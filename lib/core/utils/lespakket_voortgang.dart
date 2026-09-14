import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import 'datum_utils.dart';

class LespakketVoortgang {
  final String pakketnaam;
  final int totaalLessen;
  final int afgerondeLessen;
  final int geplandeLessen;
  final int resterendeLessen;
  final int nogInTePlannen;
  final double percentageAfgerond;
  final bool gebruiktFallback;

  const LespakketVoortgang({
    required this.pakketnaam,
    required this.totaalLessen,
    required this.afgerondeLessen,
    required this.geplandeLessen,
    required this.resterendeLessen,
    required this.nogInTePlannen,
    required this.percentageAfgerond,
    this.gebruiktFallback = false,
  });

  bool get heeftPakket => totaalLessen > 0;
  int get percentageLabel => (percentageAfgerond * 100).round();
  bool get heeftExtraLessen => heeftPakket && afgerondeLessen > totaalLessen;
  int get extraLessen => heeftExtraLessen ? afgerondeLessen - totaalLessen : 0;
  String get pakketLabel => heeftPakket
      ? '$pakketnaam $totaalLessen lessen'
      : 'Geen pakket ingesteld';

  factory LespakketVoortgang.fromProfiel({
    required LeerlingProfiel profiel,
    required List<Les> lessen,
  }) {
    final vandaag = DatumUtils.vandaagString();
    // Canonical bugfix (2026-09-10): 'afgerond' komt uitsluitend nog uit de
    // server-side bijgehouden leerlingen.lessen_gevolgd-teller -- dezelfde
    // trigger-onderhouden bron als pakket_minuten_verbruikt, en dezelfde
    // teller die de Instructeur-app en Admin Web al gebruiken. Voorheen werd
    // hier een client-side recount van `lessen` gedaan (afkomstig van
    // `student_lessen_view`), met lessen_gevolgd alleen als fallback
    // wanneer die lijst leeg was. Die view toont een afgeronde les alleen
    // wanneer `zichtbaar_voor_leerling = true` (terecht voor content/
    // feedback, maar geen geldig criterium voor pakketcredit-verbruik) --
    // bewezen root cause van een discrepantie waarbij de Leerling-app 15
    // afgerond toonde terwijl 58 pakketlessen daadwerkelijk waren
    // afgeschreven (Instrecteur/Admin/lessen_gevolgd). Geen tweede recount
    // meer: lessen_gevolgd is hier onvoorwaardelijk de bron.
    final afgerond = profiel.lessenGevolgd < 0 ? 0 : profiel.lessenGevolgd;
    // Alleen toekomstige, geplande PAKKETlessen verbruiken pakketcredit --
    // zelfde semantiek als Instrecteur's isGeplandePakketLes() (status
    // gepland + les_type pakketles + datum niet in het verleden). Geplande
    // niet-pakketafspraken (bv. 'rijles') horen hier niet in mee te tellen
    // (bewezen bug: 8 i.p.v. 1 doordat les_type niet gefilterd werd).
    final gepland = lessen.where((les) {
      return les.status == LesStatus.gepland &&
          les.lesType == 'Pakketles' &&
          les.datum.compareTo(vandaag) >= 0;
    }).length;
    final totaal = profiel.lessenTotaal < 0 ? 0 : profiel.lessenTotaal;
    final percentage = totaal <= 0 ? 0.0 : (afgerond / totaal).clamp(0.0, 1.0);

    return LespakketVoortgang(
      pakketnaam: profiel.pakket.label,
      totaalLessen: totaal,
      afgerondeLessen: afgerond,
      geplandeLessen: gepland,
      resterendeLessen: (totaal - afgerond).clamp(0, 9999),
      nogInTePlannen: (totaal - afgerond - gepland).clamp(0, 9999),
      percentageAfgerond: percentage,
      // Altijd false: 'afgerond' is nu onvoorwaardelijk canonical (nooit
      // meer een client-side benadering). Veld blijft bestaan voor de
      // bestaande UI-plumbing (LespakketVoortgangData.gebruiktFallback),
      // maar wordt niet meer op true gezet.
      gebruiktFallback: false,
    );
  }
}
