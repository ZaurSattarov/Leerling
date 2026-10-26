import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/services/leerling_notificatie_router.dart';
import 'package:leerling_app/features/notificaties/notificaties_provider.dart';
import 'package:leerling_app/features/notificaties/notificaties_screen.dart';
import 'package:leerling_app/models/notificatie.dart';

const _lesId = '3f2b6c1e-8a4d-4b7e-9c11-0a1b2c3d4e5f';

Notificatie _melding({
  String id = 'n1',
  String route = '/planning/$_lesId',
  String type = 'lesson_planned',
  bool gelezen = true,
  Map<String, dynamic> metadata = const {},
}) =>
    Notificatie(
      id: id,
      leerlingId: 'l1',
      instructeurId: 'i1',
      titel: 'Nieuwe les ingepland',
      bericht: 'Er staat een nieuwe rijles in je planning.',
      type: type,
      gelezen: gelezen,
      aangemaaktOp: DateTime.now().toUtc().toIso8601String(),
      targetRoute: route,
      metadata: metadata,
    );

void main() {
  group('Notificatie.lesId', () {
    test('uit /planning/:id', () {
      expect(_melding().lesId, _lesId);
    });

    test('uit metadata als er geen route naar de les is', () {
      final n = _melding(
        route: '/planning',
        type: 'lesson_cancelled',
        metadata: {'les_id': _lesId},
      );
      expect(n.lesId, _lesId);
    });

    test('meldingen zonder les hebben geen lesId', () {
      expect(_melding(route: '/facturen', type: 'invoice_created').lesId,
          isNull);
    });
  });

  group('lesVanMeldingVerwijderd', () {
    test('les bestaat -> niet verwijderd', () async {
      final r = await lesVanMeldingVerwijderd(_melding(),
          bestaandeLesIds: (ids) async => ids);
      expect(r, isFalse);
    });

    test('les ontbreekt -> verwijderd', () async {
      final r = await lesVanMeldingVerwijderd(_melding(),
          bestaandeLesIds: (ids) async => <String>{});
      expect(r, isTrue);
    });

    test('laadfout -> nooit "verwijderd" tonen', () async {
      final r = await lesVanMeldingVerwijderd(_melding(),
          bestaandeLesIds: (ids) async => throw Exception('offline'));
      expect(r, isFalse);
    });
  });

  testWidgets(
      'melding van verwijderde les: gedimd, label, tik = uitleg zonder '
      'navigatie', (tester) async {
    final melding = _melding();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificatiesProvider.overrideWith((ref) async => [melding]),
          verwijderdeLesMeldingenProvider
              .overrideWith((ref) async => {melding.id}),
        ],
        child: const MaterialApp(home: NotificatiesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Les verwijderd'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Les verwijderd')), findsWidgets);

    await tester.tap(find.text('Nieuwe les ingepland'));
    await tester.pumpAndSettle();

    expect(find.text(kLesVerwijderdUitleg), findsOneWidget);
    expect(find.byType(NotificatiesScreen), findsOneWidget);
  });
}
