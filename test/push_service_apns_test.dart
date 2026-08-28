// Tests voor PushService.waitForApnsToken (de begrensde retry rond
// FirebaseMessaging.getAPNSToken() — zie push_service.dart, Klantio iOS
// push-audit 2026-08-27: `firebase_messaging/apns-token-not-set` op iOS bij
// koude app-start).
//
// Bewust GEEN test die de echte FirebaseMessaging-plugin aanroept — dat zou
// platform-channel-mocks vereisen die dit project niet heeft en zou een
// bredere testinfra-toevoeging zijn dan deze minimale fix rechtvaardigt.
// `waitForApnsToken` is daarom injectable (`fetchApnsToken`), zodat de
// retry-/bounded-loop-logica los van de plugin geverifieerd kan worden.
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/services/push_service.dart';

void main() {
  group('PushService.waitForApnsToken', () {
    test('APNs token direct beschikbaar: geen retries nodig', () async {
      var calls = 0;
      final result = await PushService.waitForApnsToken(
        fetchApnsToken: () async {
          calls++;
          return 'fake-apns-token';
        },
        retryDelay: Duration.zero,
      );

      expect(result, 'fake-apns-token');
      expect(calls, 1);
    });

    test('APNs token pas na een paar pogingen beschikbaar (delayed init)',
        () async {
      var calls = 0;
      final result = await PushService.waitForApnsToken(
        fetchApnsToken: () async {
          calls++;
          if (calls < 3) return null;
          return 'fake-apns-token';
        },
        maxRetries: apnsTokenMaxRetries,
        retryDelay: Duration.zero,
      );

      expect(result, 'fake-apns-token');
      expect(calls, 3);
    });

    test('APNs token blijft null: stopt begrensd, geen oneindige loop',
        () async {
      var calls = 0;
      final result = await PushService.waitForApnsToken(
        fetchApnsToken: () async {
          calls++;
          return null;
        },
        maxRetries: apnsTokenMaxRetries,
        retryDelay: Duration.zero,
      );

      expect(result, isNull);
      expect(calls, apnsTokenMaxRetries);
    });

    test('respecteert een custom maxRetries', () async {
      var calls = 0;
      final result = await PushService.waitForApnsToken(
        fetchApnsToken: () async {
          calls++;
          return null;
        },
        maxRetries: 2,
        retryDelay: Duration.zero,
      );

      expect(result, isNull);
      expect(calls, 2);
    });
  });
}
