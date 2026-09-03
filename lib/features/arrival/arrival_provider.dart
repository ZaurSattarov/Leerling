import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/arrival_repository.dart';
import '../../models/arrival_location.dart';
import '../../models/arrival_session.dart';
import '../../models/arrival_settings_info.dart';

/// Leerling-side state voor Live Aankomst (Feature 2, Fase 2C).
///
/// [session]/[location] zijn ALTIJD wat de laatste verse SELECT teruggaf --
/// nooit een lokaal gecachete/onthouden waarde die verder leeft dan de
/// server het toestaat. `null` betekent hier consequent "niets te tonen",
/// niet "nog niet geladen" (zie [loading] daarvoor).
class ArrivalState {
  final ArrivalSession? session;
  final ArrivalLocation? location;
  final bool loading;
  final bool polling;

  const ArrivalState({
    this.session,
    this.location,
    this.loading = false,
    this.polling = false,
  });

  bool get heeftZichtbareSessie => session?.isActive() ?? false;

  ArrivalState copyWith({
    ArrivalSession? session,
    bool clearSession = false,
    ArrivalLocation? location,
    bool clearLocation = false,
    bool? loading,
    bool? polling,
  }) {
    return ArrivalState(
      session: clearSession ? null : (session ?? this.session),
      location: clearLocation ? null : (location ?? this.location),
      loading: loading ?? this.loading,
      polling: polling ?? this.polling,
    );
  }
}

/// Orkestreert de leesstroom rond één les tegelijk: sessie ophalen/volgen,
/// zodra actief de locatie ophalen/volgen, en -- alleen zolang de locatie
/// nog verborgen is -- een lichte pollingfallback (zie klasse-commentaar
/// onderaan dit bestand voor de motivatie).
///
/// Puur consumer: roept nooit een arrival-RPC aan en schrijft nooit naar
/// arrival_sessions/current_arrival_location (zie [ArrivalRepository]).
class ArrivalController extends StateNotifier<ArrivalState> {
  ArrivalController({required ArrivalRepository repository})
      : _repo = repository,
        super(const ArrivalState());

  final ArrivalRepository _repo;

  String? _lessonId;
  RealtimeChannel? _sessionChannel;
  RealtimeChannel? _locationChannel;
  Timer? _pollTimer;
  bool _disposed = false;

  /// Zolang de sessie actief is maar de locatie nog niet zichtbaar/leesbaar
  /// is, wordt elke [pollInterval] een verse SELECT gedaan (sessie +
  /// locatie) als vangnet naast Realtime -- zie motivatie onderaan.
  static const Duration pollInterval = Duration(seconds: 7);

  /// Aanroepen wanneer `HomeData.volgendeLes` verandert (nieuwe les, of geen
  /// les meer). Ruimt de vorige les-scope volledig op en start schoon op
  /// voor de nieuwe -- nooit state van de vorige les laten "doorlekken".
  Future<void> onLessonChanged(String? lessonId) async {
    // Kan binnenkomen ná dispose() (bv. een uitgestelde microtask vanuit een
    // widget-dispose die net gemist heeft dat de controller zelf ondertussen
    // ook al is opgeruimd) -- nooit crashen, gewoon een no-op.
    if (_disposed) return;
    if (_lessonId == lessonId) return;
    _lessonId = lessonId;
    await _teardownSubscriptions();

    if (lessonId == null) {
      _setState(const ArrivalState());
      return;
    }

    _setState(const ArrivalState(loading: true));
    try {
      _sessionChannel = _repo.subscribeSession(
        lessonId,
        () => _refreshSession(lessonId),
      );
    } catch (_) {
      // Realtime-verbinding niet beschikbaar: nooit crashen (§21). De
      // eerste fetch hieronder gebeurt hoe dan ook; zonder kanaal werkt
      // alleen de live-update-laag niet, geen fout-state voor de gebruiker.
      _sessionChannel = null;
    }
    await _refreshSession(lessonId, isEersteLaad: true);
  }

