import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/models/instructeur.dart';
import 'package:leerling_app/models/leerling_profiel.dart';

LeerlingProfiel _profiel({String? pakketNaam}) {
  return LeerlingProfiel(
    id: '1',
    instructeurId: 'i',
    voornaam: 'Test',
    achternaam: 'Leerling',
    pakket: PakketType.standaard,
    status: LeerlingStatus.actief,
    lessenTotaal: 10,
    lessenGevolgd: 0,
    aangemaaktOp: '2026-01-01',
    bijgewerktOp: '2026-01-01',
    pakketNaam: pakketNaam,
  );
}

void main() {
  test('schoolnaam is nooit een e-mailadres', () {
    const metMail = Instructeur(
      id: '1',
      rijschoolNaam: 'school@example.com',
      naam: 'Sam',
    );
    expect(metMail.weergaveNaam, 'Sam');

    const alleenMail = Instructeur(
      id: '1',
      rijschoolNaam: 'school@example.com',
      naam: 'ook@example.com',
    );
    expect(alleenMail.weergaveNaam, 'Je rijschool');
  });

  test('pakketnaam komt uit het toegewezen pakket', () {
    expect(
      _profiel(pakketNaam: 'Testpakket 10 lessen').pakketWeergaveNaam,
      'Testpakket 10 lessen',
    );
    expect(
      _profiel(pakketNaam: 'Testpakket 10 lessen').pakketLabelMetAantal(10),
      'Testpakket 10 lessen',
    );
    expect(_profiel().pakketWeergaveNaam, 'Standaard');
    expect(_profiel().pakketLabelMetAantal(10), 'Standaard 10 lessen');
  });
}
