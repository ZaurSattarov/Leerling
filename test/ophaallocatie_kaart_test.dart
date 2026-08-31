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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:leerling_app/core/services/geocoding_service.dart';
import 'package:leerling_app/core/utils/maps_uri.dart';
import 'package:leerling_app/features/arrival/arrival_provider.dart';
import 'package:leerling_app/features/arrival/live_aankomst_fullscreen_screen.dart';
import 'package:leerling_app/features/planning/les_detail_screen.dart';
import 'package:leerling_app/features/planning/planning_provider.dart';
import 'package:leerling_app/models/arrival_location.dart';
import 'package:leerling_app/models/arrival_session.dart';
import 'package:leerling_app/models/les.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';

import 'features/arrival/fakes.dart';

/// Test-double die altijd een vast, bekend coördinatenpaar teruggeeft --
/// zodat de "pickup-marker in de fullscreen-kaart"-tests niet afhankelijk
/// zijn van een echte (betaalde) Google Geocoding-aanroep.
class _FakeGeocodingService implements GeocodingService {
  final GeocodedLocation? resultaat;
  const _FakeGeocodingService(this.resultaat);

  @override
  Future<GeocodedLocation?> geocode(String address) async => resultaat;
}

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

Widget _bouwScherm(
  Les les, {
  ArrivalController? arrivalController,
  GeocodingService? geocodingService,
}) {
  return ProviderScope(
    overrides: [
      lesDetailProvider(les.id).overrideWith((ref) async => les),
      mijnProfielProvider.overrideWith((ref) async => null),
      if (arrivalController != null)
        arrivalControllerProvider.overrideWith((ref) => arrivalController),
      if (geocodingService != null)
        geocodingServiceProvider.overrideWithValue(geocodingService),
    ],
    child: MaterialApp(
      home: LesDetailScreen(id: les.id),
    ),
  );
}

/// Bouwt een [ArrivalController] met gescripte servertoestand voor les
/// [les], al vooraf op die les gericht (zoals `_OphaallocatieSectie` na
/// mount ook zou doen) -- zodat de eerste `pumpAndSettle()` direct de
/// juiste state laat zien zonder een race met de widget's eigen
/// postFrameCallback.
Future<ArrivalController> _bouwArrivalController(
  FakeArrivalRepository repo,
  Les les,
) async {
  final controller = ArrivalController(repository: repo);
  await controller.onLessonChanged(les.id);
  return controller;
}

ArrivalSession _sessie({
  required String lessonId,
  String id = 'sess-1',
  String status = 'active',
  String visibility = 'visible',
  Duration eindigtOver = const Duration(minutes: 5),
}) {
  return ArrivalSession(
    id: id,
    lessonId: lessonId,
    status: status,
    endsAt: DateTime.now().add(eindigtOver),
    locationVisibility: visibility,
  );
}

