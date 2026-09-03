import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/examenadvies/examenadvies_data.dart';

void main() {
  test('fromRpc mapped canonical backend payload', () {
    final advies = ExamenadviesData.fromRpc({
      'status': 'klaarVoorExamen',
      'statusLabel': 'Klaar voor examen',
      'score': 100,
      'heeftBetrouwbareScore': true,
      'uitleg': 'test',
      'sterkePunten': ['Voertuigbeheersing'],
      'nogOefenen': <String>[],
      'ontwikkeling': '',
      'volgendeStap': 'Blijf de huidige lijn vasthouden tot het examen.',
      'instructeurFeedback': null,
      'categorieen': [
        {
          'naam': 'Verkeer',
          'huidigOpVijf': 5,
          'trend': 'stijgt',
          'terugkerendProbleem': false,
        },
      ],
      'aantalBeoordelingen': 3,
      'resterendeLessen': 'Je instructeur kan een examen of proefexamen inplannen.',
      'gebaseerdOp': ['Vaardigheidsbeoordelingen van je instructeur'],
    });

    expect(advies.status, ExamenadviesStatus.klaarVoorExamen);
    expect(advies.score, 100);
    expect(advies.categorieen.single.trend, VaardigheidTrend.stijgt);
  });

  test('toont 1 decimaal zonder scores te herberekenen', () {
    final advies = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 40,
      'heeftBetrouwbareScore': true,
      'uitleg': 'test',
      'sterkePunten': <String>[],
      'nogOefenen': <String>['Observatie'],
      'ontwikkeling': '',
      'volgendeStap': 'test',
      'categorieen': [
        {
          'naam': 'Voertuigbeheersing',
          'huidigOpVijf': 2.0,
          'trend': 'stabiel',
          'terugkerendProbleem': false,
        },
        {
          'naam': 'Observatie',
          'huidigOpVijf': 1.7,
          'trend': 'daalt',
          'terugkerendProbleem': true,
        },
      ],
      'aantalBeoordelingen': 3,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });

    expect(advies.categorieen[0].scoreLabel, '2.0');
    expect(advies.categorieen[1].scoreLabel, '1.7');
    expect(advies.categorieen[0].scoreAfgerond, isNot(3));
  });

  test('fromRpc zonder payload toont geen neppercentage', () {
    final advies = ExamenadviesData.fromRpc(null);
    expect(advies.score, isNull);
    expect(advies.heeftBetrouwbareScore, isFalse);
    expect(advies.status, ExamenadviesStatus.onvoldoendeData);
  });
}
