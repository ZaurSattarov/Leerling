// Eén centrale bron voor "komende les" / "volgende les".
// Home ("Volgende les") en Planning ("Mijn lessen") gebruiken dezelfde
// DateTime-logica -- nooit database-volgorde, created_at of .first vóór sort.

import '../../models/les.dart';

/// Vandaag ("YYYY-MM-DD") volgens de lokale klok van het apparaat.
String vandaagString(DateTime nu) {
  return '${nu.year.toString().padLeft(4, '0')}-'
      '${nu.month.toString().padLeft(2, '0')}-'
      '${nu.day.toString().padLeft(2, '0')}';
}

/// Huidige tijd ("HH:MM:SS") volgens de lokale klok van het apparaat.
String nuTijdString(DateTime nu) {
  return '${nu.hour.toString().padLeft(2, '0')}:'
      '${nu.minute.toString().padLeft(2, '0')}:'
      '${nu.second.toString().padLeft(2, '0')}';
}

/// Combineert lesdatum + tijd tot één lokale DateTime.
/// [tijd] mag "HH:MM" of "HH:MM:SS" zijn.
DateTime? combineerLesDateTime(String datum, String tijd) {
  if (datum.isEmpty) return null;
  final dag = DateTime.tryParse(datum);
  if (dag == null) return null;

  final delen = tijd.trim().split(':');
  final uur = delen.isNotEmpty ? int.tryParse(delen[0]) ?? 0 : 0;
  final minuut = delen.length > 1 ? int.tryParse(delen[1]) ?? 0 : 0;
  final seconde = delen.length > 2 ? int.tryParse(delen[2]) ?? 0 : 0;

  return DateTime(dag.year, dag.month, dag.day, uur, minuut, seconde);
}

DateTime? lesStartDateTime(Les les) =>
    combineerLesDateTime(les.datum, les.starttijd);

DateTime? lesEindDateTime(Les les) {
  final einde = les.eindtijd.trim();
  if (einde.isNotEmpty) return combineerLesDateTime(les.datum, einde);
  return lesStartDateTime(les);
}

/// True wanneer de les nog relevant is t.o.v. [nu]:
/// toekomstig, of vandaag nog bezig (eindtijd nog niet verstreken).
bool isKomendeLes({
  required String datum,
  required String starttijd,
  String? eindtijd,
  required DateTime nu,
}) {
  final grensTijd =
      (eindtijd != null && eindtijd.trim().isNotEmpty) ? eindtijd : starttijd;
  final einde = combineerLesDateTime(datum, grensTijd);
  if (einde == null) return false;
  return einde.isAfter(nu);
}

bool isAfgelopenLes(Les les, DateTime nu) {
  final einde = lesEindDateTime(les);
  if (einde == null) return false;
  return !einde.isAfter(nu);
}

int vergelijkOpStart(Les a, Les b) {
  final sa = lesStartDateTime(a);
  final sb = lesStartDateTime(b);
  if (sa == null && sb == null) return 0;
  if (sa == null) return 1;
  if (sb == null) return -1;
  return sa.compareTo(sb);
}

/// Filtert afgelopen lessen eruit en sorteert op startDateTime ASC.
/// Dit is de enige volgorde die Home en Mijn lessen mogen gebruiken.
List<Les> filterEnSorteerKomendeLessen(List<Les> lessen, DateTime nu) {
  final komend = lessen
      .where(
        (les) => isKomendeLes(
          datum: les.datum,
          starttijd: les.starttijd,
          eindtijd: les.eindtijd,
          nu: nu,
        ),
      )
      .toList();
  komend.sort(vergelijkOpStart);
  return komend;
}

/// Eerste les in de chronologische komende-lijst = echte "Volgende les".
Les? selecteerVolgendeLes(List<Les> lessen, DateTime nu) {
  final gesorteerd = filterEnSorteerKomendeLessen(lessen, nu);
  if (gesorteerd.isEmpty) return null;
  return gesorteerd.first;
}

/// Server-side benadering van dezelfde regel: toekomstige dag, of vandaag
/// met eindtijd nog na nu (inclusief lopende les).
String komendeLesPostgrestFilter(DateTime nu) {
  final vandaag = vandaagString(nu);
  final tijd = nuTijdString(nu);
  return 'datum.gt.$vandaag,and(datum.eq.$vandaag,eindtijd.gt.$tijd)';
}
