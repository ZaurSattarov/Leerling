import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/lespakket_voortgang.dart';
import 'package:leerling_app/models/leerling_profiel.dart';

// Overstap-import (optie B, 2026-11-03): pakket van 10 lessen waarvan 5 al
// gevolgd bij de vorige rijschoolsoftware. Dat staat in
// leerlingen.startsaldo_lessen_gevolgd; lessen_gevolgd telt alleen de in
// Klantio afgeronde lessen.
Map<String, dynamic> _profielJson({int lessenGevolgd = 0, int? startsaldo = 5}) => {
      'id': 'leerling-1',
      'instructeur_id': 'instr-1',
      'voornaam': 'Sanne',
      'achternaam': 'Voorbeeld',
      'pakket': 'standaard',
      'status': 'actief',
      'pakket_id': 'pakket-a',
      'pakket_naam': 'Pakket A',
      'pakket_lessen': 10,
      'losse_lessen': 0,
      'lessen_totaal': 10,
      'lessen_gevolgd': lessenGevolgd,
      if (startsaldo != null) 'startsaldo_lessen_gevolgd': startsaldo,
      'aangemaakt_op': '',
      'bijgewerkt_op': '',
    };

void main() {
  test('startsaldo telt mee als gevolgde pakketlessen', () {
    final p = LeerlingProfiel.fromJson(_profielJson());
    expect(p.lessenGevolgd, 5);
    expect(p.lessenTotaal, 10);

    final v = LespakketVoortgang.fromProfiel(profiel: p, lessen: const []);
    expect(v.afgerondeLessen, 5);
    expect(v.totaalLessen, 10);
    expect(v.percentageLabel, 50);
  });

  test('in Klantio afgeronde lessen komen bovenop het startsaldo', () {
    final p = LeerlingProfiel.fromJson(_profielJson(lessenGevolgd: 2));
    expect(p.lessenGevolgd, 7);
  });

  test('leerling zonder startsaldo blijft gelijk', () {
    final p = LeerlingProfiel.fromJson(_profielJson(lessenGevolgd: 3, startsaldo: null));
    expect(p.lessenGevolgd, 3);
  });
}