ArrivalLocation _locatie({
  double lat = 52.1,
  double lon = 5.1,
  DateTime? recordedAt,
}) {
  return ArrivalLocation(
    latitude: lat,
    longitude: lon,
    recordedAt: recordedAt ?? DateTime.now(),
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

    test(
        'MapsUri zelf blijft dependency-vrij (geen mapbox); '
        'google_maps_flutter is sinds Feature 2/Fase 3-4 (Live Aankomst) '
        'bewust wél aanwezig in pubspec.yaml, maar uitsluitend voor de Live '
        'Aankomst-integratie in de ophaallocatiekaart (arrival_live_map.dart) '
        '-- MapsUri zelf gebruikt en importeert dat package nergens (zie de '
        'externe-link-schemes hierboven, ongewijzigd)', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.toLowerCase(), isNot(contains('mapbox')));
      expect(bron, isNot(contains('google_maps_flutter')));
    });
  });

  group('Ophaallocatiekaart -- widget-gedrag via LesDetailScreen', () {
    testWidgets('toont de plaatsnaam correct wanneer alleen een plaats is '
        'opgeslagen', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(locatie: 'Amsterdam')));
      await tester.pumpAndSettle();

      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
      expect(find.text('Amsterdam'), findsOneWidget);
      expect(find.text('Bekijk locatie'), findsOneWidget);
      // De oude tekst mag nergens meer voorkomen -- tikken op de hoofdkaart
      // mag nooit meer als "ga direct naar externe Maps" ogen.
      expect(find.text('Open in Maps'), findsNothing);
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
      expect(find.text('Bekijk locatie'), findsNothing);
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

    testWidgets('heeft een semantisch label voor screenreaders: "Bekijk '
        'ophaallocatie"', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(locatie: 'Amsterdam')));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.text('OPHAALLOCATIE').first);
      // De ouderlijke Semantics-node (excludeSemantics) draagt het label;
      // we controleren dat er ergens in de boom een label met deze tekst
      // voorkomt. Bewust GEEN "in Maps" meer -- de kaart opent intern, niet
      // extern.
      expect(find.bySemanticsLabel(RegExp('Bekijk ophaallocatie.*')),
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

  group('Ophaallocatiekaart -- interne kaart i.p.v. externe navigatie '
      '(Fix Ophaallocatie Navigatie)', () {
    testWidgets(
        'geen live sessie -> tikken op de kaart opent de interne fullscreen-'
        'kaart (LiveAankomstFullscreenScreen), GEEN externe Maps-app',
        (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwScherm(
        les,
        arrivalController: controller,
        geocodingService: const _FakeGeocodingService(null),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LiveAankomstFullscreenScreen), findsNothing);

      await tester.tap(find.text('OPHAALLOCATIE'));
      await tester.pumpAndSettle();

      // Statische modus: geen live sessie, dus het scherm blijft open (geen
      // auto-pop) en toont de interne kaart -- geen enkele externe
      // Maps-aanroep is hiervoor nodig geweest (MapsUri wordt alleen nog
      // aangeroepen vanuit de secundaire "Route"-knop binnen dit scherm,
      // zie de bron-guard-tests hieronder).
      expect(find.byType(LiveAankomstFullscreenScreen), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Ophaallocatie'), findsOneWidget);
      expect(find.text('Amsterdam'), findsWidgets);
    });

    testWidgets(
        'de interne fullscreen-kaart toont de ophaallocatie-marker zodra '
        'geocoding een resultaat oplevert', (tester) async {
      final les = _bouwLes(locatie: 'Overtoom 283, Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwScherm(
        les,
        arrivalController: controller,
        geocodingService: const _FakeGeocodingService(
          GeocodedLocation(latitude: 52.3626, longitude: 4.8652),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPHAALLOCATIE'));
      await tester.pumpAndSettle();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers, hasLength(1));
      expect(map.markers.single.markerId, const MarkerId('ophaallocatie'));
      expect(map.markers.single.position,
          const LatLng(52.3626, 4.8652));
    });

    testWidgets(
        'de secundaire "Route"-knop in de fullscreen-kaart blijft apart '
        'werken (externe navigatie is optioneel, nooit de hoofdactie)',
        (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwScherm(
        les,
        arrivalController: controller,
        geocodingService: const _FakeGeocodingService(null),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPHAALLOCATIE'));
      await tester.pumpAndSettle();

      final routeKnop = find.bySemanticsLabel('Route openen in Maps');
      expect(routeKnop, findsOneWidget);

      // MapsUri.open zelf vangt elke platform-channel-fout af (geen
      // canLaunchUrl-mock nodig in widget-tests, bewust patroon elders in
      // dit bestand) -- tikken mag dus nooit crashen, ook niet zonder
      // gemockte url_launcher-plugin.
      await tester.tap(routeKnop);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Ophaallocatiekaart -- Live Aankomst-integratie (Feature 2, Fase 4)',
      () {
    testWidgets('geen live sessie -> normale ophaallocatiekaart', (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester
          .pumpWidget(_bouwScherm(les, arrivalController: controller));
      await tester.pumpAndSettle();

      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
      expect(find.text('Bekijk locatie'), findsOneWidget);
      expect(find.byType(GoogleMap), findsNothing);
      expect(find.textContaining('Live'), findsNothing);
    });

    testWidgets(
        'actieve, zichtbare sessie -> live kaart met badge in plaats van de '
        'normale kaart', (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = _sessie(lessonId: les.id);
      repo.locationsBySession['sess-1'] = _locatie();
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester
          .pumpWidget(_bouwScherm(les, arrivalController: controller));
      await tester.pumpAndSettle();

      expect(find.text('OPHAALLOCATIE'), findsNothing,
          reason: 'de normale kaart is vervangen, niet ernaast getoond');
      expect(find.text('Open in Maps'), findsNothing);
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Instructeur onderweg · Live'), findsOneWidget);
      expect(find.text('Bekijk live kaart'), findsOneWidget);
      // Adres blijft zichtbaar, ook in de live-variant.
      expect(find.text('Amsterdam'), findsOneWidget);

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers.single.position, const LatLng(52.1, 5.1));
      expect(map.myLocationEnabled, false);
    });

    testWidgets('locatie nog verborgen (hidden) -> normale kaart, geen live '
        'marker', (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] =
          _sessie(lessonId: les.id, visibility: 'hidden');
      repo.locationsBySession['sess-1'] = null;
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester
          .pumpWidget(_bouwScherm(les, arrivalController: controller));
      await tester.pumpAndSettle();

      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
      expect(find.byType(GoogleMap), findsNothing);
    });

    testWidgets(
        'stale locatie -> geen live marker, valt terug op normale kaart '
        '(geen stale-location-leakage)', (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = _sessie(lessonId: les.id);
      repo.locationsBySession['sess-1'] = _locatie(
        recordedAt: DateTime.now().subtract(const Duration(seconds: 200)),
      );
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester
          .pumpWidget(_bouwScherm(les, arrivalController: controller));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleMap), findsNothing,
          reason: 'stale locatie mag nooit als actuele live kaart getoond');
      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
    });

    testWidgets(
        'sessie stopt terwijl live kaart getoond werd -> valt direct terug '
        'op de normale kaart, geen oude marker blijft staan', (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = _sessie(lessonId: les.id);
      repo.locationsBySession['sess-1'] = _locatie();
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester
          .pumpWidget(_bouwScherm(les, arrivalController: controller));
      await tester.pumpAndSettle();
      expect(find.byType(GoogleMap), findsOneWidget);

      repo.sessionsByLesson[les.id] = null; // instructeur heeft gestopt
      repo.stuurSessionEvent(les.id);
      await tester.pumpAndSettle();

      expect(find.byType(GoogleMap), findsNothing);
      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
      expect(find.text('Bekijk locatie'), findsOneWidget);
    });

    testWidgets('tik op de live kaart opent de fullscreen-weergave',
        (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = _sessie(lessonId: les.id);
      repo.locationsBySession['sess-1'] = _locatie();
      final controller = await _bouwArrivalController(repo, les);
      addTearDown(controller.dispose);

      await tester
          .pumpWidget(_bouwScherm(les, arrivalController: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bekijk live kaart'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveAankomstFullscreenScreen), findsOneWidget);
      // Fullscreen toont zelf ook een echte kaart + het adres + een
      // terugknop -- geen losse ETA/route-elementen.
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Instructeur onderweg'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // De compacte kaart onder de fullscreen-route blijft gemount (gewone
      // push, geen pop) en heeft dus ook nog haar eigen 6s-fallbacktimer.
      // Laat die hier expliciet aflopen zodat er geen pending timer
      // overblijft aan het einde van de test.
      await tester.pump(const Duration(seconds: 7));
    });
  });

  group('les_detail_screen.dart -- Ophaallocatiekaart (bron-guard)', () {
    late String bron;
    setUpAll(() {
      bron = File('lib/features/planning/les_detail_screen.dart')
          .readAsStringSync();
    });

    test(
        '_LocatieCard opent de interne LiveAankomstFullscreenScreen bij een '
        'tik, GEEN directe MapsUri.open/canLaunchUrl-aanroep meer als '
        'hoofdactie (Fix Ophaallocatie Navigatie: externe Maps mag nooit meer '
        'de primaire tap-actie zijn)', () {
      final start = bron.indexOf('class _LocatieCard');
      final eind = bron.indexOf('class _OphaallocatieBadge');
      expect(start, greaterThan(-1));
      expect(eind, greaterThan(start));
      final blok = bron.substring(start, eind);
      expect(blok, contains('LiveAankomstFullscreenScreen'));
      expect(blok, isNot(contains('MapsUri.open')));
    });

    test(
        'MapsUri.open bestaat nog wél, maar uitsluitend als secundaire actie '
        'binnen de fullscreen-kaart (live_aankomst_fullscreen_screen.dart) -- '
        '_LocatieCard zelf roept het niet meer aan (alleen toelichtende '
        'commentaartekst mag de naam nog noemen)', () {
      final fullscreenBron =
          File('lib/features/arrival/live_aankomst_fullscreen_screen.dart')
              .readAsStringSync();
      expect(fullscreenBron, contains('MapsUri.open'));

      final start = bron.indexOf('class _LocatieCard');
      final eind = bron.indexOf('class _OphaallocatieBadge');
      final blok = bron.substring(start, eind);
      expect(blok, isNot(contains('MapsUri.open')));
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

    test(
        'sibling-kaarten (Voertuig/Evaluatie) blijven aanwezig; Lestype is '
        'sinds de Impeccable-redesign geïntegreerd in _LesInformatieCard '
        'i.p.v. een eigen losse _LesInfoCard (bewuste verwijdering, geen '
        'regressie)', () {
      expect(bron, contains('class _VoertuigCard'));
      expect(bron, contains('class _EvaluatieSection'));
      expect(bron, contains('class _EvaluatieFallback'));
      expect(bron, contains('class _EvaluatieNietBeschikbaar'));
      expect(bron, isNot(contains('class _LesInfoCard')));
      expect(bron, contains('class _LesInformatieCard'));
    });

    test('geen database/route/navbar-wijziging: LesDetailScreen gebruikt '
        'nog steeds hetzelfde id-gebaseerde lesDetailProvider', () {
      expect(bron, contains('lesDetailProvider(id)'));
    });
  });
}
