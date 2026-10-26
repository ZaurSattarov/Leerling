/// Tijdzone van de rijschool (Europe/Amsterdam). Lestijden en dagindelingen
/// ("Vandaag", "Gisteren") volgen de Nederlandse wandklok, ook als het toestel
/// van de leerling op een andere tijdzone staat.
///
/// Zuivere Dart-implementatie van de EU-zomertijdregel (CET = UTC+1,
/// CEST = UTC+2; zomertijd van de laatste zondag van maart 01:00 UTC tot de
/// laatste zondag van oktober 01:00 UTC), zodat er geen extra dependency of
/// tijdzonedatabase nodig is.
const String kRijschoolTijdzone = 'Europe/Amsterdam';

DateTime _laatsteZondagUtc(int jaar, int maand) {
  final laatsteDag = DateTime.utc(jaar, maand + 1, 0, 1);
  return laatsteDag.subtract(Duration(days: laatsteDag.weekday % 7));
}

/// UTC-offset van Nederland op het absolute moment [moment].
Duration schoolOffset(DateTime moment) {
  final utc = moment.toUtc();
  final start = _laatsteZondagUtc(utc.year, 3);
  final einde = _laatsteZondagUtc(utc.year, 10);
  final zomer = !utc.isBefore(start) && utc.isBefore(einde);
  return Duration(hours: zomer ? 2 : 1);
}

/// Wandkloktijd in Nederland voor een absoluut tijdstip. Het resultaat is een
/// "kale" [DateTime] waarvan de velden (jaar, maand, dag, uur, ...) de
/// Nederlandse klok tonen; gebruik het alleen voor weergave en dagindeling.
DateTime schoolTijd(DateTime moment) {
  final utc = moment.toUtc();
  final nl = utc.add(schoolOffset(utc));
  return DateTime(nl.year, nl.month, nl.day, nl.hour, nl.minute, nl.second,
      nl.millisecond);
}

/// De huidige wandkloktijd van de rijschool.
DateTime nuSchool() => schoolTijd(DateTime.now());

/// Vandaag volgens de rijschool-tijdzone, als kale kalenderdatum.
DateTime schoolVandaag([DateTime? moment]) {
  final nu = moment == null ? nuSchool() : schoolTijd(moment);
  return DateTime(nu.year, nu.month, nu.day);
}

/// Aantal kalenderdagen tussen [moment] en vandaag, in schooltijd.
int dagenGeledenSchool(DateTime moment, {DateTime? nu}) {
  final dag = schoolVandaag(moment);
  final vandaag = schoolVandaag(nu);
  return DateTime.utc(vandaag.year, vandaag.month, vandaag.day)
      .difference(DateTime.utc(dag.year, dag.month, dag.day))
      .inDays;
}

/// Weergave van een tijdstempel in schooltijd: "vandaag 10:50", "gisteren
/// 21:05", "ma 26 okt 10:50".
String schoolTijdstempelLabel(DateTime moment, {DateTime? nu}) {
  const dagen = ['ma', 'di', 'wo', 'do', 'vr', 'za', 'zo'];
  const maanden = [
    'jan', 'feb', 'mrt', 'apr', 'mei', 'jun', //
    'jul', 'aug', 'sep', 'okt', 'nov', 'dec',
  ];
  final t = schoolTijd(moment);
  final hhmm = '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
  final geleden = dagenGeledenSchool(moment, nu: nu);
  if (geleden == 0) return 'vandaag $hhmm';
  if (geleden == 1) return 'gisteren $hhmm';
  return '${dagen[t.weekday - 1]} ${t.day} ${maanden[t.month - 1]} $hhmm';
}
