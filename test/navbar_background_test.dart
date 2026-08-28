// Regressietest/source-guard voor de "donkergrijze achtergrondlaag achter
// de zwevende navbar"-bug. Root cause (1-op-1 zelfde mechanisme als de
// Instructeur-app, zie lib/shared/widgets/main_scaffold.dart): zonder
// `Scaffold.extendBody: true` stopt de body vóór de bottomNavigationBar-zone
// begint, waardoor de BackdropFilter in PremiumBottomNavBar geen
// paginacontent meer heeft om te vervagen en in plaats daarvan de vlakke
// Scaffold.backgroundColor toont als zichtbare grijze laag achter de witte
// pil.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/shared/widgets/main_scaffold.dart';

GoRouter _bouwShellRouter({String initialLocation = '/home'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const _LangeTestPagina(label: 'Home-inhoud'),
          ),
          GoRoute(
            path: '/profiel',
            builder: (_, __) =>
                const _LangeTestPagina(label: 'Profiel-inhoud'),
          ),
        ],
      ),
    ],
  );
}

/// Simuleert zowel een lange scrollpagina (veel content) als een normale
/// pagina -- de laatste regel moet in beide gevallen bereikbaar blijven en
/// nooit permanent achter de capsule verdwijnen.
class _LangeTestPagina extends StatelessWidget {
  final String label;
  const _LangeTestPagina({required this.label});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(label),
        for (var i = 0; i < 30; i++) SizedBox(height: 20, child: Text('$i')),
        const Text('Laatste regel'),
      ],
    );
  }
}

