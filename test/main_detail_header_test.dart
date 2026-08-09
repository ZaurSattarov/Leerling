// Tests voor de gedeelde detailheader (MainDetailHeader) en de
// terugnavigatie-unificatie over alle detail-/subschermen. Sommige
// schermen (factuurdetail, examenadvies, ...) hebben Supabase/Riverpod-
// afhankelijkheden die niet zonder zware mocking-infrastructuur
// widget-test-baar zijn -- daarom draaien de interactieve/geometrische
// tests rechtstreeks tegen MainDetailHeader (de daadwerkelijk herbruikte
// widget), en toetsen de structurele checks per scherm via brontekst --
// dezelfde beproefde aanpak als premium_bottom_nav_bar_test.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/shared/widgets/main_detail_header.dart';

Widget _wrapMetRouter({
  required Widget detailScherm,
  String initialLocation = '/detail',
  String? fallbackTestRoute,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/root',
        builder: (_, __) => const Scaffold(body: Text('Root-scherm')),
      ),
      GoRoute(
        path: '/detail',
        builder: (_, __) => Scaffold(body: detailScherm),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('MainDetailHeader -- widget-rendering', () {
    testWidgets(
        'toont titel en terugpijl, geometrisch gecentreerd -- geen eyebrow '
        'meer', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(_wrapMetRouter(
        detailScherm: const MainDetailHeader(
          title: 'Examenadvies',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Examenadvies'), findsOneWidget);
      expect(find.byKey(const Key('main_detail_header_back')), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Geometrisch gecentreerd: het midden van de titel valt samen met het
      // horizontale midden van het SCHERM, niet alleen het midden van de
      // ruimte die na de terugpijl overblijft.
      final schermMidden =
          tester.getSize(find.byType(MaterialApp)).width / 2;
      final titelMidden = tester.getCenter(find.text('Examenadvies')).dx;
      expect(titelMidden, closeTo(schermMidden, 1.0));
    });

    testWidgets('geen dubbele header -- precies één terugpijl-knop',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(_wrapMetRouter(
        detailScherm: const MainDetailHeader(
          title: 'Examenadvies',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main_detail_header_back')), findsOneWidget);
      expect(find.byType(MainDetailHeader), findsOneWidget);
    });

    testWidgets('achtergrond is de donkerblauwe gradient, geen witte AppBar',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(_wrapMetRouter(
        detailScherm: const MainDetailHeader(
          title: 'Factuur',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(MainDetailHeader),
            matching: find.byType(Container),
          )
          .first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.first, const Color(0xFF141C2B));
      // Zelfde bron van waarheid als MainTabHeader: geen afgeronde
      // onderhoeken, geen schaduw.
      expect(decoration.borderRadius, isNull);
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets('statusbadge (actions) blijft zichtbaar naast de titel',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(_wrapMetRouter(
        detailScherm: const MainDetailHeader(
          title: 'Factuur',
          actions: [Chip(label: Text('Betaald'))],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Betaald'), findsOneWidget);
    });

    for (final breedte in [320.0, 390.0, 430.0]) {
      testWidgets('geen overflow op breedte ${breedte.toInt()}',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(breedte, 200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapMetRouter(
          detailScherm: const MainDetailHeader(
            title: 'Lespakket & voortgang',
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('geen overflow op breedte ${breedte.toInt()} bij 130% '
          'tekstschaal', (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(breedte, 200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(breedte, 200),
              textScaler: const TextScaler.linear(1.3),
            ),
            child: const Scaffold(
              body: MainDetailHeader(
                title: 'Lespakket & voortgang',
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('MainDetailHeader -- terugnavigatie', () {
    testWidgets('terugpijl roept pop aan wanneer er een navigatiestack is',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = GoRouter(
        initialLocation: '/root',
        routes: [
          GoRoute(
            path: '/root',
            builder: (_, __) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: null,
                  child: const Text('Root-scherm'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, __) => const Scaffold(
              body: MainDetailHeader(
                title: 'Examenadvies',
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push('/detail');
      await tester.pumpAndSettle();

      expect(find.text('Examenadvies'), findsOneWidget);
      await tester.tap(find.byKey(const Key('main_detail_header_back')));
      await tester.pumpAndSettle();

      expect(find.text('Root-scherm'), findsOneWidget);
      expect(find.text('Examenadvies'), findsNothing);
    });

    testWidgets(
        'terugpijl gaat naar de fallbackroute wanneer pop niet mogelijk is '
        '(bv. cold start / directe deep link)', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = GoRouter(
        initialLocation: '/detail',
        routes: [
          GoRoute(
            path: '/home-fallback',
            builder: (_, __) => const Scaffold(body: Text('Home-fallback')),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, __) => const Scaffold(
              body: MainDetailHeader(
                title: 'Examenadvies',
                fallbackRoute: '/home-fallback',
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Geen stack: dit is de initiële locatie (net als een cold start /
      // directe deep link zonder voorgaande navigatiehistorie).
      await tester.tap(find.byKey(const Key('main_detail_header_back')));
      await tester.pumpAndSettle();

      expect(find.text('Home-fallback'), findsOneWidget);
    });

    testWidgets('geen dubbele pop -- na terug is er geen tweede terugpijl '
        'meer beschikbaar om per ongeluk nogmaals te poppen', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = GoRouter(
        initialLocation: '/root',
        routes: [
          GoRoute(
            path: '/root',
            builder: (_, __) => const Scaffold(body: Text('Root-scherm')),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, __) => const Scaffold(
              body: MainDetailHeader(
                title: 'Examenadvies',
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push('/detail');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('main_detail_header_back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main_detail_header_back')), findsNothing);
      expect(find.text('Root-scherm'), findsOneWidget);
    });
  });

  group('Detailschermen gebruiken de gedeelde MainDetailHeader (brontekst)', () {
    final schermen = <String, String>{
      'Factuurdetails': 'lib/features/facturen/factuur_detail_screen.dart',
      'Examenadvies': 'lib/features/examenadvies/examenadvies_screen.dart',
      'Lesvoorbereiding':
          'lib/features/lesvoorbereiding/lesvoorbereiding_screen.dart',
      'Meldingen': 'lib/features/notificaties/notificaties_screen.dart',
      'Mijn tijden': 'lib/features/beschikbaarheid/beschikbaarheid_screen.dart',
    };

    for (final entry in schermen.entries) {
      test('${entry.key} gebruikt MainDetailHeader en heeft een terugpijl',
          () {
        final bron = File(entry.value).readAsStringSync();
        expect(bron, contains('MainDetailHeader'),
            reason: '${entry.key} moet MainDetailHeader gebruiken');
        expect(bron, isNot(contains('DetailGradientHeader')),
            reason: '${entry.key} mag de oude witte AppBar-header niet meer '
                'gebruiken');
        expect(bron, isNot(contains('SliverAppBar(')),
            reason: '${entry.key} mag geen eigen SliverAppBar meer hebben');
        expect(bron, isNot(contains('appBar: AppBar(')),
            reason: '${entry.key} mag geen letterlijke witte AppBar meer '
                'hebben');
      });
    }

    test('Factuurdetails toont geen witte AppBar meer', () {
      final bron = File('lib/features/facturen/factuur_detail_screen.dart')
          .readAsStringSync();
      expect(bron, isNot(contains('AppColors.white')));
    });
  });

  group('Bodycontent blijft bereikbaar (brontekst, geen verwijderde '
      'functionaliteit)', () {
    test('Factuurdetail behoudt iDEAL-betaalknop, downloadfunctie en '
        'businesslogica', () {
      final bron = File('lib/features/facturen/factuur_detail_screen.dart')
          .readAsStringSync();
      expect(bron, contains('Betaal met iDEAL'));
      expect(bron, contains('Download factuur'));
      expect(bron, contains('requestMollieFactuurPayment'));
      expect(bron, contains('StatusPill.factuur'));
    });

    test('Beschikbaarheid behoudt de "Tijd toevoegen"-knop', () {
      final bron =
          File('lib/features/beschikbaarheid/beschikbaarheid_screen.dart')
              .readAsStringSync();
      expect(bron, contains('Tijd toevoegen'));
    });

    test('Meldingen behoudt notificatielogica ongewijzigd', () {
      final bron = File('lib/features/notificaties/notificaties_screen.dart')
          .readAsStringSync();
      expect(bron, contains('notificatiesProvider'));
      expect(bron, contains('_markeerAlles'));
    });
  });

  group('Detailroutes staan buiten de ShellRoute (geen navbar op '
      'detailschermen)', () {
    test('les-logboek, examenadvies, examens, lesvoorbereiding, '
        'planning/:id, voortgang/lespakket en facturen/:id zijn geen '
        'kind-routes van de ShellRoute meer', () {
      final bron = File('lib/app.dart').readAsStringSync();
      final shellStart = bron.indexOf('ShellRoute(');
      final shellBlok = bron.substring(shellStart);

      // Binnen de ShellRoute mogen alleen de vijf echte hoofdtab-schermen
      // nog voorkomen.
      expect(shellBlok, isNot(contains('LesLogboekScreen')));
      expect(shellBlok, isNot(contains('ExamenadviesScreen')));
      expect(shellBlok, isNot(contains('ExamensScreen')));
      expect(shellBlok, isNot(contains('LesvoorbereidingScreen')));
      expect(shellBlok, isNot(contains('LesDetailScreen')));
      expect(shellBlok, isNot(contains('LespakketDetailScreen')));
      expect(shellBlok, isNot(contains('FactuurDetailScreen')));

      // ...maar ze bestaan wel nog als losse top-level routes (voor de
      // ShellRoute), elk in StudentProfileGate.
      final voorShell = bron.substring(0, shellStart);
      expect(voorShell, contains("path: '/les-logboek'"));
      expect(voorShell, contains("path: '/examenadvies'"));
      expect(voorShell, contains("path: '/examens'"));
      expect(voorShell, contains("path: '/lesvoorbereiding'"));
      expect(voorShell, contains("path: '/planning/:id'"));
      expect(voorShell, contains("path: '/voortgang/lespakket'"));
      expect(voorShell, contains("path: '/facturen/:id'"));
    });

    test('de vijf hoofdtabs staan nog wél in de ShellRoute', () {
      final bron = File('lib/app.dart').readAsStringSync();
      final shellStart = bron.indexOf('ShellRoute(');
      final shellBlok = bron.substring(shellStart);

      expect(shellBlok, contains('HomeScreen'));
      expect(shellBlok, contains('PlanningScreen'));
      expect(shellBlok, contains('VoortgangScreen'));
      expect(shellBlok, contains('FacturenScreen'));
      expect(shellBlok, contains('ProfielScreen'));
    });
  });

  group('Hoofdtabs en navbar blijven ongewijzigd', () {
    test('main_scaffold.dart bevat nog steeds precies één '
        'PremiumBottomNavBar-klasse (niet aangeraakt in deze taak)', () {
      final bron =
          File('lib/shared/widgets/main_scaffold.dart').readAsStringSync();
      final treffers =
          RegExp(r'class PremiumBottomNavBar').allMatches(bron);
      expect(treffers.length, 1);
    });

    for (final scherm in [
      'lib/features/planning/planning_screen.dart',
      'lib/features/voortgang/voortgang_screen.dart',
      'lib/features/facturen/facturen_screen.dart',
      'lib/features/profiel/profiel_screen.dart',
    ]) {
      test('$scherm gebruikt nog steeds MainTabHeader (geen '
          'MainDetailHeader, geen terugpijl)', () {
        final bron = File(scherm).readAsStringSync();
        expect(bron, contains('MainTabHeader('));
        expect(bron, isNot(contains('MainDetailHeader')));
      });
    }

    // Home is de bewuste uitzondering (zie klantio_header_test.dart voor de
    // volledige HomeHeader-dekking): een persoonlijke begroeting via
    // HomeHeader i.p.v. de gecentreerde MainTabHeader-titel, maar wel
    // dezelfde KlantioHeaderShell (identieke hoogte/padding), dus ook geen
    // terugpijl/MainDetailHeader.
    test('lib/features/home/home_screen.dart gebruikt HomeHeader (de '
        'bewuste uitzondering op MainTabHeader), geen MainDetailHeader', () {
      final bron = File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(bron, contains('HomeHeader('));
      expect(bron, isNot(contains('MainDetailHeader')));
    });
  });
}
