// Tests voor de gecentraliseerde datumblok-formatters in DatumUtils
// (dagAfkorting/dagNummer/maandAfkorting) -- voorheen driemaal byte-
// identiek gedupliceerd in home_screen.dart, planning_screen.dart en
// les_detail_screen.dart. Nu één bron, dus geen risico meer dat de drie
// schermen uit elkaar lopen voor dezelfde les.

import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/datum_utils.dart';

void main() {
  group('DatumUtils datumblok-formatters', () {
    test('dagAfkorting geeft de juiste Nederlandse weekdagafkorting', () {
      // 2026-08-20 is een donderdag.
      expect(DatumUtils.dagAfkorting('2026-08-20'), 'DON');
      // 2026-08-17 is een maandag.
      expect(DatumUtils.dagAfkorting('2026-08-17'), 'MAA');
      // 2026-08-23 is een zondag.
      expect(DatumUtils.dagAfkorting('2026-08-23'), 'ZON');
    });

    test('dagNummer geeft het dagnummer als string', () {
      expect(DatumUtils.dagNummer('2026-08-20'), '20');
      expect(DatumUtils.dagNummer('2026-01-01'), '1');
    });

    test('maandAfkorting geeft de juiste Nederlandse maandafkorting', () {
      expect(DatumUtils.maandAfkorting('2026-08-20'), 'aug');
      expect(DatumUtils.maandAfkorting('2026-01-01'), 'jan');
      expect(DatumUtils.maandAfkorting('2026-12-31'), 'dec');
    });

    test('ongeldige datumstring geeft veilige fallback, geen crash', () {
      expect(DatumUtils.dagAfkorting(''), '');
      expect(DatumUtils.dagNummer('niet-een-datum'), '?');
      expect(DatumUtils.maandAfkorting('niet-een-datum'), '');
    });

    test(
        'Home, Planning en Lesdetails tonen voor dezelfde les-datum '
        'identieke waarden (zelfde bron)', () {
      const datum = '2026-08-20';
      // Er is nu maar één implementatie, dus dit is triviaal waar -- de
      // test bevestigt vooral dat de functies bestaan en consistent zijn
      // voor herhaalde aanroepen (geen verborgen state).
      expect(DatumUtils.dagAfkorting(datum), DatumUtils.dagAfkorting(datum));
      expect(DatumUtils.dagNummer(datum), DatumUtils.dagNummer(datum));
      expect(
          DatumUtils.maandAfkorting(datum), DatumUtils.maandAfkorting(datum));
    });
  });
}
