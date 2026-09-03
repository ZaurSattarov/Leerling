import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leerling_app/features/auth/login_screen.dart';

void main() {
  group('leerlingToonAppleLogin', () {
    test('Android verbergt Apple volledig', () {
      expect(
        leerlingToonAppleLogin(
          isWeb: false,
          isAndroid: true,
          isIOS: false,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
    });

    test('iOS toont Apple', () {
      expect(
        leerlingToonAppleLogin(
          isWeb: false,
          isAndroid: false,
          isIOS: true,
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });

    test('web toont Apple nooit', () {
      expect(
        leerlingToonAppleLogin(
          isWeb: true,
          isAndroid: false,
          isIOS: true,
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
    });
  });
}
