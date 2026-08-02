// Regressietests voor de bottom navigation bar, 1-op-1 overgenomen uit de
// Instructeur-app (rijschool-planner-flutter). Dekt: geen overflow op de
// vereiste breedtes, tik-gedrag met de juiste index, kleuren, en dat alle
// labels altijd zichtbaar zijn (icoon+label samen, actief en inactief).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/core/constants/app_colors.dart';
import 'package:leerling_app/shared/widgets/main_scaffold.dart';

const _items = [
  NavBarItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: '/home'),
  NavBarItem(
      label: 'Planning',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      route: '/planning'),
  NavBarItem(
      label: 'Voortgang',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      route: '/voortgang'),
  NavBarItem(
      label: 'Facturen',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: '/facturen'),
  NavBarItem(
      label: 'Profiel',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: '/profiel'),
];

Future<int?> _pompNavBar(
  WidgetTester tester, {
  required int activeIndex,
  required double width,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = Size(width, 200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  int? getikt;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.surface,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: PremiumBottomNavBar(
              activeIndex: activeIndex,
              items: _items,
              onItemTap: (i) => getikt = i,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return getikt;
}

void main() {
  group('PremiumBottomNavBar -- geen overflow op vereiste breedtes', () {
    const breedtes = <String, double>{
      'iPhone SE (320)': 320,
      'iPhone 14 (390)': 390,
      'iPhone Pro Max (430)': 430,
      'Android smal (360)': 360,
    };

    for (final entry in breedtes.entries) {
      testWidgets('${entry.key} -- geen RenderFlex overflow', (tester) async {
        await _pompNavBar(tester, activeIndex: 0, width: entry.value);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('PremiumBottomNavBar -- functionaliteit', () {
    testWidgets('elke route heeft een eigen tikbaar element (5 tabs)',
        (tester) async {
      await _pompNavBar(tester, activeIndex: 0, width: 390);
      for (final item in _items) {
        expect(find.byKey(Key('nav_bar_tab_${item.route}')), findsOneWidget);
      }
    });

    testWidgets('tikken op elke tab geeft exact de bijbehorende index door',
        (tester) async {
      for (var i = 0; i < _items.length; i++) {
        int? getikt;
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = const Size(390, 200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: PremiumBottomNavBar(
                  activeIndex: 0,
                  items: _items,
                  onItemTap: (i) => getikt = i,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('nav_bar_tab_${_items[i].route}')));
        await tester.pump();
        expect(getikt, i);
      }
    });
  });

  group('PremiumBottomNavBar -- alle labels altijd zichtbaar', () {
    for (var i = 0; i < _items.length; i++) {
      testWidgets('${_items[i].label} actief -- alle 5 labels staan er',
          (tester) async {
        await _pompNavBar(tester, activeIndex: i, width: 390);
        for (final item in _items) {
          expect(find.text(item.label), findsOneWidget);
        }
      });
    }
  });

  group('PremiumBottomNavBar -- kleuren', () {
    testWidgets('actief icoon gebruikt activeIcon en is wit', (tester) async {
      await _pompNavBar(tester, activeIndex: 1, width: 390);
      final actiefIcon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const Key('nav_bar_tab_/planning')),
        matching: find.byType(Icon),
      ));
      expect(actiefIcon.icon, Icons.calendar_today_rounded);
      expect(actiefIcon.color, Colors.white);
    });

    testWidgets('inactieve iconen gebruiken AppColors.textSecondary',
        (tester) async {
      await _pompNavBar(tester, activeIndex: 1, width: 390);
      final inactiefIcon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const Key('nav_bar_tab_/home')),
        matching: find.byType(Icon),
      ));
      expect(inactiefIcon.icon, Icons.home_outlined);
      expect(inactiefIcon.color, AppColors.textSecondary);
    });
  });
}
