import '../../models/instructor_lesson_package.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';

/// Volledig, correct-gebronde beeld van het aan een leerling toegewezen
/// lespakket voor Profiel -> Rijopleiding -> Lespakket (Fase 4).
///
/// Bronregel (1-op-1 het patroon uit de Instructeur-app,
/// leerling_detail_screen.dart, daar zelf "Fase F" genoemd):
///   waarde = heeftSnapshot ? snapshotveld op profiel : catalogusFallback-veld,
///   met "niet beschikbaar" als geen van beide een waarde heeft.
/// Zodra een leerling een snapshot heeft, wordt de catalogus NOOIT meer
/// geraadpleegd voor prijs/duur/examens -- een latere catalogusprijswijziging
/// mag een al toegewezen pakket niet met terugwerkende kracht veranderen.
///
/// Bewust een NIEUWE, aparte klasse i.p.v. [LespakketVoortgang] uit te
/// breiden: die klasse (en `LespakketVoortgangData`) wordt ook gebruikt door
/// het bestaande Voortgang-tabblad, dat in deze fase nog niet mag wijzigen.
/// Dit voorkomt dat een aanpassing hier per ongeluk het gedrag van dat
/// tabblad meeverandert.
class LespakketDetail {
  final bool heeftPakket;
  final bool heeftGegevens;
  final bool heeftSnapshot;
  final bool catalogusPakketOntbreekt;

  final String pakketnaam;
  final String? rijbewijsCategorie;
  final String? transmissie;
  final String saldoEenheid;

  final int lesduurMinuten;
  final double? pakketprijs;
  final double? losseLesprijs;
  final bool praktijkexamenInbegrepen;
  final bool tussentijdseToetsInbegrepen;
  final String? startdatum;

  // Lessen-modus.
  final int totaalLessen;
  final int gevolgdeLessen;
  final int resterendeLessen;

  // Minuten-modus.
  final int totaalMinuten;
  final int verbruikteMinuten;
  final int resterendeMinuten;

  const LespakketDetail({
    required this.heeftPakket,
    required this.heeftGegevens,
    required this.heeftSnapshot,
    required this.catalogusPakketOntbreekt,
    required this.pakketnaam,
    this.rijbewijsCategorie,
    this.transmissie,
    required this.saldoEenheid,
    required this.lesduurMinuten,
    this.pakketprijs,
    this.losseLesprijs,
    required this.praktijkexamenInbegrepen,
    required this.tussentijdseToetsInbegrepen,
    this.startdatum,
    required this.totaalLessen,
    required this.gevolgdeLessen,
    required this.resterendeLessen,
    required this.totaalMinuten,
    required this.verbruikteMinuten,
    required this.resterendeMinuten,
  });

  bool get gebruiktMinuten => saldoEenheid == 'minuten';

  String get resterendLabel => gebruiktMinuten
      ? formatMinutenSaldo(resterendeMinuten)
      : '$resterendeLessen ${resterendeLessen == 1 ? 'les' : 'lessen'}';

  String get totaalLabel => gebruiktMinuten
      ? formatMinutenSaldo(totaalMinuten)
      : '$totaalLessen ${totaalLessen == 1 ? 'les' : 'lessen'}';

  String get gevolgdLabel => gebruiktMinuten
      ? formatMinutenSaldo(verbruikteMinuten)
      : '$gevolgdeLessen ${gevolgdeLessen == 1 ? 'les' : 'lessen'}';

  double get percentageAfgerond {
    final totaal = gebruiktMinuten ? totaalMinuten : totaalLessen;
    final gevolgd = gebruiktMinuten ? verbruikteMinuten : gevolgdeLessen;
    if (totaal <= 0) return 0.0;
    return (gevolgd / totaal).clamp(0.0, 1.0);
  }

  int get percentageLabel => (percentageAfgerond * 100).round();

