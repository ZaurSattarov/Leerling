import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/models/arrival_session.dart';

void main() {
  group('ArrivalSession.fromRow', () {
    test('parseert een geldige rij correct', () {
      final endsAt = DateTime.now().add(const Duration(minutes: 5)).toUtc();
      final session = ArrivalSession.fromRow({
        'id': 'sess-1',
        'lesson_id': 'les-1',
        'status': 'active',
        'ends_at': endsAt.toIso8601String(),
        'location_visibility': 'hidden',
      });
      expect(session, isNotNull);
      expect(session!.id, 'sess-1');
      expect(session.lessonId, 'les-1');
      expect(session.status, 'active');
      expect(session.locationVisibility, 'hidden');
    });

    test('null rij -> null (geen sessie te tonen)', () {
      expect(ArrivalSession.fromRow(null), isNull);
    });

    test('ontbrekende ends_at -> null (fail-closed, niet crashen)', () {
      final session = ArrivalSession.fromRow({
        'id': 'sess-1',
        'lesson_id': 'les-1',
        'status': 'active',
      });
      expect(session, isNull);
    });

    test('ontbrekend id -> null', () {
      final session = ArrivalSession.fromRow({
        'lesson_id': 'les-1',
        'status': 'active',
        'ends_at': DateTime.now().toIso8601String(),
      });
      expect(session, isNull);
    });
  });

  group('isActive / isVisible', () {
    test('status active + ends_at in de toekomst -> isActive true', () {
      final session = ArrivalSession(
        id: 'x',
        lessonId: 'les-1',
        status: 'active',
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        locationVisibility: 'hidden',
      );
      expect(session.isActive(), true);
    });

    test('ends_at gepasseerd -> isActive false, ook al status=active', () {
      final session = ArrivalSession(
        id: 'x',
        lessonId: 'les-1',
        status: 'active',
        endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
        locationVisibility: 'hidden',
      );
      expect(session.isActive(), false);
    });

    test('status stopped -> isActive false', () {
      final session = ArrivalSession(
        id: 'x',
        lessonId: 'les-1',
        status: 'stopped',
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        locationVisibility: 'hidden',
      );
      expect(session.isActive(), false);
    });

    test('location_visibility visible -> isVisible true, anders false', () {
      final zichtbaar = ArrivalSession(
        id: 'x',
        lessonId: 'les-1',
        status: 'active',
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        locationVisibility: 'visible',
      );
      final verborgen = ArrivalSession(
        id: 'x',
        lessonId: 'les-1',
        status: 'active',
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        locationVisibility: 'hidden',
      );
      expect(zichtbaar.isVisible, true);
      expect(verborgen.isVisible, false);
    });
  });
}
