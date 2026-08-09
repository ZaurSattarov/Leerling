// Eén centrale, zuivere bron voor "is deze les nog komend?" -- gebruikt
// door StudentService.getMijnKomendeLessen (en dus zowel Home als Planning,
// die beide diezelfde methode als bron gebruiken, zie student_service.dart).
//
// Root cause van de eerder gemelde "verkeerde datum bij de volgende les":
// de query filterde alleen op `datum >= vandaag`, zonder de starttijd van
// vandaag te toetsen. Bij meerdere lessen op dezelfde dag (of een les die
// vandaag al begonnen is maar nog niet als "afgerond" is gemarkeerd) won
// altijd de VROEGSTE starttijd van vandaag, ook als die al gepasseerd was.
//
// `datum`/`starttijd` komen als "YYYY-MM-DD"/"HH:MM:SS" (Postgres
// `date`/`time without time zone`, geen tijdzone-info) uit Supabase -- zie
// live schema-check tijdens onderzoek. Zowel hier als in de PostgREST-
// filter wordt zuiver lexicografisch (String-)vergeleken; dat is voor deze
// al zero-padded, vaste-breedte representaties equivalent aan chronologisch
// vergelijken, precies zoals Postgres `date`/`time`-kolommen onderling
// vergelijkt. Geen DateTime-rekenkunde nodig en dus geen DST-gevoeligheid.

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

/// True wanneer een les met [datum] ("YYYY-MM-DD") en [starttijd] ("HH:MM"
/// of "HH:MM:SS") nog "komend" is t.o.v. [nu]: op een latere datum, of
/// vandaag met een starttijd die nog niet is gepasseerd.
bool isKomendeLes({
  required String datum,
  required String starttijd,
  required DateTime nu,
}) {
  final vandaag = vandaagString(nu);
  final vergelijking = datum.compareTo(vandaag);
  if (vergelijking > 0) return true;
  if (vergelijking < 0) return false;
  return starttijd.compareTo(nuTijdString(nu)) >= 0;
}

/// Bouwt de PostgREST `.or(...)`-filterstring die dezelfde logica als
/// [isKomendeLes] server-side afdwingt: `datum > vandaag` OF (`datum ==
/// vandaag` EN `starttijd >= nu`).
String komendeLesPostgrestFilter(DateTime nu) {
  final vandaag = vandaagString(nu);
  final tijd = nuTijdString(nu);
  return 'datum.gt.$vandaag,and(datum.eq.$vandaag,starttijd.gte.$tijd)';
}
