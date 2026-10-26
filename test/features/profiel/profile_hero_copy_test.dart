import 'package:flutter_test/flutter_test.dart';

import 'package:leerling_app/features/profiel/profile_hero_copy.dart';
import 'package:leerling_app/models/instructeur.dart';
import 'package:leerling_app/models/leerling_profiel.dart';

LeerlingProfiel _leerling({
  String voornaam = 'Teo',
  String achternaam = 'Seee',
  String? email,
  LeerlingStatus status = LeerlingStatus.actief,
}) {
  return LeerlingProfiel(
    id: 'l1',
    instructeurId: 'i1',
    voornaam: voornaam,
    achternaam: achternaam,
    email: email,
    pakket: PakketType.standaard,
    status: status,
    lessenTotaal: 20,
    lessenGevolgd: 4,
    aangemaaktOp: '2026-01-01',
    bijgewerktOp: '2026-01-01',
  );
}

void main() {
  test('kop toont het e-mailadres van de leerling, niet van de rijschool', () {
    final copy = buildLearnerProfileHeroCopy(
      profiel: _leerling(email: 'leerling@example.com'),
      instructeur: const Instructeur(
        id: 'i1',
        rijschoolNaam: 'school@example.com',
        naam: 'Joost',
        email: 'school@example.com',
      ),
      accountEmail: 'leerling@example.com',
    );
    expect(copy.primaryTitle, 'Teo Seee');
    expect(copy.schoolLine, 'leerling@example.com');
    expect(copy.schoolLine, isNot('school@example.com'));
    expect(copy.schoolLine, isNot('Joost'));
  });

  test('instructeur-adres wordt niet als leerlingadres getoond', () {
    final copy = buildLearnerProfileHeroCopy(
      profiel: _leerling(email: 'school@example.com'),
      instructeur: const Instructeur(
        id: 'i1',
        email: 'school@example.com',
      ),
      accountEmail: 'school@example.com',
    );
    expect(copy.schoolLine, isNull);
  });

  test('profiel-e-mail als het accountadres ontbreekt', () {
    final copy = buildLearnerProfileHeroCopy(
      profiel: _leerling(email: 'leerling@example.com'),
      instructeur: const Instructeur(id: 'i1', naam: 'Joost'),
    );
    expect(copy.schoolLine, 'leerling@example.com');
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