  /// Statuslabel -- afgeleid van de resterende hoeveelheid, geen apart
  /// databaseveld (dat bestaat niet).
  String get statusLabel {
    if (!heeftPakket) return 'Geen pakket';
    if (!heeftGegevens) return 'Onbekend';
    final resterend = gebruiktMinuten ? resterendeMinuten : resterendeLessen;
    if (resterend <= 0) return 'Volledig gebruikt';
    final bijnaOp =
        gebruiktMinuten ? resterendeMinuten <= 120 : resterendeLessen <= 2;
    return bijnaOp ? 'Bijna op' : 'Actief';
  }

  String get prijsLabel =>
      pakketprijs != null ? _euroLabel(pakketprijs!) : '';

  static String _euroLabel(double value) {
    final rounded = value.round();
    if ((value - rounded).abs() < 0.01) {
      return '€ ${rounded.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    }
    return '€ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  factory LespakketDetail.resolve({
    required LeerlingProfiel profiel,
    required List<Les> lessen,
    InstructorLessonPackage? catalogusFallback,
  }) {
    final heeftPakketId = profiel.pakketId?.trim().isNotEmpty == true;
    final heeftSnapshot = profiel.heeftPakketSnapshot;

    // Geen enkele koppeling naar een pakket -- legitieme lege staat, geen
    // fout ("Geen pakket toegewezen" i.p.v. "Pakketgegevens niet
    // beschikbaar").
    if (!heeftPakketId) {
      return const LespakketDetail(
        heeftPakket: false,
        heeftGegevens: false,
        heeftSnapshot: false,
        catalogusPakketOntbreekt: false,
        pakketnaam: 'Geen pakket ingesteld',
        saldoEenheid: 'lessen',
        lesduurMinuten: 0,
        praktijkexamenInbegrepen: false,
        tussentijdseToetsInbegrepen: false,
        totaalLessen: 0,
        gevolgdeLessen: 0,
        resterendeLessen: 0,
        totaalMinuten: 0,
        verbruikteMinuten: 0,
        resterendeMinuten: 0,
      );
    }

    // Wél een pakket_id, maar geen snapshot EN geen (meer) vindbare
    // catalogusrij (bv. de instructeur heeft het pakket sindsdien
    // verwijderd) -- expliciete "niet beschikbaar"-staat, geen verzonnen
    // waarden.
    if (!heeftSnapshot && catalogusFallback == null) {
      return const LespakketDetail(
        heeftPakket: true,
        heeftGegevens: false,
        heeftSnapshot: false,
        catalogusPakketOntbreekt: true,
        pakketnaam: 'Pakketgegevens niet beschikbaar',
        saldoEenheid: 'lessen',
        lesduurMinuten: 0,
        praktijkexamenInbegrepen: false,
        tussentijdseToetsInbegrepen: false,
        totaalLessen: 0,
        gevolgdeLessen: 0,
        resterendeLessen: 0,
        totaalMinuten: 0,
        verbruikteMinuten: 0,
        resterendeMinuten: 0,
      );
    }

    final saldoEenheid = heeftSnapshot
        ? profiel.saldoEenheid
        : (catalogusFallback?.saldoEenheid ?? 'lessen');
    final gebruiktMinuten = saldoEenheid == 'minuten';

    final pakketnaam = (heeftSnapshot ? profiel.pakketNaam : null) ??
        catalogusFallback?.naam ??
        'Pakket';
    final transmissie =
        heeftSnapshot ? profiel.transmissie : catalogusFallback?.transmissie;
    final lesduurMinuten = (heeftSnapshot
            ? profiel.pakketLesduurMinuten
            : catalogusFallback?.lesduurMinuten) ??
        0;
    final pakketprijs = heeftSnapshot
        ? (profiel.pakketPrijsCents != null
            ? profiel.pakketPrijsCents! / 100
            : null)
        : catalogusFallback?.pakketprijs;
    final losseLesprijs = heeftSnapshot
        ? (profiel.pakketLosseLesPrijsCents != null
            ? profiel.pakketLosseLesPrijsCents! / 100
            : null)
        : catalogusFallback?.losseLesprijs;
    final praktijkexamenInbegrepen = (heeftSnapshot
            ? profiel.pakketPraktijkexamenInbegrepen
            : catalogusFallback?.praktijkexamenInbegrepen) ??
        false;
    final tussentijdseToetsInbegrepen = (heeftSnapshot
            ? profiel.pakketTussentijdseToetsInbegrepen
            : catalogusFallback?.tussentijdseToetsInbegrepen) ??
        false;

    // ── Lessen-modus: totaal/gevolgd/resterend ──────────────────────────
    // Alleen echte pakketlessen tellen mee (matcht de server-trigger
    // fn_lesson_balance_sync, die lessen_gevolgd ook uitsluitend voor
    // les_type='pakketles' ophoogt) -- voorkomt dat losse lessen of
    // examenritten hier per ongeluk meetellen. "Resterend" telt hier bewust
    // niet ook nog geplande lessen af (zelfde, eenvoudigere definitie als
    // Leerling.pakketLesAantal-gebaseerde weergave in de Instructeur-app).
    final afgerondUitLessen = lessen
        .where((les) =>
            les.status == LesStatus.afgerond && les.lesType == 'Pakketles')
        .length;
    final gebruiktFallback =
        lessen.isEmpty && afgerondUitLessen == 0 && profiel.lessenGevolgd > 0;
    final gevolgdeLessen =
        gebruiktFallback ? profiel.lessenGevolgd : afgerondUitLessen;
    final totaalLessen =
        profiel.lessenTotaal < 0 ? 0 : profiel.lessenTotaal;
    final resterendeLessen = (totaalLessen - gevolgdeLessen).clamp(0, 9999);

    // ── Minuten-modus: pakket_minuten_verbruikt wordt server-side exact
    // bijgehouden (dezelfde trigger) -- geen client-recompute nodig of
    // gewenst.
    final totaalMinuten = (heeftSnapshot
            ? profiel.pakketMinutenTotaal
            : catalogusFallback?.pakketMinutenTotaal) ??
        0;
    final verbruikteMinuten =
        profiel.pakketMinutenVerbruikt < 0 ? 0 : profiel.pakketMinutenVerbruikt;
    final resterendeMinuten =
        (totaalMinuten - verbruikteMinuten).clamp(0, 1 << 30);

    return LespakketDetail(
      heeftPakket: true,
      heeftGegevens: true,
      heeftSnapshot: heeftSnapshot,
      catalogusPakketOntbreekt: false,
      pakketnaam: pakketnaam,
      rijbewijsCategorie: profiel.rijbewijsSoort,
      transmissie: transmissie,
      saldoEenheid: saldoEenheid,
      lesduurMinuten: lesduurMinuten,
      pakketprijs: pakketprijs,
      losseLesprijs: losseLesprijs,
      praktijkexamenInbegrepen: praktijkexamenInbegrepen,
      tussentijdseToetsInbegrepen: tussentijdseToetsInbegrepen,
      startdatum: profiel.startdatum,
      totaalLessen: gebruiktMinuten ? 0 : totaalLessen,
      gevolgdeLessen: gebruiktMinuten ? 0 : gevolgdeLessen,
      resterendeLessen: gebruiktMinuten ? 0 : resterendeLessen,
      totaalMinuten: gebruiktMinuten ? totaalMinuten : 0,
      verbruikteMinuten: gebruiktMinuten ? verbruikteMinuten : 0,
      resterendeMinuten: gebruiktMinuten ? resterendeMinuten : 0,
    );
  }
}

/// Volledig uitgeschreven duur, bv. "17 uur 30 min", "45 min", "2 uur".
/// 1-op-1 dezelfde opmaak als de Instructeur-app gebruikt voor
/// saldo_eenheid = 'minuten'-pakketten.
String formatMinutenSaldo(int minuten) {
  final veilig = minuten < 0 ? 0 : minuten;
  final uren = veilig ~/ 60;
  final rest = veilig % 60;
  if (uren == 0) return '$rest min';
  if (rest == 0) return uren == 1 ? '1 uur' : '$uren uur';
  return '${uren == 1 ? '1 uur' : '$uren uur'} $rest min';
}
