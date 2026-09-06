import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/splash/splash_screen.dart';

void main() {
  // Let op: alle pumps hieronder blijven bewust ONDER de totale
  // animatieduur (3000ms) -- bij afronding roept SplashScreen zelf
  // `_bootstrap()` aan (Supabase.instance.client.auth...), en Supabase is
  // in deze widget-test niet geïnitialiseerd. Dit bestand test dus alleen
  // de visuele compositie/animatievolgorde, niet de post-animatie
  // navigatie (die is functioneel ongewijzigd overgenomen en hoort bij een
  // aparte, met Supabase-mocking opgezette test).
  group('Leerling splash (1-op-1 poort van de Instructeur-splash)', () {
    testWidgets(
      'toont ICON, KLANTIO en LEERLINGENPORTAAL als losse, gecentreerde '
      'compositie op de exacte Leerling-achtergrondkleur (#131528)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: SplashScreen()),
          ),
        );

        final lFinder = find.byKey(const ValueKey('splash-l-icon'));
        final klantioFinder = find.byKey(const ValueKey('splash-klantio'));
        final portaalFinder =
            find.byKey(const ValueKey('splash-leerlingenportaal'));

        expect(lFinder, findsOneWidget);
        expect(klantioFinder, findsOneWidget);
        expect(portaalFinder, findsOneWidget);

        // Achtergrond is exact #131528 -- de enige visuele afwijking t.o.v.
        // de Instructeur-splash.
        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(SplashScreen),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(coloredBox.color, const Color(0xFF131528));

        // ICON staat gecentreerd boven KLANTIO (zelfde horizontale center),
        // exact dezelfde compositieregel als bij de Instructeur-app.
        final lRect = tester.getRect(lFinder);
        final klantioRect = tester.getRect(klantioFinder);
        expect(lRect.center.dx, closeTo(klantioRect.center.dx, 0.5));
        expect(lRect.bottom, lessThan(klantioRect.top));

        // LEERLINGENPORTAAL staat onder KLANTIO en hangt net voorbij de
        // rechterrand van het woordmerk (niet gecentreerd, niet flush) --
        // zelfde regel als RIJPLANNER bij de Instructeur-app.
        final portaalRect = tester.getRect(portaalFinder);
        expect(portaalRect.top, greaterThan(klantioRect.bottom));
        expect(portaalRect.right, greaterThan(klantioRect.right));
        expect(portaalRect.width, lessThan(klantioRect.width));

        // Losse aanpassing: LEERLINGENPORTAAL heeft een extra verticale
        // drop t.o.v. KLANTIO (pure paint-verschuiving) -- de afstand moet
        // dus duidelijk groter zijn dan de kale intro-gap alleen.
        expect(
          portaalRect.top - klantioRect.bottom,
          greaterThan(6),
          reason: 'LEERLINGENPORTAAL moet duidelijk verder van KLANTIO af '
              'staan dan zonder de extra drop',
        );

        await tester.pump(const Duration(milliseconds: 1500));
      },
    );

    testWidgets(
      'animatievolgorde: ICON verschijnt eerst, dan KLANTIO, dan '
      'LEERLINGENPORTAAL (zelfde timing als de Instructeur-app)',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: SplashScreen()),
          ),
        );

        double opacityOf(Key key) => tester
            .widget<Opacity>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Opacity),
              ),
            )
            .opacity;

        const lKey = ValueKey('splash-l-icon');
        const klantioKey = ValueKey('splash-klantio');
        const portaalKey = ValueKey('splash-leerlingenportaal');

        await tester.pump(const Duration(milliseconds: 1));
        expect(opacityOf(lKey), lessThan(0.05));
        expect(opacityOf(klantioKey), 0.0);
        expect(opacityOf(portaalKey), 0.0);

        // Rond 0.5s: ICON volledig zichtbaar, KLANTIO nog niet.
        await tester.pump(const Duration(milliseconds: 500));
        expect(opacityOf(lKey), greaterThan(0.95));
        expect(opacityOf(klantioKey), lessThan(1.0));

        // Rond 0.85s: KLANTIO volledig zichtbaar, LEERLINGENPORTAAL nog
        // niet klaar.
        await tester.pump(const Duration(milliseconds: 350));
        expect(opacityOf(klantioKey), greaterThan(0.95));
        expect(opacityOf(portaalKey), lessThan(1.0));

        // Rond 1.1s: alle drie volledig zichtbaar.
        await tester.pump(const Duration(milliseconds: 250));
        expect(opacityOf(portaalKey), greaterThan(0.95));

        await tester.pump(const Duration(milliseconds: 900));
      },
    );
  });
}
