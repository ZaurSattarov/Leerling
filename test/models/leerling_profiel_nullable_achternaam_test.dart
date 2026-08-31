import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/models/leerling_profiel.dart';

import 'dart:io';

void main() {
  test('voorlopig leerlingprofiel accepteert een null achternaam', () {
    final profiel = LeerlingProfiel.fromJson({
      'id': 'student-1',
      'instructeur_id': 'instructeur-1',
      'voornaam': 'Sara',
      'achternaam': null,
      'pakket': 'standaard',
      'status': 'actief',
      'lessen_totaal': 0,
      'lessen_gevolgd': 0,
      'rijbewijs_soort': 'B',
      'transmissie': 'manual',
    });

    expect(profiel.achternaam, isEmpty);
    expect(profiel.volledigeNaam, 'Sara');
  });

  test('Leerling-app behoudt het canonical koppelcode-RPC-contract', () {
    final source =
        File('lib/core/services/student_service.dart').readAsStringSync();

    expect(source, contains("'koppel_leerling_met_code'"));
    expect(source, contains("'p_koppel_code'"));
  });
}
