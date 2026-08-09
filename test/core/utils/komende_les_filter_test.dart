// Tests voor de centrale "is deze les nog komend?"-logica
// (komende_les_filter.dart), gebruikt door StudentService.
// getMijnKomendeLessen -- de enige bron voor zowel Home ("Volgende les")
// als Planning ("Mijn lessen -> Komende lessen"). Dekt precies de
// grensgevallen die de opdracht vereist: vandaag, morgen, weekgrens,
// maandgrens, Nederlandse tijdzone/DST, en meerdere lessen op dezelfde dag.

import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/komende_les_filter.dart';

void main() {
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

  group('isKomendeLes -- vandaag: root cause "lessen later op dezelfde dag"',
      () {
    test('les vandaag met starttijd nog niet gepasseerd is komend', () {
      // Het is 14:00, de les is om 15:00 -- moet nog als komend gelden.
      final nu = DateTime(2026, 8, 20, 14, 0);
      expect(
        isKomendeLes(datum: '2026-08-20', starttijd: '15:00:00', nu: nu),
        isTrue,
      );
    });

    test(
        'les vandaag met starttijd al gepasseerd is NIET meer komend '
        '(de oorspronkelijke bug)', () {
      // Het is 14:00, een eerdere les vandaag was om 09:00 -- die telt niet
      // meer mee als "volgende les", ook al staat status nog op gepland.
      final nu = DateTime(2026, 8, 20, 14, 0);
      expect(
        isKomendeLes(datum: '2026-08-20', starttijd: '09:00:00', nu: nu),
        isFalse,
      );
    });

    test('les die exact nu begint telt nog als komend (grens inclusief)',
        () {
      final nu = DateTime(2026, 8, 20, 15, 0, 0);
      expect(
        isKomendeLes(datum: '2026-08-20', starttijd: '15:00:00', nu: nu),
        isTrue,
      );
    });

    test(
        'twee lessen vandaag: vroege les is voorbij, latere les vandaag '
        'wordt terecht als komend gezien (kernscenario)', () {
      final nu = DateTime(2026, 8, 20, 12, 0);
      final vroegeLesVoorbij =
          isKomendeLes(datum: '2026-08-20', starttijd: '09:00:00', nu: nu);
      final lateLesVandaag =
          isKomendeLes(datum: '2026-08-20', starttijd: '17:00:00', nu: nu);
      expect(vroegeLesVoorbij, isFalse);
      expect(lateLesVandaag, isTrue);
    });
  });

  group('isKomendeLes -- week-/maandgrens', () {
    test('weekgrens: zondag 23:50 -> les maandag 00:30 is komend', () {
      // 2026-08-16 is een zondag.
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

  group('isKomendeLes -- Nederlandse tijdzone / DST-overgang', () {
    test(
        'DST-overgang (laatste zondag van oktober): datumvergelijking blijft '
        'zuiver lexicografisch, geen uur-verschuiving door de klokomzetting',
        () {
      // 2026-10-25 is de laatste zondag van oktober (wintertijd-overgang in
      // NL). Puur String-vergelijking op "YYYY-MM-DD"/"HH:MM:SS" is per
      // definitie ongevoelig voor DST -- geen DateTime-aftrekking nodig.
      final nu = DateTime(2026, 10, 25, 23, 30);
      expect(
        isKomendeLes(datum: '2026-10-26', starttijd: '01:00:00', nu: nu),
        isTrue,
      );
      expect(
        isKomendeLes(datum: '2026-10-25', starttijd: '23:00:00', nu: nu),
        isFalse,
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
    test('bouwt de verwachte .or()-filterstring', () {
      final nu = DateTime(2026, 8, 20, 14, 30, 0);
      expect(
        komendeLesPostgrestFilter(nu),
        'datum.gt.2026-08-20,and(datum.eq.2026-08-20,starttijd.gte.14:30:00)',
      );
    });
  });
}
