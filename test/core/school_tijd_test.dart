import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/school_tijd.dart';

void main() {
  test('winter (CET) en zomer (CEST) offsets', () {
    expect(schoolTijd(DateTime.utc(2026, 1, 15, 12)).hour, 13);
    expect(schoolTijd(DateTime.utc(2026, 7, 15, 12)).hour, 14);
  });

  test('wisseldagen 2026: zomertijd 29 maart, wintertijd 25 oktober', () {
    expect(schoolTijd(DateTime.utc(2026, 3, 29, 0, 59)).hour, 1);
    expect(schoolTijd(DateTime.utc(2026, 3, 29, 1, 0)).hour, 3);
    expect(schoolTijd(DateTime.utc(2026, 10, 25, 0, 59)).hour, 2);
    expect(schoolTijd(DateTime.utc(2026, 10, 25, 1, 0)).hour, 2);
    expect(schoolTijd(DateTime.utc(2026, 10, 25, 2, 0)).hour, 3);
  });

  test('LA-30: dezelfde dag-indeling ongeacht de toesteltijdzone', () {
    // 26 okt 2026 11:15 CET = 10:15 UTC; nu = 26 okt 19:19 CET = 18:19 UTC.
    final melding = DateTime.utc(2026, 10, 26, 10, 15);
    final nu = DateTime.utc(2026, 10, 26, 18, 19);
    // Zelfde absolute momenten, uitgedrukt als lokale toestelmomenten in een
    // andere zone, geven dezelfde schooldag (de omrekening gaat via UTC).
    expect(dagenGeledenSchool(melding, nu: nu), 0);
    expect(dagenGeledenSchool(DateTime.utc(2026, 10, 25, 21, 0), nu: nu), 1);
    expect(dagenGeledenSchool(DateTime.utc(2026, 10, 25, 23, 30), nu: nu), 0,
        reason: '00:30 CET op 26 okt is nog vandaag');
  });

  test('tijdstempellabel in schooltijd', () {
    final nu = DateTime.utc(2026, 10, 26, 18, 19);
    expect(schoolTijdstempelLabel(DateTime.utc(2026, 10, 26, 9, 50), nu: nu),
        'vandaag 10:50');
    expect(schoolTijdstempelLabel(DateTime.utc(2026, 10, 25, 20, 5), nu: nu),
        'gisteren 21:05');
    expect(schoolTijdstempelLabel(DateTime.utc(2026, 10, 22, 12, 0), nu: nu),
        'do 22 okt 14:00');
  });
}
