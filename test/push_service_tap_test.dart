import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/services/push_service.dart';
import 'package:leerling_app/models/notificatie.dart';

void main() {
  group('PushService.canNavigateForTap', () {
    test('alle gates true → mag navigeren', () {
      expect(
        PushService.canNavigateForTap(
          bootstrapComplete: true,
          hasUser: true,
          hasRouter: true,
          appPastSplash: true,
        ),
        isTrue,
      );
    });

    test('bootstrap nog niet klaar maar app voorbij splash → mag navigeren', () {
      expect(
        PushService.canNavigateForTap(
          bootstrapComplete: false,
          hasUser: true,
          hasRouter: true,
          appPastSplash: true,
        ),
        isTrue,
      );
    });

    test('geen router → geen navigatie', () {
      expect(
        PushService.canNavigateForTap(
          bootstrapComplete: true,
          hasUser: true,
          hasRouter: false,
          appPastSplash: true,
        ),
        isFalse,
      );
    });
  });

  group('Notificatie.fromPushData', () {
    test('gebruikt target_route uit FCM data', () {
      final n = Notificatie.fromPushData({
        'notification_id': 'abc',
        'type': 'lesson_feedback',
        'target_route': '/planning/les-uuid',
        'app_type': 'leerling',
      });
      expect(n.targetRoute, '/planning/les-uuid');
    });

    test('examens query-route blijft behouden', () {
      final n = Notificatie.fromPushData({
        'notification_id': 'abc',
        'type': 'exam_result',
        'target_route': '/examens?exam=examen-uuid',
      });
      expect(n.targetRoute, '/examens?exam=examen-uuid');
    });
  });
}
