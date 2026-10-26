import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/providers/theme_provider.dart';
import 'package:leerling_app/features/profiel/app_instellingen_screen.dart';
import 'package:leerling_app/shared/widgets/isomorphic_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('LA-14: tik op de donkere-modus-knop wisselt het thema en de '
      'animatie stopt', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            themeMode: ref.watch(themeModeProvider),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const AppInstellingenScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.byType(IsomorphicDarkModeToggle));
    // pumpAndSettle faalt (timeout) als er een animatie blijft doorlopen.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(container.read(themeModeProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('klantio-theme'), 'dark');

    await tester.tap(find.byType(IsomorphicDarkModeToggle));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
