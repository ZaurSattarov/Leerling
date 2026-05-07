import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../core/utils/datum_utils.dart';
import '../../core/utils/lespakket_voortgang.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import '../../shared/providers/auth_provider.dart';

final lespakketVoortgangProvider =
    FutureProvider.autoDispose<LespakketVoortgangData?>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return null;
  final lessen = await StudentService.getMijnLessenVoorPakket(profiel.id);
  return LespakketVoortgangData.fromProfielEnLessen(
    profiel: profiel,
    lessen: lessen,
  );
});

class LespakketVoortgangData {
  final LeerlingProfiel profiel;
  final List<Les> lessen;
  final int totaalLessen;
  final int afgerondeLessen;
  final int geplandeLessen;
  final int nogTeGebruiken;
  final int nogInTePlannen;
  final double percentageAfgerond;
  final bool gebruiktFallback;

  const LespakketVoortgangData({
    required this.profiel,
    required this.lessen,
    required this.totaalLessen,
    required this.afgerondeLessen,
    required this.geplandeLessen,
    required this.nogTeGebruiken,
    required this.nogInTePlannen,
    required this.percentageAfgerond,
    required this.gebruiktFallback,
  });

  String get pakketLabel => totaalLessen > 0
      ? '${profiel.pakket.label} $totaalLessen lessen'
      : 'Geen pakket ingesteld';

  bool get heeftPakket => totaalLessen > 0;

  bool get heeftExtraLessen => heeftPakket && afgerondeLessen > totaalLessen;

  int get extraLessen => heeftExtraLessen ? afgerondeLessen - totaalLessen : 0;

  int get percentageLabel => (percentageAfgerond * 100).round();

  List<Les> get tijdlijnLessen {
    final vandaag = DatumUtils.vandaagString();
    return lessen.where((les) {
      if (les.status == LesStatus.afgerond) {
        return true;
      }
      if (les.status == LesStatus.gepland) {
        return les.datum.compareTo(vandaag) >= 0;
      }
      return les.status == LesStatus.geannuleerd ||
          les.status == LesStatus.verzet ||
          les.status == LesStatus.geen_toon;
    }).toList()
      ..sort((a, b) {
        final datum = b.datum.compareTo(a.datum);
        if (datum != 0) return datum;
        return b.starttijd.compareTo(a.starttijd);
      });
  }

  factory LespakketVoortgangData.fromProfielEnLessen({
    required LeerlingProfiel profiel,
    required List<Les> lessen,
  }) {
    final berekening = LespakketVoortgang.fromProfiel(
      profiel: profiel,
      lessen: lessen,
    );

    return LespakketVoortgangData(
      profiel: profiel,
      lessen: lessen,
      totaalLessen: berekening.totaalLessen,
      afgerondeLessen: berekening.afgerondeLessen,
      geplandeLessen: berekening.geplandeLessen,
      nogTeGebruiken: berekening.resterendeLessen,
      nogInTePlannen: berekening.nogInTePlannen,
      percentageAfgerond: berekening.percentageAfgerond,
      gebruiktFallback: berekening.gebruiktFallback,
    );
  }
}
