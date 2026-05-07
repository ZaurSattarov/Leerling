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
    final afgerondUitLessen =
        lessen.where((les) => les.status == LesStatus.afgerond).length;
    final gebruiktFallback =
        lessen.isEmpty && afgerondUitLessen == 0 && profiel.lessenGevolgd > 0;
    final afgerond =
        gebruiktFallback ? profiel.lessenGevolgd : afgerondUitLessen;
    final gepland = lessen.where((les) {
      return les.status == LesStatus.gepland &&
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
      gebruiktFallback: gebruiktFallback,
    );
  }
}