  Future<void> _refreshSession(String lessonId, {bool isEersteLaad = false}) async {
    if (_disposed || _lessonId != lessonId) return;
    ArrivalSession? session;
    try {
      session = await _repo.fetchSessionForLesson(lessonId);
    } catch (_) {
      // Netwerk/backendfout: nooit een crash, nooit oude data als "actueel"
      // laten staan -- gewoon niets te tonen tot de volgende poging.
      session = null;
    }
    if (_disposed || _lessonId != lessonId) return;

    _setState(state.copyWith(
      session: session,
      clearSession: session == null,
      loading: false,
    ));

    if (session != null && session.isActive()) {
      await _ensureLocationTracking(session);
    } else {
      await _teardownLocationTracking();
      _setState(state.copyWith(clearLocation: true));
    }
  }

  Future<void> _ensureLocationTracking(ArrivalSession session) async {
    if (_locationChannel == null) {
      try {
        _locationChannel = _repo.subscribeLocation(
          session.id,
          () => _refreshLocation(session.id),
        );
      } catch (_) {
        // Zelfde redenering als bij de sessie-subscription hierboven: geen
        // crash, de fetch hieronder gebeurt sowieso.
        _locationChannel = null;
      }
    }
    await _refreshLocation(session.id);
  }

  Future<void> _refreshLocation(String sessionId) async {
    if (_disposed || state.session?.id != sessionId) return;
    ArrivalLocation? location;
    try {
      location = await _repo.fetchLocation(sessionId);
    } catch (_) {
      location = null;
    }
    if (_disposed || state.session?.id != sessionId) return;

    _setState(state.copyWith(location: location, clearLocation: location == null));

    if (location == null) {
      _startPollingIfNeeded(sessionId);
    } else {
      _stopPolling();
    }
  }

