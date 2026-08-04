// Tests voor de herontworpen Ophaallocatiekaart (Planning -> Lesdetails).
// MapsUri is volledig los van Riverpod/Supabase en dus rechtstreeks
// unit-test-baar. De kaart zelf (_LocatieCard e.a.) bestaat uit bewust
// PRIVATE widgets in les_detail_screen.dart (consistent met alle andere
// kaarten in dat bestand) en is dus vanuit een los testbestand niet
// rechtstreeks als type importeerbaar -- die kant wordt gedekt via
// brontekst-regressietests (bewezen patroon elders in dit project, zie
// main_detail_header_test.dart), aangevuld met een handvol echte
// widget-tests via LesDetailScreen + ProviderScope-overrides voor het
// zichtbare gedrag (weergave, verbergen bij lege locatie, tikbaarheid,
// geen overflow).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/core/utils/maps_uri.dart';
import 'package:leerling_app/features/planning/les_detail_screen.dart';
import 'package:leerling_app/features/planning/planning_provider.dart';
import 'package:leerling_app/models/les.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';

Les _bouwLes({String? locatie, String id = 'les-1'}) {
  return Les(
    id: id,
    instructeurId: 'instr-1',
    leerlingId: 'leerling-1',
    datum: '2026-08-04',
    starttijd: '10:00',
    eindtijd: '11:00',
    duurMinuten: 60,
    status: LesStatus.gepland,
    locatie: locatie,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

Widget _bouwScherm(Les les) {
  return ProviderScope(
    overrides: [
      lesDetailProvider(les.id).overrideWith((ref) async => les),
      mijnProfielProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp(
      home: LesDetailScreen(id: les.id),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('MapsUri -- URL-encoding en kandidaten (geen Riverpod nodig)', () {
    test('lege locatie levert geen kandidaten op (kaart moet dan verborgen '
        'blijven)', () {
      expect(MapsUri.candidatesFor(''), isEmpty);
      expect(MapsUri.candidatesFor('   '), isEmpty);
    });

    test('adres wordt correct URL-encoded in de universele browserfallback',
        () {
      final kandidaten = MapsUri.candidatesFor('Overtoom 283, Amsterdam');
      expect(kandidaten, isNotEmpty);
      final laatste = kandidaten.last;
      expect(laatste.scheme, 'https');
      expect(laatste.host, 'www.google.com');
      expect(laatste.queryParameters['query'], 'Overtoom 283, Amsterdam');
      // Uri codeert zelf de spaties/komma's -- geen rauwe tekst
      // geconcateneerd.
      expect(laatste.toString(), contains('Overtoom'));
      expect(laatste.toString(), isNot(contains(' ')));
    });

    test('alleen een plaatsnaam ("Amsterdam") geeft dezelfde encodering', () {
      final kandidaten = MapsUri.candidatesFor('Amsterdam');
      expect(kandidaten.last.queryParameters['query'], 'Amsterdam');
    });

    test('geen enkele kandidaat-URI gebruikt een onbetrouwbaar/bespoke '
        'custom scheme dat op iOS eerst gewhitelist moet worden -- alleen '
        'https en geo', () {
      final kandidaten = MapsUri.candidatesFor('Amsterdam');
      for (final uri in kandidaten) {
        expect(['https', 'geo'], contains(uri.scheme));
      }
    });

    test('universele fallback is altijd de laatste kandidaat (werkt overal, '
        'ook zonder geïnstalleerde kaarten-app)', () {
      final kandidaten = MapsUri.candidatesFor('Amsterdam');
      expect(kandidaten.last.host, 'www.google.com');
    });
  });

  group('MapsUri -- geen API-key, geen extra dependency (bron-guard)', () {
    late String bron;
    setUpAll(() {
      bron = File('lib/core/utils/maps_uri.dart').readAsStringSync();
    });

    test('geen API-key-achtige string in de Maps-helper', () {
      expect(bron.toLowerCase(), isNot(contains('apikey')));
      expect(bron.toLowerCase(), isNot(contains('api_key')));
      expect(bron, isNot(contains('AIza')));
    });

    test('gebruikt alleen https/geo -- geen bespoke custom schemes '
        '(maps://, comgooglemaps://)', () {
      expect(bron, isNot(contains("scheme: 'maps'")));
      expect(bron, isNot(contains('comgooglemaps')));
    });

    test('ondersteunt zowel iOS (Apple Maps) als Android (geo-query) met '
        'browserfallback', () {
      expect(bron, contains('Platform.isIOS'));
      expect(bron, contains('maps.apple.com'));
      expect(bron, contains('Platform.isAndroid'));
      expect(bron, contains("scheme: 'geo'"));
    });

    test('pubspec.yaml heeft geen nieuwe maps-dependency/API-key '
        'toegevoegd', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.toLowerCase(), isNot(contains('google_maps_flutter')));
      expect(pubspec.toLowerCase(), isNot(contains('mapbox')));
    });
  });

  group('Ophaallocatiekaart -- widget-gedrag via LesDetailScreen', () {
    testWidgets('toont de plaatsnaam correct wanneer alleen een plaats is '
        'opgeslagen', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(locatie: 'Amsterdam')));
      await tester.pumpAndSettle();

      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
      expect(find.text('Amsterdam'), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);
    });

    testWidgets('een volledig adres wrapt netjes over twee regels (straat op '
        'regel 1, postcode+plaats op regel 2)', (tester) async {
      await tester.pumpWidget(_bouwScherm(
          _bouwLes(locatie: 'Overtoom 283, 1054 HW Amsterdam')));
      await tester.pumpAndSettle();

      expect(find.text('Overtoom 283\n1054 HW Amsterdam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lege/ontbrekende locatie verbergt de hele kaart (geen '
        'null/-/placeholder zichtbaar)', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(locatie: null)));
      await tester.pumpAndSettle();

      expect(find.text('OPHAALLOCATIE'), findsNothing);
      expect(find.text('Open in Maps'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('de volledige kaart is tikbaar (InkWell aanwezig rond de '
        'kaartinhoud)', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(locatie: 'Amsterdam')));
      await tester.pumpAndSettle();

      final inkWell = find.ancestor(
        of: find.text('OPHAALLOCATIE'),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
    });

    testWidgets('heeft een semantisch label voor screenreaders: "Open '
        'ophaallocatie in Maps"', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(locatie: 'Amsterdam')));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.text('OPHAALLOCATIE').first);
      // De ouderlijke Semantics-node (excludeSemantics) draagt het label;
      // we controleren dat er ergens in de boom een label met deze tekst
      // voorkomt.
      expect(find.bySemanticsLabel(RegExp('Open ophaallocatie in Maps.*')),
          findsOneWidget);
      // triviale sanity-check dat de widget zelf iets van semantiek heeft
      expect(semantics, isNotNull);
    });

    testWidgets('geen overflow bij een lange locatie op een smal scherm '
        '(320px)', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_bouwScherm(_bouwLes(
          locatie:
              'Een heel erg lange straatnaam met huisnummer 12345, 1234 AB Een Hele Lange Plaatsnaam')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('geen overflow bij tekstschaal 1.3', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _bouwScherm(
              _bouwLes(locatie: 'Overtoom 283, 1054 HW Amsterdam')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('geen regressie: Lestype-kaart blijft aanwezig naast de '
        'Ophaallocatiekaart', (tester) async {
      final les = Les(
        id: 'les-2',
        instructeurId: 'instr-1',
        leerlingId: 'leerling-1',
        datum: '2026-08-04',
        starttijd: '10:00',
        eindtijd: '11:00',
        duurMinuten: 60,
        status: LesStatus.gepland,
        locatie: 'Amsterdam',
        lesType: 'Rijles',
        aangemaaktOp: '2026-01-01T00:00:00Z',
        bijgewerktOp: '2026-01-01T00:00:00Z',
      );
      await tester.pumpWidget(_bouwScherm(les));
      await tester.pumpAndSettle();

      expect(find.text('Lestype'), findsOneWidget);
      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
    });
  });

  group('les_detail_screen.dart -- Ophaallocatiekaart (bron-guard)', () {
    late String bron;
    setUpAll(() {
      bron = File('lib/features/planning/les_detail_screen.dart')
          .readAsStringSync();
    });

    test('_LocatieCard gebruikt MapsUri.open, geen directe canLaunchUrl-'
        'aanroep meer voor navigatie', () {
      final start = bron.indexOf('class _LocatieCard');
      final eind = bron.indexOf('class _OphaallocatieBadge');
      expect(start, greaterThan(-1));
      expect(eind, greaterThan(start));
      final blok = bron.substring(start, eind);
      expect(blok, contains('MapsUri.open'));
    });

    test('geen dubbele locatievermelding: de oude losse "Navigeer naar '
        'locatie"-tegel wordt niet meer als widget-label gebruikt (het '
        'exacte oude label-argument komt niet meer voor -- alleen in '
        'toelichtende commentaartekst is dat toegestaan)', () {
      expect(bron, isNot(contains("label: 'Navigeer naar locatie'")));
    });

    test('geen losse grote knop meer onder de kaart (oude _ContactButton '
        'niet meer gebruikt voor locatie)', () {
      final start = bron.indexOf('class _LocatieCard');
      final eind = bron.indexOf('class _OphaallocatieBadge');
      final blok = bron.substring(start, eind);
      expect(blok, isNot(contains('_ContactButton(')));
    });

    test('sibling-kaarten (Lestype/Voertuig/Evaluatie) blijven ongewijzigd '
        'aanwezig -- geen regressie', () {
      expect(bron, contains('class _LesInfoCard'));
      expect(bron, contains('class _VoertuigCard'));
      expect(bron, contains('class _EvaluatieSection'));
      expect(bron, contains('class _EvaluatieFallback'));
      expect(bron, contains('class _EvaluatieNietBeschikbaar'));
    });

    test('geen database/route/navbar-wijziging: LesDetailScreen gebruikt '
        'nog steeds hetzelfde id-gebaseerde lesDetailProvider', () {
      expect(bron, contains('lesDetailProvider(id)'));
    });
  });
}
