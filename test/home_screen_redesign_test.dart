// Tests voor de herziene Home/Dashboard-hiërarchie (Impeccable-redesign,
// zie CLAUDE.md-opdracht "Home-pagina rustiger en actiegerichter"):
// kerncijfers -> volgende les -> voorbereiding -> voortgang -> examenadvies
// -> (optioneel) urgente factuuractie. Geen volledige factuurlijst meer op
// Home.
//
// HomeScreen heeft Supabase/Riverpod-afhankelijkheden (StudentService).
// Net als in main_detail_header_test.dart en ophaallocatie_kaart_test.dart
// worden de structurele volgorde-/verwijderingsgaranties gedekt via
// brontekst-regressietests, aangevuld met echte widget-tests via
// ProviderScope-overrides voor het zichtbare gedrag.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/features/home/home_coach_provider.dart';
import 'package:leerling_app/features/home/home_provider.dart';
import 'package:leerling_app/features/home/home_screen.dart';
import 'package:leerling_app/features/lesvoorbereiding/lesvoorbereiding_provider.dart';
import 'package:leerling_app/models/factuur.dart';
import 'package:leerling_app/models/leerling_profiel.dart';
import 'package:leerling_app/models/les.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';

LeerlingProfiel _bouwProfiel({int lessenGevolgd = 13, int lessenTotaal = 20}) {
  return LeerlingProfiel(
    id: 'leerling-1',
    instructeurId: 'instr-1',
    voornaam: 'Lisa',
    achternaam: 'Jansen',
    pakket: PakketType.standaard,
    status: LeerlingStatus.actief,
    lessenTotaal: lessenTotaal,
    lessenGevolgd: lessenGevolgd,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

Les _bouwLes({String? locatie = 'Overtoom 283, Amsterdam'}) {
  return Les(
    id: 'les-1',
    instructeurId: 'instr-1',
    leerlingId: 'leerling-1',
    datum: '2026-08-07',
    starttijd: '20:00',
    eindtijd: '21:00',
    duurMinuten: 60,
    status: LesStatus.gepland,
    instructeurNaam: 'Zaur',
    locatie: locatie,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

Factuur _bouwFactuur({
  String id = 'factuur-1',
  FactuurStatus status = FactuurStatus.open,
  String? vervaldatum,
}) {
  return Factuur(
    id: id,
    instructeurId: 'instr-1',
    leerlingId: 'leerling-1',
    factuurnummer: 'F-2026-001',
    beschrijving: 'Lespakket standaard',
    bedragCents: 4500,
    status: status,
    vervaldatum: vervaldatum,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

const _leegVoorbereiding = PreparationViewModel(
  emptyState: PreparationEmptyState.geenVolgendeLes,
);

const _leegCoach = HomeCoachData(
  readinessScore: 0,
  status: 'Nog onvoldoende data',
  advies: 'Volg meer lessen voor gepersonaliseerd advies.',
  feedback: '',
  laatstGeoefend: [],
  heeftData: false,
);

Widget _bouwHomeScherm({
  required HomeData home,
  LeerlingProfiel? profiel,
  HomeCoachData coach = _leegCoach,
  PreparationViewModel voorbereiding = _leegVoorbereiding,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/planning',
        builder: (_, __) => const Scaffold(body: Text('Planning-scherm')),
      ),
      GoRoute(
        path: '/voortgang',
        builder: (_, __) => const Scaffold(body: Text('Voortgang-scherm')),
      ),
      GoRoute(
        path: '/examenadvies',
        builder: (_, __) => const Scaffold(body: Text('Examenadvies-scherm')),
      ),
      GoRoute(
        path: '/lesvoorbereiding',
        builder: (_, __) =>
            const Scaffold(body: Text('Lesvoorbereiding-scherm')),
      ),
      GoRoute(
        path: '/facturen',
        builder: (_, __) => const Scaffold(body: Text('Facturen-scherm')),
      ),
      GoRoute(
        path: '/facturen/:id',
        builder: (context, state) => Scaffold(
          body: Text('Factuurdetail-${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/notificaties',
        builder: (_, __) => const Scaffold(body: Text('Notificaties-scherm')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      mijnProfielProvider.overrideWith((ref) async => profiel),
      homeProvider.overrideWith((ref) async => home),
      homeCoachProvider.overrideWith((ref) async => coach),
      lesvoorbereidingProvider.overrideWith((ref) async => voorbereiding),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Ruime hoogte zodat de hele sliverlijst rendert zonder scrollen --
  // voorkomt valse "findsNothing" door lazy sliver-opbouw buiten viewport.
  void gebruikRuimeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('HomeScreen -- widget-gedrag via ProviderScope-overrides', () {
    testWidgets('toont kerncijfers: lessen, voortgang% en aantal facturen',
        (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(lessenGevolgd: 13, lessenTotaal: 20),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: [_bouwFactuur()],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('13/20'), findsOneWidget);
      // 65% komt bewust 2x voor: de kerncijfer-tegel én de Mijn
      // voortgang-kaart tonen dezelfde afgeleide waarde (geen dubbele
      // databron, gewoon dezelfde bestaande voortgangPercent op 2 plekken).
      expect(find.text('65%'), findsNWidgets(2));
      expect(find.text('1'), findsOneWidget); // Facturen-tegel
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'volgende les toont tijd, instructeur en locatie, en navigeert naar '
        '/planning', (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: const [],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('20:00 — 21:00'), findsOneWidget);
      expect(find.text('Zaur'), findsOneWidget);
      expect(find.text('Overtoom 283, Amsterdam'), findsOneWidget);

      await tester.tap(find.text('20:00 — 21:00'));
      await tester.pumpAndSettle();
      expect(find.text('Planning-scherm'), findsOneWidget);
    });

    testWidgets('examenadvieskaart navigeert naar /examenadvies bij tik',
        (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: const [],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
        coach: const HomeCoachData(
          readinessScore: 79,
          status: 'Bijna examenklaar',
          advies: 'Extra aandacht voor kijkgedrag en bijzondere verrichtingen.',
          feedback: '',
          laatstGeoefend: [],
          heeftData: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Examenadvies'), findsOneWidget);
      expect(find.text('Bijna examenklaar'), findsOneWidget);

      await tester.tap(find.text('Examenadvies'));
      await tester.pumpAndSettle();
      expect(find.text('Examenadvies-scherm'), findsOneWidget);
    });

    testWidgets(
        'volledige "Openstaande facturen"-lijst staat niet meer op Home, '
        'ook niet met meerdere open facturen', (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: [
            _bouwFactuur(id: 'f-1'),
            _bouwFactuur(id: 'f-2'),
          ],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Openstaande facturen'), findsNothing);
      expect(find.text('F-2026-001'), findsNothing);
    });

    testWidgets(
        'geen urgente factuurkaart wanneer geen enkele factuur echt actie '
        'vereist', (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: [
            _bouwFactuur(
              status: FactuurStatus.open,
              vervaldatum: '2026-12-31', // ver in de toekomst
            ),
          ],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Factuur is verlopen'), findsNothing);
      expect(find.textContaining('Factuur verloopt over'), findsNothing);
      expect(find.text('Betaal factuur'), findsNothing);
      expect(find.text('Bekijk factuur'), findsNothing);
    });

    testWidgets(
        'geen urgente factuurkaart wanneer er helemaal geen open facturen '
        'zijn', (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: const [],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Betaal factuur'), findsNothing);
      expect(find.text('Bekijk factuur'), findsNothing);
    });

    testWidgets(
        'urgente factuurkaart verschijnt wanneer één factuur is verlopen, '
        'en navigeert direct naar die factuurdetail', (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: [
            _bouwFactuur(id: 'factuur-1', status: FactuurStatus.verlopen),
          ],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Factuur is verlopen'), findsOneWidget);
      expect(find.text('Bekijk factuur'), findsOneWidget);

      await tester.tap(find.text('Factuur is verlopen'));
      await tester.pumpAndSettle();
      expect(find.text('Factuurdetail-factuur-1'), findsOneWidget);
    });

    testWidgets(
        'urgente factuurkaart toont een samengevoegd label en navigeert naar '
        'de facturenlijst wanneer meerdere facturen verlopen zijn',
        (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: [
            _bouwFactuur(id: 'f-1', status: FactuurStatus.verlopen),
            _bouwFactuur(id: 'f-2', status: FactuurStatus.verlopen),
          ],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 facturen verlopen'), findsOneWidget);

      await tester.tap(find.text('2 facturen verlopen'));
      await tester.pumpAndSettle();
      expect(find.text('Facturen-scherm'), findsOneWidget);
    });

    testWidgets(
        'urgente factuurkaart verschijnt wanneer een open factuur binnen 3 '
        'dagen vervalt, en navigeert naar de factuurdetail', (tester) async {
      gebruikRuimeViewport(tester);
      final over2Dagen =
          DateTime.now().add(const Duration(days: 2)).toIso8601String();
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: [
            _bouwFactuur(
              id: 'f-bijna-verlopen',
              status: FactuurStatus.open,
              vervaldatum: over2Dagen,
            ),
          ],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Factuur verloopt over'), findsOneWidget);
      expect(find.text('Betaal factuur'), findsOneWidget);

      await tester.tap(find.text('Betaal factuur'));
      await tester.pumpAndSettle();
      expect(find.text('Factuurdetail-f-bijna-verlopen'), findsOneWidget);
    });

    testWidgets('header blijft ongewijzigd (eyebrow-datum en begroeting)',
        (tester) async {
      gebruikRuimeViewport(tester);
      await tester.pumpWidget(_bouwHomeScherm(
        profiel: _bouwProfiel(),
        home: HomeData(
          volgendeLes: _bouwLes(),
          openFacturen: const [],
          ongelezenNotificaties: 0,
          recenteNotificaties: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hoi, Lisa.'), findsOneWidget);
    });

    for (final breedte in [320.0, 360.0, 390.0, 393.0, 430.0]) {
      testWidgets('geen overflow op breedte ${breedte.toInt()}',
          (tester) async {
        tester.view.physicalSize = Size(breedte, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_bouwHomeScherm(
          profiel: _bouwProfiel(),
          home: HomeData(
            volgendeLes: _bouwLes(),
            openFacturen: [_bouwFactuur(status: FactuurStatus.verlopen)],
            ongelezenNotificaties: 3,
            recenteNotificaties: const [],
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('geen overflow bij 130% tekstschaal', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 2400),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _bouwHomeScherm(
            profiel: _bouwProfiel(),
            home: HomeData(
              volgendeLes: _bouwLes(),
              openFacturen: [_bouwFactuur(status: FactuurStatus.verlopen)],
              ongelezenNotificaties: 3,
              recenteNotificaties: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('home_screen.dart -- hiërarchie en verwijderingen (bron-guard)', () {
    late String bron;
    setUpAll(() {
      bron = File('lib/features/home/home_screen.dart').readAsStringSync();
    });

    test('volgende les staat vóór voorbereiding, voorbereiding vóór '
        'voortgang, voortgang vóór examenadvies', () {
      final volgendeLes = bron.indexOf("title: 'Volgende les'");
      final voorbereiding = bron.indexOf('_LesvoorbereidingCard(');
      final voortgang = bron.indexOf('_VoortgangCard(');
      final examenadvies = bron.indexOf('_ExamenadviesHero(');

      expect(volgendeLes, greaterThan(-1));
      expect(voorbereiding, greaterThan(volgendeLes));
      expect(voortgang, greaterThan(voorbereiding));
      expect(examenadvies, greaterThan(voortgang));
    });

    test('urgente factuurkaart staat na examenadvies en is voorwaardelijk',
        () {
      final examenadvies = bron.indexOf('_ExamenadviesHero(');
      final urgent = bron.indexOf('_UrgenteFactuurCard(');

      expect(urgent, greaterThan(examenadvies));
      expect(bron, contains('if (urgenteActie != null) ...['));
    });

    test('geen volledige openstaande-facturenlijst meer op Home', () {
      expect(bron, isNot(contains("'Openstaande facturen'")));
      expect(bron, isNot(contains('class _FactuurRij')));
      expect(bron, isNot(contains('openFacturen.take(2)')));
    });

    test('geen gekleurde side-stripe accentbalk meer (Impeccable-verbod)',
        () {
      expect(bron, isNot(contains('class _ActieCard')));
      expect(bron, isNot(contains('class _VolgendeActieCard')));
    });

    test('gedeelde SectionHeader wordt hergebruikt i.p.v. een privé-duplicaat',
        () {
      expect(bron, contains('SectionHeader('));
      expect(bron, isNot(contains('class _SectionLabel')));
    });

    test('navigatie blijft ongewijzigd naar bestaande routes', () {
      expect(bron, contains("context.go('/planning')"));
      expect(bron, contains("context.go('/voortgang')"));
      expect(bron, contains("context.push('/examenadvies')"));
      expect(bron, contains("context.push('/lesvoorbereiding')"));
      expect(bron, contains("context.go('/facturen')"));
      expect(bron, contains("context.push('/facturen/\${f.id}')"));
      // De notificatie-navigatie zelf is sinds de header-refactor verplaatst
      // naar de gedeelde HomeHeader (shared/widgets/home_header.dart) --
      // home_screen.dart geeft alleen nog de losse waarden door.
      final headerBron =
          File('lib/shared/widgets/home_header.dart').readAsStringSync();
      expect(headerBron, contains("context.go('/notificaties')"));
    });

    test('header en business-providers blijven ongewijzigd', () {
      // Sinds de header-refactor gebruikt Home de eigen HomeHeader
      // (klantio_header_test.dart dekt HomeHeader zelf uitgebreid) i.p.v.
      // rechtstreeks MainTabHeader -- geen MainDetailHeader/terugpijl.
      expect(bron, contains('HomeHeader('));
      expect(bron, isNot(contains('MainDetailHeader')));
      expect(bron, contains('ref.watch(mijnProfielProvider)'));
      expect(bron, contains('ref.watch(homeProvider)'));
      expect(bron, contains('ref.watch(homeCoachProvider)'));
      expect(bron, contains('ref.watch(lesvoorbereidingProvider)'));
    });
  });

  group('Navbar blijft ongewijzigd (bron-guard, mirror van '
      'main_detail_header_test.dart)', () {
    test('main_scaffold.dart bevat nog steeds precies één '
        'PremiumBottomNavBar-klasse (niet aangeraakt in deze taak)', () {
      final bron =
          File('lib/shared/widgets/main_scaffold.dart').readAsStringSync();
      final treffers = RegExp(r'class PremiumBottomNavBar').allMatches(bron);
      expect(treffers.length, 1);
    });

    test('HomeScreen gebruikt nog steeds HomeHeader, geen eigen AppBar', () {
      final bron =
          File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(bron, contains('HomeHeader('));
      expect(bron, isNot(contains('appBar: AppBar(')));
    });
  });
}
