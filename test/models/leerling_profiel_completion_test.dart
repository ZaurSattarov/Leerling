import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/models/leerling_profiel.dart';

void main() {
  test('voorlopig profiel is incompleet', () {
    final profiel = _profiel(achternaam: '', geboortedatum: null, email: null);
    expect(profiel.isProfielCompleet, isFalse);
  });

  test('achternaam geboortedatum auth-email en avatar maken profiel compleet',
      () {
    final profiel = _profiel(
      achternaam: 'Jansen',
      geboortedatum: '2001-04-12',
      email: 'sara@example.nl',
      avatarId: 'female_1',
    );
    expect(profiel.isProfielCompleet, isTrue);
  });

  test('avatar-url is ook een geldige afgeronde avatar', () {
    final profiel = _profiel(
      achternaam: 'Jansen',
      geboortedatum: '2001-04-12',
      email: 'sara@example.nl',
      avatarUrl: 'https://example.invalid/avatar.jpg',
    );
    expect(profiel.isProfielCompleet, isTrue);
  });
}

LeerlingProfiel _profiel({
  required String achternaam,
  required String? geboortedatum,
  required String? email,
  String? avatarId,
  String? avatarUrl,
}) {
  return LeerlingProfiel.fromJson({
    'id': 'student-1',
    'instructeur_id': 'instructor-1',
    'voornaam': 'Sara',
    'achternaam': achternaam,
    'email': email,
    'geboortedatum': geboortedatum,
    'avatar_id': avatarId,
    'avatar_url': avatarUrl,
  });
}
