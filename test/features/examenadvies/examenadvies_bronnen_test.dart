import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/examenadvies/examenadvies_data.dart';

void main() {
  test('fromRpc negeert dossier-JSON en leest alleen RPC-categorieën', () {
    final advies = ExamenadviesData.fromRpc({
      'status': 'nogNietKlaar',
      'score': 27,
      'heeftBetrouwbareScore': true,
      'uitleg': 'test',
      'sterkePunten': <String>[],
      'nogOefenen': <String>['Voertuigbeheersing'],
      'ontwikkeling': '',
      'volgendeStap': 'test',
      'vaardigheden': {
        'stuurcontrole': 5,
        'kijkgedrag': 5,
      },
      'categorieen': [
        {
          'naam': 'Voertuigbeheersing',
          'huidigOpVijf': 1.0,
          'trend': 'stabiel',
          'terugkerendProbleem': false,
        },
        {
          'naam': 'Observatie',
          'huidigOpVijf': 1.0,
          'trend': 'stabiel',
          'terugkerendProbleem': false,
        },
      ],
      'aantalBeoordelingen': 1,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });

    expect(advies.score, 27);
    expect(advies.status, ExamenadviesStatus.nogNietKlaar);
    expect(advies.categorieen[0].scoreLabel, '1.0');
    expect(advies.categorieen[1].scoreLabel, '1.0');
  });

  test('fromRpc toont actuele dossierwaarde 5.0 zonder clientformule', () {
    final advies = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 63,
      'heeftBetrouwbareScore': true,
      'uitleg': 'test',
      'sterkePunten': <String>['Voertuigbeheersing', 'Observatie'],
      'nogOefenen': <String>['Verkeer'],
      'ontwikkeling': '',
      'volgendeStap': 'test',
      'categorieen': [
        {
          'naam': 'Voertuigbeheersing',
          'huidigOpVijf': 5.0,
          'trend': 'daalt',
          'terugkerendProbleem': false,
        },
        {
          'naam': 'Observatie',
          'huidigOpVijf': 5.0,
          'trend': 'daalt',
          'terugkerendProbleem': false,
        },
      ],
      'aantalBeoordelingen': 4,
      'resterendeLessen': '',
      'gebaseerdOp': <String>['Actuele vaardigheden van je instructeur'],
    });

    expect(advies.categorieen[0].scoreLabel, '5.0');
    expect(advies.categorieen[1].scoreLabel, '5.0');
    expect(advies.score, 63);
  });

  test('Leerling-leespad is rpc_get_examenadvies, geen student_exam_readiness',
      () {
    final service =
        File('lib/core/services/student_service.dart').readAsStringSync();
    final provider = File('lib/features/examenadvies/examenadvies_provider.dart')
        .readAsStringSync();
    final coach =
        File('lib/features/home/home_coach_provider.dart').readAsStringSync();

    expect(service, contains("'rpc_get_examenadvies'"));
    expect(provider, contains('StudentService.getExamenadvies'));
    expect(provider, isNot(contains('getExamReadiness')));
    expect(coach, contains('examenadviesProvider'));
    expect(coach, isNot(contains('getExamReadiness')));
    expect(coach, isNot(contains('student_exam_readiness')));
  });
}