void main() {
  group('MainScaffold -- extendBody / transparantie (widget)', () {
    testWidgets('Scaffold heeft extendBody: true zodat de pagina-achtergrond '
        'onder de zwevende navbar doorloopt', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = _bouwShellRouter();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.extendBody, isTrue);
    });

    testWidgets('navbarwrapper (Padding rond PremiumBottomNavBar) heeft geen '
        'eigen achtergrondkleur -- alleen de pagina-achtergrond mag '
        'doorschijnen', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = _bouwShellRouter();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // De directe Padding-ouder van PremiumBottomNavBar mag geen
      // decoration/color hebben -- dat zou een "vaste rechthoek achter de
      // capsule" zijn, wat expliciet niet mag.
      final navBarFinder = find.byType(PremiumBottomNavBar);
      expect(navBarFinder, findsOneWidget);

      final paddingBoven = find
          .ancestor(of: navBarFinder, matching: find.byType(Padding))
          .first;
      final padding = tester.widget<Padding>(paddingBoven);
      expect(padding.child, isNotNull);

      // Er mag geen ColoredBox/Container met een eigen (donkere) kleur
      // tussen de Padding en PremiumBottomNavBar in zitten.
      final containersTussenin = find.ancestor(
        of: navBarFinder,
        matching: find.byType(Container),
      );
      for (final el in containersTussenin.evaluate()) {
        final container = el.widget as Container;
        // Alleen PremiumBottomNavBar's eigen Container (de glazen capsule
        // zelf) mag een decoration/kleur hebben -- die van de wrapper
        // ERBUITEN niet. We herkennen de capsule aan zijn vaste hoogte.
        if (container.constraints?.maxHeight == 56 ||
            (container.decoration is BoxDecoration &&
                (container.decoration as BoxDecoration).borderRadius !=
                    null)) {
          continue; // dit is de capsule zelf, geen wrapper-achtergrond.
        }
        expect(container.color, isNull,
            reason:
                'Geen enkele wrapper rond de navbar mag een eigen achtergrondkleur hebben');
      }
    });

    testWidgets('onderste SafeArea (indien aanwezig) voegt geen eigen '
        'achtergrondkleur toe', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = _bouwShellRouter();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // MainScaffold gebruikt bewust GEEN SafeArea rond de navbar (zie
      // toelichting in main_scaffold.dart) -- als die er ooit weer bij komt,
      // mag hij in ieder geval geen eigen kleur/decoration hebben.
      final scaffoldFinder = find.byType(Scaffold);
      final safeAreas = find.descendant(
        of: scaffoldFinder,
        matching: find.byType(SafeArea),
      );
      for (final el in safeAreas.evaluate()) {
        // SafeArea zelf heeft geen `color`-property -- een eventuele
        // achtergrond zou via een Container/ColoredBox-kind moeten komen.
        // We controleren dat de eerste kind geen ColoredBox is.
        final safeArea = el.widget as SafeArea;
        expect(safeArea.child, isNot(isA<ColoredBox>()));
      }
    });

    testWidgets('body-content blijft bereikbaar op een lange scrollpagina '
        '(laatste regel niet permanent achter de capsule)', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = _bouwShellRouter();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Laatste regel'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Laatste regel'), findsOneWidget);
    });

    testWidgets('alle vijf hoofdtabs renderen MainScaffold met extendBody '
        'true (Home, Planning, Voortgang, Facturen, Profiel)', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainScaffold(child: child),
            routes: [
              GoRoute(
                  path: '/home', builder: (_, __) => const Text('Home')),
              GoRoute(path: '/planning',
                  builder: (_, __) => const Text('Planning')),
              GoRoute(path: '/voortgang',
                  builder: (_, __) => const Text('Voortgang')),
              GoRoute(path: '/facturen',
                  builder: (_, __) => const Text('Facturen')),
              GoRoute(path: '/profiel',
                  builder: (_, __) => const Text('Profiel')),
            ],
          ),
        ],
      );
      for (final route in [
        '/home',
        '/planning',
        '/voortgang',
        '/facturen',
        '/profiel',
      ]) {
        router.go(route);
        await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
        await tester.pumpAndSettle();
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.extendBody, isTrue, reason: 'route $route');
      }
    });
  });

  group('MainScaffold -- capsule ongewijzigd (source-guard)', () {
    late String bron;
    setUpAll(() {
      bron =
          File('lib/shared/widgets/main_scaffold.dart').readAsStringSync();
    });

    test('Scaffold heeft extendBody: true', () {
      expect(bron, contains('extendBody: true'));
    });

    test('de wrapper rond bottomNavigationBar bevat geen eigen '
        'achtergrondkleur (geen Container/color/ColoredBox tussen '
        'IosNativeNavigationHost.fallback en PremiumBottomNavBar)', () {
      final start = bron.indexOf('fallback: Padding(');
      final eind = bron.indexOf('PremiumBottomNavBar(', start);
      expect(start, greaterThan(-1));
      expect(eind, greaterThan(start));
      final wrapperBlok = bron.substring(start, eind);
      expect(wrapperBlok, isNot(contains('color:')));
      expect(wrapperBlok, isNot(contains('ColoredBox')));
      expect(wrapperBlok, isNot(contains('Container(')));
      expect(wrapperBlok, isNot(contains('DecoratedBox')));
    });

    test('geen donkere/zwarte achtergrondkleur toegevoegd rond de '
        'bottomNavigationBar-zone', () {
      final start = bron.indexOf('bottomNavigationBar: IosNativeNavigationHost(');
      final eindeMethod =
          bron.indexOf('\n}', start) == -1 ? bron.length : bron.indexOf('\n}', start);
      final zone = bron.substring(start, eindeMethod);
      expect(zone, isNot(contains('Colors.black')));
      expect(zone, isNot(contains('grey.shade8')));
      expect(zone, isNot(contains('grey.shade9')));
      expect(zone, isNot(contains('0xFF1')));
      expect(zone, isNot(contains('0xFF0')));
    });

    test('de capsule zelf (PremiumBottomNavBar) is ongewijzigd: hoogte, '
        'radius, schaduw, glas-blur en actieve kleur blijven identiek', () {
      expect(bron, contains('const double _kBarHeight = 56;'));
      expect(bron, contains('BorderRadius.circular(radius)'));
      expect(bron, contains('ImageFilter.blur(sigmaX: 24, sigmaY: 24)'));
      expect(bron, contains('Colors.white.withValues(alpha: 0.78)'));
      expect(bron,
          contains('color: isActive ? AppColors.primary : Colors.transparent'));
    });

    test('Scaffold.backgroundColor blijft de lichte pagina-achtergrond '
        '(AppColors.surface), geen donkere kleur', () {
      expect(bron, contains('backgroundColor: AppColors.surface'));
    });
  });

  group('Bottom-clearance in hoofdschermen (source-guard)', () {
    test('NavShellTokens.contentBottomClearance bestaat en is 96', () {
      final bron = File('lib/core/constants/nav_shell_tokens.dart')
          .readAsStringSync();
      expect(bron, contains('contentBottomClearance = 96'));
    });

    for (final entry in {
      'Home': 'lib/features/home/home_screen.dart',
      'Facturen': 'lib/features/facturen/facturen_screen.dart',
      'Profiel': 'lib/features/profiel/profiel_screen.dart',
    }.entries) {
      test('${entry.key} reserveert NavShellTokens.contentBottomClearance '
          'zodat content niet achter de capsule verdwijnt', () {
        final bron = File(entry.value).readAsStringSync();
        expect(bron, contains('NavShellTokens.contentBottomClearance'));
      });
    }

    for (final entry in {
      'Planning': 'lib/features/planning/planning_screen.dart',
      'Voortgang': 'lib/features/voortgang/voortgang_screen.dart',
    }.entries) {
      test('${entry.key} had al voldoende (>=96) bottom-clearance, '
          'ongewijzigd gelaten', () {
        final bron = File(entry.value).readAsStringSync();
        expect(bron, contains('96'));
      });
    }
  });
}
