import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/profiel/profiel_afronden_screen.dart';

void main() {
  test('een laat profiel wist een al getypte achternaam niet', () {
    final invulling = vulAlleenLegeProfielvelden(
      getypteAchternaam: 'Jansen',
      getyptAdres: '',
      gekozenAvatar: null,
      gekozenGeslacht: null,
      gekozenGeboortedatum: null,
      profielAchternaam: 'Oud',
      profielAdres: 'Dorpsstraat 1',
      profielAvatar: 'male_01',
      profielGeslacht: 'man',
      profielGeboortedatum: '2008-01-15',
    );

    expect(invulling.achternaam, 'Jansen');
    expect(invulling.adres, 'Dorpsstraat 1');
    expect(invulling.avatarId, 'male_01');
    expect(invulling.geboortedatum, DateTime.parse('2008-01-15'));
  });

  test('lege velden worden wel uit het profiel gevuld', () {
    final invulling = vulAlleenLegeProfielvelden(
      getypteAchternaam: '  ',
      getyptAdres: '',
      gekozenAvatar: 'female_02',
      gekozenGeslacht: 'vrouw',
      gekozenGeboortedatum: DateTime(2009, 3, 2),
      profielAchternaam: 'Bakker',
      profielAdres: null,
      profielAvatar: 'male_01',
      profielGeslacht: 'man',
      profielGeboortedatum: '2008-01-15',
    );

    expect(invulling.achternaam, 'Bakker');
    expect(invulling.adres, '');
    expect(invulling.avatarId, 'female_02');
    expect(invulling.geslacht, 'vrouw');
    expect(invulling.geboortedatum, DateTime(2009, 3, 2));
  });
}
