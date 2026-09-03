import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/arrival_location.dart';
import '../../models/arrival_session.dart';
import '../../models/arrival_settings_info.dart';

/// Leerling-side data-toegang voor Live Aankomst (Feature 2, Fase 2C).
///
/// STRIKT READ-ONLY. De Leerling-app is uitsluitend consumer: geen
/// `insert`/`update`/`delete`/`upsert` op `arrival_sessions` of
/// `current_arrival_location`, en geen aanroepen naar `fn_arrival_start`/
/// `fn_arrival_publish_location`/`fn_arrival_stop` -- die RPC's zijn
/// uitsluitend voor de Instructeur-app. Zie
/// test/core/services/arrival_repository_no_direct_writes_test.dart voor de
/// statische guard die dit afdwingt.
///
/// RLS blijft altijd de autoriteit: elke methode hier is een gewone SELECT
/// onder de bestaande policies (zie
/// rijschool-planner-flutter/supabase/migrations/
/// 20260831094710_live_aankomst_fase1_backend.sql, "Leerling eigen actieve
/// arrival session lezen" / "Leerling eigen actieve+zichtbare arrival
/// location lezen"). Er wordt hier bewust GEEN eigen autorisatielogica
/// nagebouwd (geen client-side les_type/venster/eigenaarschap-check) --
/// alleen server/RLS bepaalt wat wordt teruggegeven.
abstract class ArrivalRepository {
  /// De actieve arrival session voor deze les, indien die bestaat EN de
  /// ingelogde leerling er via RLS toegang toe heeft. `null` bij geen
  /// sessie, een niet-actieve sessie, of RLS-blokkade -- deze drie gevallen
  /// zijn voor de UI identiek ("geen sessie te tonen").
  Future<ArrivalSession?> fetchSessionForLesson(String lessonId);

  /// De meest actuele locatie voor deze sessie, indien via RLS zichtbaar
  /// (dus `location_visibility = 'visible'` EN sessie nog actief/geldig).
  /// `null` zolang de locatie nog verborgen is -- geen fout, geen fallback.
  Future<ArrivalLocation?> fetchLocation(String sessionId);

  /// Live Aankomst-eligibility + het ingestelde venster (in minuten) voor
  /// deze les, via de smalle `fn_leerling_arrival_settings`-RPC (migratie
  /// `20260903090000_live_aankomst_leerling_settings_rpc.sql`) -- de enige
  /// legale leesweg naar `instructor_arrival_settings.visible_from_minutes`
  /// vanuit de Leerling-app (die tabel heeft uitsluitend een
  /// instructeur-eigen SELECT-policy). Gooit door bij een echte technische
  /// fout (netwerk/RPC) -- de aanroeper behandelt dat als "nog niet
  /// geladen", nooit als `eligible: false`.
  Future<ArrivalSettingsInfo> fetchArrivalSettings(String lessonId);

  /// Realtime-subscription op wijzigingen aan de sessie voor deze les.
  /// De callback triggert uitsluitend een VERSE SELECT (zie
  /// [fetchSessionForLesson]) -- de payload van het Realtime-event zelf
  /// wordt nergens als autoritatieve state gebruikt.
  RealtimeChannel subscribeSession(String lessonId, void Function() onChange);

  /// Realtime-subscription op wijzigingen aan de locatie voor deze sessie.
  /// Zelfde principe: callback triggert alleen een verse [fetchLocation].
  RealtimeChannel subscribeLocation(
      String sessionId, void Function() onChange);

  Future<void> removeChannel(RealtimeChannel channel);
}

class SupabaseArrivalRepository implements ArrivalRepository {
  const SupabaseArrivalRepository();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<ArrivalSession?> fetchSessionForLesson(String lessonId) async {
    final row = await _client
        .from('arrival_sessions')
        .select()
        .eq('lesson_id', lessonId)
        .eq('status', 'active')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return ArrivalSession.fromRow(row);
  }

  @override
  Future<ArrivalLocation?> fetchLocation(String sessionId) async {
    final row = await _client
        .from('current_arrival_location')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();
    return ArrivalLocation.fromRow(row);
  }

  @override
  Future<ArrivalSettingsInfo> fetchArrivalSettings(String lessonId) async {
    final result = await _client.rpc(
      'fn_leerling_arrival_settings',
      params: {'p_lesson_id': lessonId},
    );
    return ArrivalSettingsInfo.fromRpcResult(result);
  }

  @override
  RealtimeChannel subscribeSession(
    String lessonId,
    void Function() onChange,
  ) {
    return _client
        .channel('leerling_arrival_session_$lessonId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'arrival_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'lesson_id',
            value: lessonId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  @override
  RealtimeChannel subscribeLocation(
    String sessionId,
    void Function() onChange,
  ) {
    return _client
        .channel('leerling_arrival_location_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'current_arrival_location',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  @override
  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
