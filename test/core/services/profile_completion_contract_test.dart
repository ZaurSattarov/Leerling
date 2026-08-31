import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profielafronding gebruikt uitsluitend de beveiligde RPC', () {
    final source =
        File('lib/core/services/student_service.dart').readAsStringSync();
    expect(source, contains("'voltooi_leerling_profiel'"));
    expect(source, contains("'p_achternaam'"));
    expect(source, contains("'p_geboortedatum'"));
    expect(source, contains("'p_avatar_id'"));
  });

  test('profile gate hervat incomplete profiel-flow', () {
    final source =
        File('lib/shared/widgets/student_profile_gate.dart').readAsStringSync();
    expect(source, contains('isProfielCompleet'));
    expect(source, contains("'/profiel-afronden'"));
  });

  test('splash behandelt profielnetwerkfout niet als ontbrekend profiel', () {
    final source =
        File('lib/features/splash/splash_screen.dart').readAsStringSync();
    expect(source, contains('on ProfileLookupException'));
    expect(source, contains("context.go('/home')"));
    expect(
      source,
      isNot(contains('profielcheck fout')),
    );
  });
}
