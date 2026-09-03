import '../../models/les.dart';

/// Zichtbare status van de Live Aankomst-banner op de Lesdetailspagina
/// (2026-09-03). Puur een weergavestatus -- zegt niets over autorisatie:
/// [ArrivalSettingsInfo.eligible] (server) en de bestaande RLS op
/// arrival_sessions blijven de enige autoriteit over wat daadwerkelijk
/// getoond/opgehaald wordt.
enum LiveAankomstBannerStatus {
  /// Vóór het venster: nog te vroeg, toont "wordt zichtbaar vanaf HH:MM".
  voorVenster,

  /// Venster is open, maar de instructeur is (nog) niet gestart.
  vensterOpenNietGestart,

  /// Er is een daadwerkelijk actieve arrival_session voor deze les.
  actief,
}

/// Bepaalt of, en welke, Live Aankomst-banner getoond moet worden.
///
/// Bewust een pure functie (geen widget/Riverpod-afhankelijkheid) -- zelfde
/// stijl als `checkArrivalEligibility` in de Instructeur-app
/// (arrival_eligibility.dart): makkelijk te unit-testen, één plek voor de
/// tijdsberekening.
///
/// Geeft `null` terug wanneer er GEEN banner getoond mag worden:
/// - les niet (meer) `gepland`, niet eligible (server: instellingen uit /
///   lestype niet toegestaan / geen toegang), of geen geldig lesmoment;
/// - het lesmoment is al gepasseerd EN er is geen actieve sessie (dan is er
///   niets zinnigs meer te communiceren -- `fn_arrival_start` staat sowieso
///   geen start meer toe na lesstart).
///
/// [lesStartMoment] is het reeds gecombineerde datum+starttijd-moment van de
/// les, in dezelfde (device-lokale) tijdzone-conventie als de rest van de
/// app (zie [leesLesStartMoment]) -- GEEN aparte timezone-hack hier.
LiveAankomstBannerStatus? bepaalLiveAankomstBannerStatus({
  required LesStatus lesStatus,
  required bool eligible,
  required int? visibleFromMinutes,
  required DateTime? lesStartMoment,
  required bool sessieActief,
  DateTime? nu,
}) {
  if (sessieActief) return LiveAankomstBannerStatus.actief;

  if (lesStatus != LesStatus.gepland) return null;
  if (!eligible || visibleFromMinutes == null) return null;
  if (lesStartMoment == null) return null;

  final huidigeTijd = nu ?? DateTime.now();
  if (!huidigeTijd.isBefore(lesStartMoment)) return null;

  final vensterOpentOp =
      lesStartMoment.subtract(Duration(minutes: visibleFromMinutes));
  if (huidigeTijd.isBefore(vensterOpentOp)) {
    return LiveAankomstBannerStatus.voorVenster;
  }
  return LiveAankomstBannerStatus.vensterOpenNietGestart;
}

/// Combineert `les.datum` ("yyyy-MM-dd") en `les.starttijd` ("HH:mm") tot één
/// lokale [DateTime] -- zelfde conventie als de rest van de app (bv.
/// `DatumUtils`, die ook overal `DateTime.parse` op device-lokale tijd
/// gebruikt zonder aparte tijdzone-conversie). Geeft `null` bij een
/// onverwachte/lege waarde i.p.v. te crashen.
DateTime? leesLesStartMoment(Les les) {
  if (les.datum.isEmpty || les.starttijd.isEmpty) return null;
  final datumDeel = DateTime.tryParse(les.datum);
  if (datumDeel == null) return null;
  final tijdDelen = les.starttijd.split(':');
  if (tijdDelen.length < 2) return null;
  final uur = int.tryParse(tijdDelen[0]);
  final minuut = int.tryParse(tijdDelen[1]);
  if (uur == null || minuut == null) return null;
  return DateTime(datumDeel.year, datumDeel.month, datumDeel.day, uur, minuut);
}
