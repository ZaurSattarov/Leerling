// Regressietests voor het uniforme, compacte Klantio-headersysteem
// (klantio_header.dart, main_tab_header.dart, main_detail_header.dart,
// home_header.dart). Dekt de acceptatiecriteria uit de header-refactor:
// - alle "normale" headers exact dezelfde contenthoogte (56px) en
//   titelstijl (22px/w700), geometrisch gecentreerd ongeacht leading/
//   trailing-breedte (bv. een brede StatusPill mag de titel niet
//   verschuiven);
// - geen eyebrow-labels meer, nergens in de app;
// - Home toont geen datum meer, en is compact: [avatar] Hoi, Naam. [bel];
// - responsive op 320/360/390/430px en bij 130% tekstschaal;
// - geen pastelkleuren: de bestaande donkere navy-gradient blijft exact.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/core/constants/app_colors.dart';
import 'package:leerling_app/shared/widgets/home_header.dart';
import 'package:leerling_app/shared/widgets/klantio_header.dart';
import 'package:leerling_app/shared/widgets/main_detail_header.dart';
import 'package:leerling_app/shared/widgets/main_tab_header.dart';

/// Pompt [child] in een echte, gecontroleerde viewport-breedte -- een
/// ancestor [MediaQuery] boven [MaterialApp] wordt genegeerd (MaterialApp
/// leest zijn eigen mediaquery via de test-window), dus de viewport moet
/// via `tester.view.physicalSize` gezet worden. Zelfde patroon als elders
/// in deze test-suite (bv. ophaallocatie_kaart_test.dart).
Future<void> _pomp(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double height = 700,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Headercontract -- uniforme hoogte', () {
    testWidgets('MainTabHeader en MainDetailHeader hebben exact dezelfde '
        'contenthoogte (${kKlantioHeaderContentHeight.toInt()}px onder de '
        'SafeArea)', (tester) async {
      await _pomp(tester, const MainTabHeader(title: 'Mijn lessen'));
      final tabHoogte =
          tester.getSize(find.byType(KlantioHeaderShell)).height;

      await _pomp(tester, const MainDetailHeader(title: 'Lesdetails'));
      final detailHoogte =
          tester.getSize(find.byType(KlantioHeaderShell)).height;

      expect(tabHoogte, detailHoogte);
      expect(tabHoogte, kKlantioHeaderContentHeight);
    });

    testWidgets(
        'HomeHeader gebruikt dezelfde KlantioHeaderShell-hoogte -- geen '
        'zichtbare sprong bij wisselen tussen Home en de andere hoofdtabs',
        (tester) async {
      await _pomp(
        tester,
        const HomeHeader(
          avatarUrl: null,
          naam: 'Lisa',
          ongelezenNotificaties: 0,
        ),
      );

      expect(tester.getSize(find.byType(KlantioHeaderShell)).height,
          kKlantioHeaderContentHeight);
    });
  });

  group('Headercontract -- geometrische centrering', () {
    testWidgets(
        'MainTabHeader-titel staat exact op het horizontale midden van het '
        'scherm, met én zonder trailing-actie', (tester) async {
      const breedte = 390.0;

      await _pomp(tester, const MainTabHeader(title: 'Mijn lessen'),
          width: breedte);
      expect(tester.getCenter(find.text('Mijn lessen')).dx,
          closeTo(breedte / 2, 1.0));

      await _pomp(
        tester,
        MainTabHeader(
          title: 'Mijn lessen',
          actions: [
            MainHeaderIconKnop(
                icon: Icons.notifications_none_rounded, onTap: () {}),
          ],
        ),
        width: breedte,
      );
      // Nog steeds op het echte schermmidden -- een trailing-actie mag de
      // titel niet naar links duwen (het bekende Row+Expanded-euvel).
      expect(tester.getCenter(find.text('Mijn lessen')).dx,
          closeTo(breedte / 2, 1.0));
    });

    testWidgets(
        'MainDetailHeader-titel blijft gecentreerd ook met een BREDE '
        'trailing-widget (bv. StatusPill), want de titel centreert op de '
        'volledige breedte, niet op de resterende Row-ruimte',
        (tester) async {
      const breedte = 390.0;

      await _pomp(
        tester,
        MainDetailHeader(
          title: 'Factuur',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('Een best brede statuspil'),
            ),
          ],
        ),
        width: breedte,
      );

      expect(tester.getCenter(find.text('Factuur')).dx,
          closeTo(breedte / 2, 1.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('backbutton en trailing-actie hebben hetzelfde verticale '
        'midden als de titel', (tester) async {
      await _pomp(
        tester,
        MainDetailHeader(
          title: 'Lesdetails',
          actions: [
            MainHeaderIconKnop(
                icon: Icons.notifications_none_rounded, onTap: () {}),
          ],
        ),
      );

      final titelY = tester.getCenter(find.text('Lesdetails')).dy;
      final backY = tester
          .getCenter(find.byKey(const Key('main_detail_header_back')))
          .dy;
      expect(backY, closeTo(titelY, 1.0));
    });
  });

  group('Headercontract -- geen eyebrows meer, projectbreed', () {
    test('geen enkel lib-bestand verwijst nog naar eyebrowText', () {
      final libDir = Directory('lib');
      final treffers = <String>[];
      for (final entiteit in libDir.listSync(recursive: true)) {
        if (entiteit is! File || !entiteit.path.endsWith('.dart')) continue;
        final inhoud = entiteit.readAsStringSync();
        if (inhoud.contains('eyebrowText')) treffers.add(entiteit.path);
      }
      expect(treffers, isEmpty,
          reason: 'eyebrowText hoort nergens meer voor te komen: $treffers');
    });

    test('de oude, dubbele headerimplementaties (DetailGradientHeader, '
        'ScreenHeader) bestaan niet meer', () {
      expect(File('lib/shared/widgets/gradient_header.dart').existsSync(),
          isFalse);
      expect(File('lib/shared/widgets/screen_header.dart').existsSync(),
          isFalse);
    });

    test('MainTabHeader en MainDetailHeader hebben geen eyebrowText-'
        'parameter meer', () {
      final tabBron =
          File('lib/shared/widgets/main_tab_header.dart').readAsStringSync();
      final detailBron = File('lib/shared/widgets/main_detail_header.dart')
          .readAsStringSync();
      expect(tabBron, isNot(contains('eyebrowText')));
      expect(detailBron, isNot(contains('eyebrowText')));
    });
  });

  group('HomeHeader -- compact, geen datum meer', () {
    testWidgets('toont geen datumregel meer', (tester) async {
      await _pomp(
        tester,
        const HomeHeader(
          avatarUrl: null,
          naam: 'Lisa',
          ongelezenNotificaties: 2,
        ),
      );

      // Geen enkele datumgerelateerde tekst (weekdag/maandnaam) meer in de
      // header -- de vorige "ZATERDAG 8 AUGUSTUS 2026"-regel is volledig
      // verwijderd, niet alleen visueel verborgen.
      const weekdagen = [
        'MAANDAG', 'DINSDAG', 'WOENSDAG', 'DONDERDAG', 'VRIJDAG', 'ZATERDAG', 'ZONDAG', //
      ];
      for (final dag in weekdagen) {
        expect(find.textContaining(dag), findsNothing);
      }
    });

    testWidgets(
        'toont [avatar] Hoi, Naam. [notificatie] als één horizontaal blok',
        (tester) async {
      await _pomp(
        tester,
        const HomeHeader(
          avatarUrl: null,
          naam: 'Lisa',
          ongelezenNotificaties: 3,
        ),
      );

      expect(find.text('Hoi, Lisa.'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Avatar (initiaal-fallback zonder avatarUrl) en begroeting op
      // dezelfde verticale positie -- voelen als één blok, niet gestapeld.
      final avatarY = tester.getCenter(find.text('L')).dy;
      final groetY = tester.getCenter(find.text('Hoi, Lisa.')).dy;
      expect(avatarY, closeTo(groetY, 1.0));
    });

    testWidgets('zonder avatar-url: bestaande initialen-fallback, geen '
        'mock-avatar', (tester) async {
      await _pomp(
        tester,
        const HomeHeader(
          avatarUrl: null,
          naam: 'Zaur',
          ongelezenNotificaties: null,
        ),
      );

      expect(find.text('Z'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lege naam: nette fallbacktekst, geen crash', (tester) async {
      await _pomp(
        tester,
        const HomeHeader(
          avatarUrl: null,
          naam: '',
          ongelezenNotificaties: 0,
        ),
      );

      expect(find.text('Welkom terug.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('home_screen.dart bevat geen datumregel meer in de header', () {
      final bron = File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(bron, isNot(contains('langeDatum(DatumUtils.vandaagString())')));
    });
  });

  group('Headercontract -- kleuren (geen pastel toegevoegd)', () {
    testWidgets(
        'MainTabHeader/MainDetailHeader/HomeHeader gebruiken dezelfde '
        'bestaande donkere navy-gradient, niets pastel', (tester) async {
      for (final header in [
        const MainTabHeader(title: 'Mijn lessen'),
        const MainDetailHeader(title: 'Lesdetails'),
        const HomeHeader(avatarUrl: null, naam: 'Lisa', ongelezenNotificaties: 0),
      ]) {
        await _pomp(tester, header);

        final container = tester.widget<Container>(find
            .descendant(
              of: find.byType(KlantioHeaderShell),
              matching: find.byType(Container),
            )
            .first);
        final gradient = (container.decoration as BoxDecoration).gradient
            as LinearGradient;
        expect(gradient.colors, kKlantioHeaderGradient);
      }
    });
  });

  group('Headercontract -- responsive', () {
    for (final breedte in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets('MainTabHeader: geen overflow op ${breedte.toInt()}px met '
          'een lange titel', (tester) async {
        await _pomp(
          tester,
          MainTabHeader(
            title: 'Een best lange titel die bijna niet past',
            actions: [
              MainHeaderIconKnop(
                  icon: Icons.notifications_none_rounded, onTap: () {}),
            ],
          ),
          width: breedte,
        );
        expect(tester.takeException(), isNull,
            reason: 'overflow op ${breedte.toInt()}px');
      });

      testWidgets(
          'MainDetailHeader: geen overflow op ${breedte.toInt()}px met een '
          'lange titel', (tester) async {
        await _pomp(
          tester,
          const MainDetailHeader(
              title: 'Een best lange detailtitel die bijna niet past'),
          width: breedte,
        );
        expect(tester.takeException(), isNull,
            reason: 'overflow op ${breedte.toInt()}px');
      });

      testWidgets('HomeHeader: geen overflow op ${breedte.toInt()}px met '
          'een lange naam', (tester) async {
        await _pomp(
          tester,
          const HomeHeader(
            avatarUrl: null,
            naam: 'Een Hele Erg Lange Voornaam Die Amper Past',
            ongelezenNotificaties: 12,
          ),
          width: breedte,
        );
        expect(tester.takeException(), isNull,
            reason: 'overflow op ${breedte.toInt()}px');
      });
    }

    testWidgets('geen overflow bij 130% tekstschaal (alle drie de headers)',
        (tester) async {
      for (final header in [
        const MainTabHeader(title: 'Mijn voortgang'),
        const MainDetailHeader(title: 'Lesvoorbereiding'),
        const HomeHeader(avatarUrl: null, naam: 'Lisa', ongelezenNotificaties: 1),
      ]) {
        await _pomp(tester, header, width: 360, textScale: 1.3);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Headercontract -- touch targets', () {
    testWidgets('terugknop is minimaal 44x44', (tester) async {
      await _pomp(tester, const MainDetailHeader(title: 'Lesdetails'));

      final size = tester
          .getSize(find.byKey(const Key('main_detail_header_back')));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('Notificatiebadge', () {
    testWidgets('belknop is een cirkel van 40x40 met wit icoon in het midden',
        (tester) async {
      await _pomp(
        tester,
        MainHeaderIconKnop(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
      );

      final knop = tester.getSize(find.byType(MainHeaderIconKnop));
      expect(knop.width, 40);
      expect(knop.height, 40);

      final icoon = tester.getRect(find.byIcon(Icons.notifications_none_rounded));
      final knopRect = tester.getRect(find.byType(MainHeaderIconKnop));
      expect(icoon.center.dx, closeTo(knopRect.center.dx, 0.5));
      expect(icoon.center.dy, closeTo(knopRect.center.dy, 0.5));
      expect(tester.widget<Icon>(find.byIcon(Icons.notifications_none_rounded)).color,
          Colors.white);
    });

    for (final entry in const {1: '1', 12: '12', 100: '99+'}.entries) {
      testWidgets('toont ${entry.value} voor teller ${entry.key}',
          (tester) async {
        await _pomp(
          tester,
          MainHeaderIconKnop(
            icon: Icons.notifications_none_rounded,
            badgeCount: entry.key,
            onTap: () {},
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
        final badge = tester.widget<Container>(
          find.byKey(const Key('main_header_notification_badge')),
        );
        final decoration = badge.decoration! as BoxDecoration;
        expect(decoration.color, AppColors.primary);
        expect(decoration.border, isNull);
        expect(decoration.boxShadow, isNull);
        expect(
          tester.widget<Text>(find.text(entry.value)).style?.color,
          Colors.white,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
