/// Eén rij uit `instructor_lesson_packages` (de door de instructeur beheerde
/// pakkettencatalogus). Gebruikt UITSLUITEND als legacy-leesfallback voor
/// leerlingen die nog geen volledige pakket-snapshot hebben op hun eigen
/// profiel (`LeerlingProfiel.heeftPakketSnapshot == false`) -- zodra die
/// snapshot bestaat, wordt dit model niet meer geraadpleegd. Zie
/// docs/PROFIEL_ARCHITECTUUR.md en StudentService.getMijnPakketCatalogusItem.
class InstructorLessonPackage {
  final String id;
  final String naam;
  final String categorie;
  final String transmissie;
  final String saldoEenheid;
  final int? aantalLessen;
  final int? pakketMinutenTotaal;
  final int lesduurMinuten;
  final double pakketprijs;
  final double losseLesprijs;
  final bool praktijkexamenInbegrepen;
  final bool tussentijdseToetsInbegrepen;
  final bool actief;

  const InstructorLessonPackage({
    required this.id,
    required this.naam,
    required this.categorie,
    required this.transmissie,
    required this.saldoEenheid,
    this.aantalLessen,
    this.pakketMinutenTotaal,
    required this.lesduurMinuten,
    required this.pakketprijs,
    required this.losseLesprijs,
    required this.praktijkexamenInbegrepen,
    required this.tussentijdseToetsInbegrepen,
    required this.actief,
  });

  bool get gebruiktMinutenSaldo => saldoEenheid == 'minuten';

  factory InstructorLessonPackage.fromJson(Map<String, dynamic> json) {
    return InstructorLessonPackage(
      id: (json['id'] as String?) ?? '',
      naam: (json['naam'] as String?) ?? '',
      categorie: (json['categorie'] as String?) ?? 'B',
      transmissie: (json['transmissie'] as String?) ?? 'none',
      saldoEenheid: (json['saldo_eenheid'] as String?) ?? 'lessen',
      aantalLessen: (json['aantal_lessen'] as num?)?.toInt(),
      pakketMinutenTotaal: (json['pakket_minuten_totaal'] as num?)?.toInt(),
      lesduurMinuten: (json['lesduur_minuten'] as num? ?? 60).toInt(),
      pakketprijs: (json['pakketprijs'] as num? ?? 0).toDouble(),
      losseLesprijs: (json['losse_lesprijs'] as num? ?? 0).toDouble(),
      praktijkexamenInbegrepen:
          json['praktijkexamen_inbegrepen'] as bool? ?? false,
      tussentijdseToetsInbegrepen:
          json['tussentijdse_toets_inbegrepen'] as bool? ?? false,
      actief: json['actief'] as bool? ?? true,
    );
  }
}
