import 'package:flutter_test/flutter_test.dart';

import 'package:leerling_app/features/profiel/profile_hero_copy.dart';
import 'package:leerling_app/models/instructeur.dart';
import 'package:leerling_app/models/leerling_profiel.dart';

LeerlingProfiel _leerling({
  String voornaam = 'Teo',
  String achternaam = 'Seee',
  LeerlingStatus status = LeerlingStatus.actief,
}) {
  return LeerlingProfiel(
    id: 'l1',
    instructeurId: 'i1',
    voornaam: voornaam,
    achternaam: achternaam,
    pakket: PakketType.standaard,
    status: status,
    lessenTotaal: 20,
    lessenGevolgd: 4,
    aangemaaktOp: '2026-01-01',
    bijgewerktOp: '2026-01-01',
  );
}

void main() {
  test('naam primair, rijschool secundair, geen e-mail', () {
    final copy = buildLearnerProfileHeroCopy(
      profiel: _leerling(),
      instructeur: const Instructeur(
        id: 'i1',
        rijschoolNaam: 'RIJ PRO',
        naam: 'Joost',
      ),
    );
    expect(copy.primaryTitle, 'Teo Seee');
    expect(copy.schoolLine, 'RIJ PRO');
    expect(copy.statusLabel, 'Actief');
    expect(copy.statusTone, LearnerHeroBadgeTone.success);
  });

  test('valt terug op instructeurnaam als rijschool ontbreekt', () {
    final copy = buildLearnerProfileHeroCopy(
      profiel: _leerling(),
      instructeur: const Instructeur(id: 'i1', naam: 'Joost'),
    );
    expect(copy.schoolLine, 'Joost');
  });

  test('lege profiel crasht niet', () {
    final copy = buildLearnerProfileHeroCopy(
      profiel: null,
      instructeur: null,
    );
    expect(copy.primaryTitle, 'Mijn profiel');
    expect(copy.schoolLine, isNull);
  });

  test('bestaande leerlingstatussen krijgen bestaande kleuren', () {
    expect(
      buildLearnerProfileHeroCopy(
        profiel: _leerling(status: LeerlingStatus.geslaagd),
        instructeur: null,
      ).statusTone,
      LearnerHeroBadgeTone.success,
    );
    expect(
      buildLearnerProfileHeroCopy(
        profiel: _leerling(status: LeerlingStatus.gestopt),
        instructeur: null,
      ).statusTone,
      LearnerHeroBadgeTone.ink,
    );
    expect(
      buildLearnerProfileHeroCopy(
        profiel: _leerling(status: LeerlingStatus.wachtlijst),
        instructeur: null,
      ).statusTone,
      LearnerHeroBadgeTone.warning,
    );
  });
}
