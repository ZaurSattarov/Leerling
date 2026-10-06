import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/splash/splash_screen.dart';

void main() {
  // Let op: alle pumps hieronder blijven bewust ONDER de totale
  // animatieduur (1900ms) -- bij afronding roept SplashScreen zelf
  // `_bootstrap()` aan (Supabase.instance.client.auth...), en Supabase is
  // in deze widget-test niet geïnitialiseerd. Dit bestand test dus alleen
  // de visuele compositie/animatievolgorde, niet de post-animatie
  // navigatie (die hoort bij een aparte, met Supabase-mocking opgezette
  // test).
  group('Leerling splash ("Behaald"-merkteken)', () {
    testWidgets(
      'toont merkteken, KLANTIO en LEERLINGENPORTAAL als gecentreerde '
      'compositie op de Leerling-achtergrondkleur (#1C2636)',
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

        final markFinder = find.byKey(const ValueKey('splash-logo-mark'));
        final klantioFinder = find.byKey(const ValueKey('splash-klantio'));
        final portaalFinder =
            find.byKey(const ValueKey('splash-leerlingenportaal'));

        expect(markFinder, findsOneWidget);
        expect(klantioFinder, findsOneWidget);
        expect(portaalFinder, findsOneWidget);

        // Achtergrond is het donker van het Leerling-app-icoon, zodat de
        // overgang icoon -> splash naadloos is.
        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(SplashScreen),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(coloredBox.color, const Color(0xFF1C2636));

        // Merkteken staat gecentreerd boven KLANTIO.
        final markRect = tester.getRect(markFinder);
        final klantioRect = tester.getRect(klantioFinder);
        expect(markRect.center.dx, closeTo(klantioRect.center.dx, 0.5));
        expect(markRect.bottom, lessThan(klantioRect.top));

        // LEERLINGENPORTAAL staat onder KLANTIO en hangt net voorbij de
        // rechterrand van het woordmerk.
        final portaalRect = tester.getRect(portaalFinder);
        expect(portaalRect.top, greaterThan(klantioRect.bottom));
        expect(portaalRect.right, greaterThan(klantioRect.right));
        expect(portaalRect.width, lessThan(klantioRect.width));

        await tester.pump(const Duration(milliseconds: 1400));
      },
    );

    testWidgets(
      'animatievolgorde: drie witte blokken, dan het roze blok, dan het '
      'doel-hoekje, daarna LEERLINGENPORTAAL',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: SplashScreen()),
          ),
        );

        double opacityOf(String key) => tester
            .widget<Opacity>(
              find
                  .descendant(
                    of: find.byKey(ValueKey(key)),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity;

        const witLb = 'splash-mark-wit-linksboven';
        const witRo = 'splash-mark-wit-rechtsonder';
        const roze = 'splash-mark-roze';
        const doel = 'splash-mark-doel';
        const portaal = 'splash-leerlingenportaal';

        await tester.pump(const Duration(milliseconds: 1));
        expect(opacityOf(witLb), lessThan(0.05));
        expect(opacityOf(roze), 0.0);
        expect(opacityOf(doel), 0.0);
        expect(opacityOf(portaal), 0.0);

        // Rond 0.72s: de witte basis staat, het roze blok is onderweg, het
        // doel nog niet.
        await tester.pump(const Duration(milliseconds: 720));
        expect(opacityOf(witLb), greaterThan(0.95));
        expect(opacityOf(witRo), greaterThan(0.95));
        expect(opacityOf(roze), inExclusiveRange(0.0, 1.0));
        expect(opacityOf(doel), 0.0);

        // Rond 1.22s: roze blok en doel-hoekje staan, LEERLINGENPORTAAL is
        // nog bezig.
        await tester.pump(const Duration(milliseconds: 500));
        expect(opacityOf(roze), 1.0);
        expect(opacityOf(doel), 1.0);
        expect(opacityOf(portaal), lessThan(1.0));

        // Rond 1.5s: alles volledig zichtbaar, vlak voor de uitgang.
        await tester.pump(const Duration(milliseconds: 280));
        expect(opacityOf(portaal), greaterThan(0.95));

        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
