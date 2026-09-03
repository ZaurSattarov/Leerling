import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/features/notificaties/notificaties_provider.dart';
import 'package:leerling_app/features/notificaties/notificaties_screen.dart';
import 'package:leerling_app/models/notificatie.dart';
import 'package:leerling_app/shared/widgets/app_card.dart';

Notificatie _melding({required bool gelezen}) => Notificatie(
      id: gelezen ? 'mock-gelezen' : 'mock-ongelezen',
      leerlingId: 'leerling-1',
      instructeurId: 'instr-1',
      titel: 'Nieuwe lesevaluatie',
      bericht: 'De evaluatie van je rijles op 3 sep staat klaar',
      type: 'lesson_feedback',
      gelezen: gelezen,
      aangemaaktOp: DateTime.now().toUtc().toIso8601String(),
      targetRoute: '/lesvoorbereiding',
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('IconBadge centreert het icoon in een 40x40 rounded-xl vak',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconBadge(
              icon: Icons.rate_review_rounded,
              color: Color(0xFF16A34A),
              size: 40,
            ),
          ),
        ),
      ),
    );

    final vak = tester.getRect(find.byType(IconBadge));
    expect(vak.width, 40);
    expect(vak.height, 40);

    final icoon = tester.getRect(find.byIcon(Icons.rate_review_rounded));
    expect(icoon.center.dx, closeTo(vak.center.dx, 0.5));
    expect(icoon.center.dy, closeTo(vak.center.dy, 0.5));

    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(IconBadge),
        matching: find.byType(Container),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(12));
    expect(decoration.color, const Color(0xFFF0F2F5));
  });

  for (final gelezen in [false, true]) {
    testWidgets(
        'meldingskaart (${gelezen ? 'gelezen' : 'ongelezen'}) '
        'houdt het type-icoon in het midden van het icoonvak', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificatiesProvider.overrideWith(
              (ref) async => [_melding(gelezen: gelezen)],
            ),
          ],
          child: const MaterialApp(home: NotificatiesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nieuwe lesevaluatie'), findsOneWidget);
      final vak = tester.getRect(find.byType(IconBadge));
      final icoon = tester.getRect(find.byIcon(Icons.rate_review_rounded));
      expect(icoon.center.dx, closeTo(vak.center.dx, 0.5));
      expect(icoon.center.dy, closeTo(vak.center.dy, 0.5));
      expect(tester.takeException(), isNull);
    });
  }
}
