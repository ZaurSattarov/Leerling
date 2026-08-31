import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Eén geocode-resultaat (adres -> coördinaten). Bewust géén afhankelijkheid
/// van `google_maps_flutter`/`LatLng` in deze servicelaag -- de UI-laag
/// (bv. `ArrivalLiveMap`) doet zelf de omzetting naar een `LatLng`.
class GeocodedLocation {
  final double latitude;
  final double longitude;
  const GeocodedLocation({required this.latitude, required this.longitude});
}

/// Bepaalt de coördinaten van de ophaallocatie van een les. Uitsluitend voor
/// het tonen van een ophaallocatie-marker op de interne kaart -- nooit voor
/// routering/navigatie (dat blijft `MapsUri`, extern, een expliciete
/// secundaire actie).
///
/// [geocode] neemt een `lessonId`, GEEN los adres. Dat is een bewuste
/// architectuurkeuze (server-side geocoding-fase, 2026-08-31): het adres
/// (`lessen.locatie`) wordt server-side opgehaald door de `geocode-pickup`
/// Edge Function, RLS-scoped op basis van dat lesson-id -- dezelfde
/// bestaande `lessen`-RLS-policies als overal elders (instructeur-eigen /
/// leerling-eigen / school-breed), geen aparte autorisatielaag. Zou deze
/// laag in plaats daarvan een los adres-string accepteren, dan zou elke
/// ingelogde gebruiker elk willekeurig adres kunnen laten geocoden (een open
/// geocoding-proxy) -- dat risico is hiermee uitgesloten.
///
/// BEWUST fail-safe als contract: elke implementatie geeft `null` terug op
/// om het even welke fout/afwezigheid van data -- nooit een exception, nooit
/// een technische foutmelding aan de gebruiker. De aanroeper (bv.
/// `LiveAankomstFullscreenScreen`) toont dan gewoon geen pickup-marker, de
/// rest van de kaart blijft normaal werken.
abstract class GeocodingService {
  Future<GeocodedLocation?> geocode(String lessonId);
}

/// Server-side implementatie (actief sinds 2026-08-31, "MAPS — SERVER-SIDE
/// GEOCODING FASE"). Roept de `geocode-pickup` Supabase Edge Function aan
/// (`supabase/functions/geocode-pickup/` in de Instructeur-repo, canonical
/// migration/functions-root) -- die Edge Function, niet deze app, roept de
/// Google Geocoding API aan, met een uitsluitend server-side secret
/// (`GOOGLE_GEOCODING_API_KEY`, via `supabase secrets set`). Deze klasse
/// bevat zelf GEEN Google-key, GEEN directe Google-REST-aanroep, en GEEN
/// `--dart-define`-afhankelijkheid.
///
/// `Supabase.instance.client.functions.invoke(...)` hangt de JWT van de
/// huidige sessie automatisch mee als Authorization-header (zelfde patroon
/// als elke andere Supabase-aanroep in deze app, bv.
/// `arrival_repository.dart`) -- de Edge Function gebruikt die JWT om
/// `lessen.locatie` RLS-scoped op te halen.
class BackendGeocodingService implements GeocodingService {
  const BackendGeocodingService();

  static const String _functionName = 'geocode-pickup';

  @override
  Future<GeocodedLocation?> geocode(String lessonId) async {
    final id = lessonId.trim();
    if (id.isEmpty) return null;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {'lesson_id': id},
      );

      final data = response.data;
      if (data is! Map) return null;

      // Uitsluitend latitude/longitude parsen -- wat de Edge Function ook
      // nog meer teruggeeft (zou niet moeten, zie server-side contract)
      // wordt hier genegeerd, nooit doorgegeven aan de UI.
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat is! num || lng is! num) return null;

      return GeocodedLocation(latitude: lat.toDouble(), longitude: lng.toDouble());
    } catch (_) {
      // Netwerkfout, FunctionException (4xx/5xx), timeout, onverwachte
      // payload, ... -- nooit een crash, nooit een technische foutmelding:
      // gewoon geen coördinaten. Zelfde fail-safe-contract als elke andere
      // GeocodingService-implementatie.
      return null;
    }
  }
}

/// Test-/fallback-implementatie: géén netwerkaanroep, géén key, altijd
/// `null`. Blijft bestaan als expliciete "geocoding uit"-test-double (zie
/// `geocoding_service_test.dart`) en als veilige placeholder mocht de
/// Edge Function ooit (tijdelijk) uitgeschakeld moeten worden zonder de
/// provider-graph te wijzigen.
class NoopGeocodingService implements GeocodingService {
  const NoopGeocodingService();

  @override
  Future<GeocodedLocation?> geocode(String lessonId) async => null;
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return const BackendGeocodingService();
});

/// `FutureProvider.family`, bewust NIET `.autoDispose`: éénmaal opgehaalde
/// coördinaten voor een lesson-id blijven voor de rest van de app-sessie in
/// het geheugen -- geocoding is een betaalde dienst (via de server-side
/// cache verder al bijna gratis na de eerste keer per uniek adres, maar
/// binnen één app-sessie hoeft zelfs die ene Edge Function-aanroep niet
/// herhaald te worden). Sleutel is de `lessonId`, NIET het adres zelf --
/// zie de doc-comment bij [GeocodingService.geocode].
final geocodedLocationProvider =
    FutureProvider.family<GeocodedLocation?, String>((ref, lessonId) {
  final service = ref.watch(geocodingServiceProvider);
  return service.geocode(lessonId);
});
