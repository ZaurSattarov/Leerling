import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:leerling_app/features/auth/verificatie_screen.dart';
import 'package:leerling_app/features/koppelcode/koppel_keuze_screen.dart';
import 'package:leerling_app/features/koppelcode/koppelcode_screen.dart';
import 'package:leerling_app/shared/widgets/settings_design.dart';

Widget _app(Widget home, {String pad = '/start'}) {
  final router = GoRouter(
    initialLocation: pad,
    routes: [
      GoRoute(path: '/start', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/koppelcode', builder: (_, __) => const KoppelKeuzeScreen()),
      GoRoute(
        path: '/koppelcode/handmatig',
        builder: (_, __) => const KoppelcodeInvoerenScreen(),
      ),
      GoRoute(
        path: '/verificatie',
        builder: (_, __) => const VerificatieScreen(email: 'test@example.com'),
      ),
      GoRoute(path: '/login', builder: (_, __) => const Text('LOGIN-STUB')),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  group('LA-13: Uitloggen staat niet op de Terug-positie en vraagt bevestiging',
      () {
    testWidgets('Koppel je account: Uitloggen rechtsboven, bevestiging',
        (tester) async {
      await tester.pumpWidget(_app(const SizedBox(), pad: '/koppelcode'));
      await tester.pumpAndSettle();

      final uitlog = find.text('Uitloggen');
      expect(uitlog, findsOneWidget);
      final scherm = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(tester.getCenter(uitlog).dx, greaterThan(scherm.width / 2),
          reason: 'Uitloggen hoort rechts, niet op de Terug-plek');

      await tester.tap(uitlog);
      await tester.pumpAndSettle();
      expect(find.text('Weet je zeker dat je wilt uitloggen?'), findsOneWidget);

      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();
      expect(find.text('Koppel je account'), findsOneWidget);
    });

    testWidgets('Koppelcode invoeren: Terug-pijl links, Uitloggen rechts',
        (tester) async {
      await tester.pumpWidget(_app(const SizedBox(), pad: '/koppelcode/handmatig'));
      await tester.pumpAndSettle();

      final terug = find.byTooltip('Terug');
      expect(terug, findsOneWidget);
      final scherm = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(tester.getCenter(terug).dx, lessThan(scherm.width / 2));
      expect(tester.getCenter(find.text('Uitloggen')).dx,
          greaterThan(scherm.width / 2));

      // Terug zonder vorig scherm gaat naar de keuze, nooit naar uitloggen.
      await tester.tap(terug);
      await tester.pumpAndSettle();
      expect(find.text('Koppel je account'), findsOneWidget);
    });
  });

  group('LA-04: toegankelijkheid auth en koppelflow', () {
    testWidgets('koppelcodeveld heeft een label en icoonknoppen een naam',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const SizedBox(), pad: '/koppelcode/handmatig'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Koppelcode'), findsWidgets);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('verificatiecode: acht vakjes met "Cijfer n van 8", 56 dp hoog',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const SizedBox(), pad: '/verificatie'));
      await tester.pumpAndSettle();

      for (var i = 1; i <= 8; i++) {
        expect(find.bySemanticsLabel('Cijfer $i van 8'), findsOneWidget);
      }
      final hoogte = tester.getSize(find.bySemanticsLabel('Cijfer 1 van 8')).height;
      expect(hoogte, greaterThanOrEqualTo(48));
      expect(find.byTooltip('Terug'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  testWidgets('LA-12/LA-29: Terug en Opslaan in de instellingen-kop hebben een naam',
      (tester) async {
    final handle = tester.ensureSemantics();
    final ctrl = TextEditingController(text: 'Leerling');
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: SettingsScaffold(
          titel: 'Persoonlijke gegevens',
          onSave: () {},
          children: [SettingsVeld(controller: ctrl, label: 'Voornaam')],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Terug'), findsOneWidget);
    expect(find.byTooltip('Opslaan'), findsOneWidget);
    // TalkBack leest label + waarde: 'Voornaam, Leerling'.
    expect(find.bySemanticsLabel(RegExp('Voornaam')), findsWidgets);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
