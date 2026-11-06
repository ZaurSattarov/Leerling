import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/komende_les_filter.dart';
import 'package:leerling_app/features/voortgang/voortgang_trends_provider.dart';
import 'package:leerling_app/models/les.dart';

Les les({
  String status = 'gepland',
  String? instructeurNaam = 'Sanne',
}) =>
    Les.fromJson({
      'id': 'l1',
      'leerling_id': 's1',
      'datum': '2026-11-06',
      'starttijd': '13:00',
      'eindtijd': '14:00',
      'status': status,
      'instructeur_naam': instructeurNaam,
    });

void main() {
  group('lopende les', () {
    test('tijdens de les is hij bezig', () {
      expect(isLesBezig(les(), DateTime(2026, 11, 6, 13, 57)), isTrue);
    });
    test('voor de start en na het einde niet', () {
      expect(isLesBezig(les(), DateTime(2026, 11, 6, 12, 59)), isFalse);
      expect(isLesBezig(les(), DateTime(2026, 11, 6, 14)), isFalse);
    });
    test('een afgeronde les is nooit bezig', () {
      expect(
        isLesBezig(les(status: 'afgerond'), DateTime(2026, 11, 6, 13, 30)),
        isFalse,
      );
    });
  });

  group('instructeursnaam', () {
    test('een e-mailadres wordt niet als naam getoond', () {
      expect(
          les(instructeurNaam: 'iemand@voorbeeld.nl').instructeurNaam, isNull);
    });
    test('een gewone naam blijft staan', () {
      expect(les().instructeurNaam, 'Sanne');
    });
  });

  group('reden examenadvies', () {
    test('noemt maximaal twee aandachtspunten', () {
      expect(
        examenadviesRedenTekst(
          toonScore: true,
          statusLabel: 'Nog oefenen',
          aandachtspunten: ['Voertuigbeheersing', 'Rotondes', 'Keren'],
        ),
        'Aandachtspunten: Voertuigbeheersing, Rotondes',
      );
    });
    test('geen reden als de leerling klaar is of de score ontbreekt', () {
      expect(
        examenadviesRedenTekst(
          toonScore: true,
          statusLabel: 'Klaar voor examen',
          aandachtspunten: ['Rotondes'],
        ),
        isNull,
      );
      expect(
        examenadviesRedenTekst(
          toonScore: false,
          statusLabel: 'Nog oefenen',
          aandachtspunten: ['Rotondes'],
        ),
        isNull,
      );
    });
  });
}
