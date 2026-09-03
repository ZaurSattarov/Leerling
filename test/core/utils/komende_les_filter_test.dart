// Centrale DateTime-logica voor Home ("Volgende les") en
// Planning ("Mijn lessen -> Komende lessen").

import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/komende_les_filter.dart';
import 'package:leerling_app/models/les.dart';

Les _les({
  required String id,
  required String datum,
  required String start,
  required String einde,
}) {
  return Les(
    id: id,
    instructeurId: 'i1',
    leerlingId: 'l1',
    datum: datum,
    starttijd: start,
    eindtijd: einde,
    duurMinuten: 60,
    status: LesStatus.gepland,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

void main() {
  group('combineerLesDateTime', () {
    test('maakt lokale DateTime van datum + HH:MM en HH:MM:SS', () {
      expect(
        combineerLesDateTime('2026-09-03', '11:00'),
        DateTime(2026, 9, 3, 11, 0),
      );
      expect(
        combineerLesDateTime('2026-09-03', '09:05:07'),
        DateTime(2026, 9, 3, 9, 5, 7),
      );
    });
  });

  group('isKomendeLes -- basis', () {
    test('les morgen is komend, ongeacht tijdstip', () {
      final nu = DateTime(2026, 8, 20, 23, 0);
      expect(
        isKomendeLes(datum: '2026-08-21', starttijd: '08:00:00', nu: nu),
        isTrue,
      );
    });

    test('les gisteren is nooit komend', () {
      final nu = DateTime(2026, 8, 20, 8, 0);
      expect(
        isKomendeLes(datum: '2026-08-19', starttijd: '23:00:00', nu: nu),
        isFalse,
      );
    });
  });

  group('isKomendeLes -- vandaag', () {
    test('les vandaag met starttijd nog niet gepasseerd is komend', () {
      final nu = DateTime(2026, 8, 20, 14, 0);
      expect(
        isKomendeLes(datum: '2026-08-20', starttijd: '15:00:00', nu: nu),
        isTrue,
      );
    });

    test('les vandaag waarvan de eindtijd voorbij is, is niet komend', () {
      final nu = DateTime(2026, 8, 20, 11, 0);
      expect(
        isKomendeLes(
          datum: '2026-08-20',
          starttijd: '09:00',
          eindtijd: '10:00',
          nu: nu,
        ),
        isFalse,
      );
    });

    test('lopende les (start voorbij, eind nog niet) blijft komend', () {
      final nu = DateTime(2026, 8, 20, 9, 30);
      expect(
        isKomendeLes(
          datum: '2026-08-20',
          starttijd: '09:00',
          eindtijd: '10:00',
          nu: nu,
        ),
        isTrue,
      );
    });

    test('les die exact nu begint telt als komend via eindtijd', () {
      final nu = DateTime(2026, 8, 20, 15, 0, 0);
      expect(
        isKomendeLes(
          datum: '2026-08-20',
          starttijd: '15:00:00',
          eindtijd: '16:00:00',
          nu: nu,
        ),
        isTrue,
      );
    });

    test('vroege les voorbij, latere les vandaag blijft komend', () {
      final nu = DateTime(2026, 8, 20, 12, 0);
      expect(
        isKomendeLes(
          datum: '2026-08-20',
          starttijd: '09:00',
          eindtijd: '10:00',
          nu: nu,
        ),
        isFalse,
      );
      expect(
        isKomendeLes(
          datum: '2026-08-20',
          starttijd: '17:00',
          eindtijd: '18:00',
          nu: nu,
        ),
        isTrue,
      );
    });
  });

  group('isKomendeLes -- week-/maandgrens', () {
    test('weekgrens: zondag 23:50 -> les maandag 00:30 is komend', () {
      final nu = DateTime(2026, 8, 16, 23, 50);
      expect(
        isKomendeLes(datum: '2026-08-17', starttijd: '00:30:00', nu: nu),
        isTrue,
      );
    });

    test('maandgrens: 31 augustus -> les 1 september is komend', () {
      final nu = DateTime(2026, 8, 31, 10, 0);
      expect(
        isKomendeLes(datum: '2026-09-01', starttijd: '09:00:00', nu: nu),
        isTrue,
      );
    });

    test('jaargrens: 31 december -> les 1 januari is komend', () {
      final nu = DateTime(2026, 12, 31, 20, 0);
      expect(
        isKomendeLes(datum: '2027-01-01', starttijd: '09:00:00', nu: nu),
        isTrue,
      );
    });
  });

  group('isKomendeLes -- lokale DateTime / DST', () {
    test('toekomstige dag na wintertijd-overgang blijft komend', () {
      final nu = DateTime(2026, 10, 25, 23, 30);
      expect(
        isKomendeLes(datum: '2026-10-26', starttijd: '01:00:00', nu: nu),
        isTrue,
      );
      expect(
        isKomendeLes(
          datum: '2026-10-25',
          starttijd: '23:00:00',
          eindtijd: '23:20:00',
          nu: nu,
        ),
        isFalse,
      );
    });
  });

  group('filterEnSorteerKomendeLessen / selecteerVolgendeLes', () {
    test(
        'Home en Mijn lessen kiezen dezelfde eerstvolgende les, '
        'ongeacht aanlevervolgorde', () {
      final nu = DateTime(2026, 9, 3, 10, 30);
      final wanorde = [
        _les(id: 'sep13', datum: '2026-09-13', start: '11:00', einde: '12:00'),
        _les(
            id: 'sep03-09',
            datum: '2026-09-03',
            start: '09:00',
            einde: '10:00'),
        _les(id: 'sep12', datum: '2026-09-12', start: '09:00', einde: '10:00'),
        _les(
            id: 'sep03-11',
            datum: '2026-09-03',
            start: '11:00',
            einde: '12:00'),
        _les(id: 'sep08', datum: '2026-09-08', start: '13:00', einde: '14:00'),
        _les(id: 'sep05', datum: '2026-09-05', start: '10:00', einde: '11:00'),
      ];

      final komend = filterEnSorteerKomendeLessen(wanorde, nu);
      expect(komend.map((l) => l.id).toList(), [
        'sep03-11',
        'sep05',
        'sep08',
        'sep12',
        'sep13',
      ]);
      expect(selecteerVolgendeLes(wanorde, nu)?.id, 'sep03-11');
      expect(komend.first.id, selecteerVolgendeLes(wanorde, nu)?.id);
      expect(komend.any((l) => l.id == 'sep03-09'), isFalse);
    });

    test('zelfde dag: vroegste toekomstige begintijd wint', () {
      final nu = DateTime(2026, 9, 3, 8, 0);
      final lessen = [
        _les(id: 'laat', datum: '2026-09-03', start: '17:00', einde: '18:00'),
        _les(id: 'vroeg', datum: '2026-09-03', start: '09:00', einde: '10:00'),
      ];
      expect(selecteerVolgendeLes(lessen, nu)?.id, 'vroeg');
    });

    test('na verstrijken van een les schuift de volgende door', () {
      final lessen = [
        _les(
            id: 'ochtend', datum: '2026-09-03', start: '09:00', einde: '10:00'),
        _les(id: 'middag', datum: '2026-09-03', start: '11:00', einde: '12:00'),
        _les(id: 'later', datum: '2026-09-05', start: '10:00', einde: '11:00'),
      ];
      expect(
        selecteerVolgendeLes(lessen, DateTime(2026, 9, 3, 8, 0))?.id,
        'ochtend',
      );
      expect(
        selecteerVolgendeLes(lessen, DateTime(2026, 9, 3, 10, 30))?.id,
        'middag',
      );
      expect(
        selecteerVolgendeLes(lessen, DateTime(2026, 9, 3, 12, 1))?.id,
        'later',
      );
    });
  });

  group('vandaagString / nuTijdString', () {
    test('zero-padded formaat, ongeacht enkelcijferige maand/dag/uur', () {
      final nu = DateTime(2026, 3, 5, 9, 4, 2);
      expect(vandaagString(nu), '2026-03-05');
      expect(nuTijdString(nu), '09:04:02');
    });
  });

  group('komendeLesPostgrestFilter', () {
    test('filtert op eindtijd zodat een lopende les blijft meedoen', () {
      final nu = DateTime(2026, 8, 20, 14, 30, 0);
      expect(
        komendeLesPostgrestFilter(nu),
        'datum.gt.2026-08-20,and(datum.eq.2026-08-20,eindtijd.gt.14:30:00)',
      );
    });
  });
}