  void _startPollingIfNeeded(String sessionId) {
    if (_pollTimer != null || _disposed) return;
    _setState(state.copyWith(polling: true));
    _pollTimer = Timer.periodic(pollInterval, (_) async {
      final lessonId = _lessonId;
      if (lessonId == null) return;
      await _refreshSession(lessonId);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    // Na dispose() mag `state` niet meer gelezen worden (StateNotifier
    // gooit dan zelf een StateError) -- de timer is hierboven al
    // gecanceld, verder is er niets meer te doen.
    if (_disposed) return;
    if (state.polling) {
      _setState(state.copyWith(polling: false));
    }
  }

  Future<void> _teardownLocationTracking() async {
    _stopPolling();
    final channel = _locationChannel;
    _locationChannel = null;
    if (channel != null) {
      await _repo.removeChannel(channel);
    }
  }

  Future<void> _teardownSubscriptions() async {
    _stopPolling();
    final sessionChannel = _sessionChannel;
    _sessionChannel = null;
    if (sessionChannel != null) {
      await _repo.removeChannel(sessionChannel);
    }
    final locationChannel = _locationChannel;
    _locationChannel = null;
    if (locationChannel != null) {
      await _repo.removeChannel(locationChannel);
    }
  }

  /// App gaat naar achtergrond: stop uitsluitend de pollingfallback (nieuw,
  /// feature-eigen gedrag). Realtime-subscriptions worden -- bewust,
  /// consistent met de rest van deze app (zie StudentService.subscribeLessen
  /// e.a., die ook niet op app-pauze worden opgeruimd) -- niet losgekoppeld.
  void onAppPaused() => _stopPolling();

  /// App weer actief: NOOIT oude lokale state vertrouwen. Altijd een verse
  /// SELECT voor sessie (en, indien actief, locatie), ongeacht wat er in
  /// [state] al stond.
  Future<void> onAppResumed() async {
    if (_disposed) return;
    final lessonId = _lessonId;
    if (lessonId == null) return;
    await _refreshSession(lessonId);
  }

  /// Logout/auth-verlies: alle arrival-state direct wissen, geen sessie- of
  /// locatiedata van de vorige gebruiker laten staan voor een eventuele
  /// volgende gebruiker op hetzelfde toestel.
  Future<void> onAuthLost() async {
    if (_disposed) return;
    _lessonId = null;
    await _teardownSubscriptions();
    _setState(const ArrivalState());
  }

  void _setState(ArrivalState next) {
    if (_disposed) return;
    state = next;
  }

  @override
  void dispose() {
    // Idempotent: kan zowel via Riverpod's eigen provider-teardown als via
    // een expliciete/test-teardown-aanroep binnenkomen (bv. wanneer een
    // widget-test de controller zowel zelf opruimt als via een
    // ProviderScope-override laat beheren) -- een dubbele aanroep mag nooit
    // crashen.
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    // Kanalen best-effort opruimen; niet awaiten in dispose().
    final sessionChannel = _sessionChannel;
    if (sessionChannel != null) {
      _repo.removeChannel(sessionChannel);
    }
    final locationChannel = _locationChannel;
    if (locationChannel != null) {
      _repo.removeChannel(locationChannel);
    }
    super.dispose();
  }
}

/// Aparte provider voor de repository (i.p.v. rechtstreeks inline
/// geconstrueerd in [arrivalControllerProvider]) zodat [arrivalSettingsProvider]
/// hieronder dezelfde instantie hergebruikt -- geen tweede losstaande
/// `SupabaseArrivalRepository()` ergens anders in de app.
final arrivalRepositoryProvider = Provider<ArrivalRepository>((ref) {
  return const SupabaseArrivalRepository();
});

final arrivalControllerProvider =
    StateNotifierProvider<ArrivalController, ArrivalState>((ref) {
  final controller =
      ArrivalController(repository: ref.watch(arrivalRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

/// Live Aankomst-eligibility + venster (in minuten) voor één les, voor de
/// altijd-zichtbare banner op Lesdetails (2026-09-03, zie
/// live_aankomst_banner_logic.dart). Eén fetch per les-id, zelfde
/// fail-safe-filosofie als de rest van deze feature: een fout hier
/// propageert als `AsyncError` -- de UI behandelt dat als "nog niet
/// geladen" (geen banner die verschijnt/verdwijnt), nooit als een
/// foutmelding of als `eligible: false`.
final arrivalSettingsProvider =
    FutureProvider.autoDispose.family<ArrivalSettingsInfo, String>(
  (ref, lessonId) {
    final repo = ref.watch(arrivalRepositoryProvider);
    return repo.fetchArrivalSettings(lessonId);
  },
);

// ============================================================================
// Fase 2C, §8 -- gekozen aanpak voor de hidden->visible Realtime/RLS-edge case
// ============================================================================
// current_arrival_location's RLS-zichtbaarheid hangt af van een subquery
// naar arrival_sessions.location_visibility (geen kolom op de rij zelf).
// Onderzoek (Supabase-documentatie + community-bronnen, 2026-08-31):
// Realtime herevalueert de RLS-policy per event tegen de NIEUWE rij-state op
// het moment van broadcast ("Realtime authorizes every event against each
// subscriber" -- https://supabase.com/docs/guides/realtime/postgres-changes),
// dus een rij die van onzichtbaar naar zichtbaar overgaat, hoort in principe
// alsnog een event te leveren zodra er een volgende wijziging aan die rij
// plaatsvindt. Twee redenen om daar NIET blind op te vertrouwen:
// 1. Dit exacte scenario (rij die überhaupt nog nooit zichtbaar was, wordt
//    dat via een JOIN-gebaseerde policy) staat nergens expliciet
//    gegarandeerd in de officiële documentatie.
// 2. Diezelfde documentatie bevestigt een aanverwant hard limiet: RLS wordt
//    NIET toegepast op DELETE-events ("RLS policies are not applied to
//    DELETE statements") -- dus voor het WEG laten gaan van een marker
//    (fn_arrival_stop verwijdert de current_arrival_location-rij) kan sowieso
//    niet op een Realtime-DELETE-event vertrouwd worden. Om die reden drijft
//    deze controller het tonen/verbergen van de kaart primair op
//    arrival_sessions-state (isActive/isVisible), nooit op het al-dan-niet
//    ontvangen van een location-DELETE-event.
// Gekozen fallback: zolang de sessie actief is maar de locatie nog niet
// zichtbaar/leesbaar is, wordt elke 7s (binnen de gevraagde 5-10s-marge)
// een verse SELECT gedaan naast de Realtime-subscription. Zodra de locatie
// zichtbaar wordt, sessie stopt, of de app naar de achtergrond gaat, stopt
// de polling direct (zie _refreshLocation/onAppPaused hierboven). Geen
// aparte polling voor het WEG laten gaan van een sessie/locatie -- dat loopt
// al via de sessie-Realtime-subscription + de client-side isActive()-check.
