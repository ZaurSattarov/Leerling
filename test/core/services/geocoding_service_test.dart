// Tests voor de geocoding-servicelaag.
//
// Twee samenhangende contracten worden hier geborgd:
// 1. "GEOCODING SECURITY CORRECTIE" (2026-08-31, ochtend): de client mag
//    GEEN eigen Google Geocoding-key/REST-aanroep bevatten.
// 2. "MAPS — SERVER-SIDE GEOCODING FASE" (2026-08-31, later die dag): de
//    actieve implementatie is nu `BackendGeocodingService`, die uitsluitend
//    de `geocode-pickup` Supabase Edge Function aanroept met een
//    `lesson_id` -- nooit een los adres, nooit rechtstreeks Google.
//
// Beide bron-guards blijven hieronder staan zodat een toekomstige wijziging
// dit niet per ongeluk terugdraait.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/services/geocoding_service.dart';

void main() {
  group('NoopGeocodingService (test-/fallback-double, niet meer de default)',
      () {
    test('geeft altijd null terug, ongeacht het lesson-id', () async {
      const service = NoopGeocodingService();

      expect(await service.geocode('les-1'), isNull);
      expect(await service.geocode(''), isNull);
      expect(await service.geocode('   '), isNull);
    });

    test('doet geen enkele netwerkaanroep (synchroon-triviaal, geen '
        'exception mogelijk)', () async {
      // Geen HTTP-mock nodig: als dit een echte netwerkaanroep zou doen,
      // zou deze test in een sandbox zonder netwerktoegang falen/hangen.
      const service = NoopGeocodingService();
      await expectLater(service.geocode('les-1'), completion(isNull));
    });
  });

  group('BackendGeocodingService (actieve implementatie)', () {
    test('leeg/whitespace-only lesson-id -> null, geen aanroep-poging',
        () async {
      const service = BackendGeocodingService();

      expect(await service.geocode(''), isNull);
      expect(await service.geocode('   '), isNull);
    });

    test(
        'fail-safe: elke fout (bv. Supabase-client niet geïnitialiseerd in '
        'een pure unit-testomgeving) resulteert in null, nooit een '
        'exception naar de aanroeper', () async {
      const service = BackendGeocodingService();

      // Geen `Supabase.initialize()` in deze pure unit-test -- dit oefent
      // dus echt het fail-safe try/catch-contract uit (een niet-
      // geïnitialiseerde client gooit intern een exception), niet een
      // gemockt "succes"-pad. Het punt van deze test is precies dat die
      // exception NOOIT onverwerkt naar de aanroeper lekt.
      await expectLater(service.geocode('les-1'), completion(isNull));
    });
  });

  group('geocodingServiceProvider (default)', () {
    test('geeft standaard de BackendGeocodingService terug (niet meer de '
        'Noop-fallback)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(geocodingServiceProvider),
          isA<BackendGeocodingService>());
    });
  });

  group('geocodedLocationProvider', () {
    test(
        'resolved naar null met de default (backend) service in een '
        'unit-testomgeving zonder Supabase-initialisatie (fail-safe, geen '
        'exception)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(geocodedLocationProvider('les-1').future);
      expect(result, isNull);
    });

    test('is overrideable met een test-double (nodig voor '
        'pickup-marker-tests elders)', () async {
      final container = ProviderContainer(overrides: [
        geocodingServiceProvider.overrideWithValue(const _FakeService()),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(geocodedLocationProvider('les-1').future);
      expect(result, const GeocodedLocation(latitude: 52.1, longitude: 5.1));
    });
  });

  group('geocoding_service.dart -- bron-guard (security-contract)', () {
    late String bron;
    setUpAll(() {
      bron =
          File('lib/core/services/geocoding_service.dart').readAsStringSync();
    });

    test('geen rechtstreekse Google Geocoding REST-aanroep meer vanuit de '
        'client', () {
      expect(bron, isNot(contains('maps.googleapis.com')));
      expect(bron, isNot(contains('package:http/http.dart')));
    });

    test('geen client-side API-key/dart-define meer voor geocoding', () {
      expect(bron, isNot(contains('String.fromEnvironment')));
      expect(bron, isNot(contains("'MAPS_API_KEY'")));
      // GOOGLE_GEOCODING_API_KEY mag als NAAM in toelichtende
      // documentatietekst voorkomen (legt uit dat de Edge Function die
      // server-side gebruikt) -- alleen de WAARDE mag nooit op de client
      // staan, en die staat hier sowieso nergens (geen enkele key-waarde in
      // deze hele klasse).
    });

    test('de GeocodingService-interface neemt een lessonId, geen los adres',
        () {
      expect(bron, contains('abstract class GeocodingService'));
      expect(
          bron, contains('Future<GeocodedLocation?> geocode(String lessonId)'));
    });

    test(
        'BackendGeocodingService roept uitsluitend de geocode-pickup Edge '
        'Function aan, met lesson_id in de body', () {
      expect(bron, contains('class BackendGeocodingService'));
      expect(bron, contains("_functionName = 'geocode-pickup'"));
      expect(bron, contains('.functions.invoke('));
      expect(bron, contains("body: {'lesson_id': id}"));
    });

    test('parsed uitsluitend latitude/longitude uit de Edge Function-'
        'response', () {
      expect(bron, contains("data['latitude']"));
      expect(bron, contains("data['longitude']"));
    });

    test('geocodingServiceProvider geeft standaard BackendGeocodingService '
        'terug', () {
      final start = bron.indexOf('final geocodingServiceProvider');
      final eind = bron.indexOf('final geocodedLocationProvider');
      expect(start, greaterThan(-1));
      expect(eind, greaterThan(start));
      expect(bron.substring(start, eind), contains('BackendGeocodingService()'));
    });
  });
}

class _FakeService implements GeocodingService {
  const _FakeService();

  @override
  Future<GeocodedLocation?> geocode(String lessonId) async =>
      const GeocodedLocation(latitude: 52.1, longitude: 5.1);
}
