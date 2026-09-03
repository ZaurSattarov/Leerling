enum ExamenadviesStatus {
  onvoldoendeData,
  nogNietKlaar,
  nogOefenen,
  bijnaKlaar,
  klaarVoorExamen,
}

enum VaardigheidTrend { stijgt, stabiel, daalt, onbekend }

class ExamenadviesRules {
  ExamenadviesRules._();

/// UI-schaal 1–5. Canonical drempels/score staan in Postgres
/// `klantio_bereken_examenadvies`, niet in deze class.

  /// Minimaal aantal categorieën met echte scores.
  static const int minCategorieenVoorAdvies = 3;

  /// Recente lessen wegen zwaarder; ouder dan dit venster telt niet mee
  /// voor het huidige niveau (wel voor trend).
  static const int recencyVenster = 5;

/// Drempels en scoring staan in Postgres `klantio_bereken_examenadvies`.
/// Dit bestand is alleen DTO/UI.
  static const int drempelKlaarVoorExamen = 80;
  static const int drempelBijnaKlaar = 65;
  static const int drempelNogOefenen = 40;

  /// 1–5 schaal, gelijk aan [EvolutieService] in de Instructeur-app.
  static const int zwakkeScoreOpVijf = 2;
  static const double minGemiddeldeOpVijfVoorKlaar = 4.0;
  static const double trendDrempelOpVijf = 0.4;

  static const int maxScoreOpVijf = 5;
}

class ExamenVaardigheidCategorie {
  final String naam;
  final List<String> skillKeys;

  const ExamenVaardigheidCategorie({
    required this.naam,
    required this.skillKeys,
  });
}

/// De zes canonieke categorieën uit `vaardighedenCategorieen`, plus de
/// skill-keys die de Instructeur-app per les opslaat in `lesson_skill_scores`.
const List<ExamenVaardigheidCategorie> examenVaardigheidCategorieen = [
  ExamenVaardigheidCategorie(
    naam: 'Voertuigbeheersing',
    skillKeys: [
      'voertuigbeheersing',
      'stuurcontrole',
      'gas_rem_koppeling',
      'schakelen',
      'optrekken_remmen',
      'voertuig_controle',
    ],
  ),
  ExamenVaardigheidCategorie(
    naam: 'Observatie',
    skillKeys: [
      'observatie',
      'kijkgedrag',
      'spiegelen',
      'spiegelgebruik',
      'dode_hoek',
      'reactie_omgeving',
      'omgeving_reactie',
      'volgafstand',
      'signalen',
      'signalen_lezen',
    ],
  ),
  ExamenVaardigheidCategorie(
    naam: 'Manoeuvres',
    skillKeys: [
      'manoeuvres',
      'parkeren',
      'invoegen',
      'keren',
      'achteruit_inparkeren',
      'parallel_parkeren',
      'invoegen_uitvoegen',
      'bochten',
      'bochten_nemen',
    ],
  ),
  ExamenVaardigheidCategorie(
    naam: 'Verkeer',
    skillKeys: [
      'verkeer',
      'rotondes',
      'voorrang',
      'voorrang_verlenen',
      'kruispunten',
      'bebording',
      'rijstroken',
    ],
  ),
  ExamenVaardigheidCategorie(
    naam: 'Wegpositie',
    skillKeys: [
      'wegpositie',
      'rijbaan_positie',
      'snelheidsaanpassing',
      'inhalen',
      'rechts_houden',
      'zijdelingse_afstand',
    ],
  ),
  ExamenVaardigheidCategorie(
    naam: 'Gedrag',
    skillKeys: [
      'gedrag',
      'zelfstandig_rijden',
      'stressbeheersing',
      'anticiperen',
      'richtingaanwijzer',
      'algehele_ervaring',
      'algehele_rijervaring',
    ],
  ),
];

class LesVaardigheidBeoordeling {
  final String leerlingId;
  final String? lesId;
  final String? evaluatieId;
  final String? instructeurId;
  final DateTime datum;
  final Map<String, int> scores;
  final String? rating;
  final String? ingrepenCount;

  const LesVaardigheidBeoordeling({
    required this.leerlingId,
    required this.datum,
    required this.scores,
    this.lesId,
    this.evaluatieId,
    this.instructeurId,
    this.rating,
    this.ingrepenCount,
  });
}

class CategorieScore {
  final String naam;
  final double? huidigOpVijf;
  final VaardigheidTrend trend;
  final bool terugkerendProbleem;

  /// Canonical lespunten (max. 6), zelfde reeks als SQL-trend. Geen 0-vulling.
  final List<double> geschiedenis;

  const CategorieScore({
    required this.naam,
    required this.huidigOpVijf,
    required this.trend,
    this.terugkerendProbleem = false,
    this.geschiedenis = const [],
  });

  int? get scoreAfgerond =>
      huidigOpVijf == null ? null : huidigOpVijf!.round().clamp(1, 5);

  /// Canonical weergave: 1 decimaal uit Postgres, geen herberekening.
  String? get scoreLabel =>
      huidigOpVijf == null ? null : huidigOpVijf!.toStringAsFixed(1);

  bool get heeftData => huidigOpVijf != null;
}

class ExamenadviesData {
  final ExamenadviesStatus status;
  final int? score;
  final bool heeftBetrouwbareScore;
  final String uitleg;
  final List<String> sterkePunten;
  final List<String> nogOefenen;
  final String ontwikkeling;
  final String volgendeStap;
  final String? instructeurFeedback;
  final List<CategorieScore> categorieen;
  final int aantalBeoordelingen;
  final String resterendeLessen;
  final List<String> gebaseerdOp;

  const ExamenadviesData({
    required this.status,
    required this.score,
    required this.heeftBetrouwbareScore,
    required this.uitleg,
    required this.sterkePunten,
    required this.nogOefenen,
    required this.ontwikkeling,
    required this.volgendeStap,
    required this.categorieen,
    required this.aantalBeoordelingen,
    required this.resterendeLessen,
    required this.gebaseerdOp,
    this.instructeurFeedback,
  });

  String get statusLabel => switch (status) {
        ExamenadviesStatus.klaarVoorExamen => 'Klaar voor examen',
        ExamenadviesStatus.bijnaKlaar => 'Bijna klaar',
        ExamenadviesStatus.nogOefenen => 'Nog oefenen',
        ExamenadviesStatus.nogNietKlaar => 'Nog niet klaar',
        ExamenadviesStatus.onvoldoendeData => 'Nog onvoldoende data',
      };

  /// Alleen de canonical RPC-payload. `leerlingen.vaardigheden` hoort
  /// hier niet bij — dat is het interne instructeursdossier.
  static ExamenadviesData fromRpc(dynamic raw) {
    if (raw is! Map) return emptyExamenadvies;
    final json = Map<String, dynamic>.from(raw);
    return ExamenadviesData(
      status: _statusFromRpc(json['status']),
      score: json['score'] is num ? (json['score'] as num).toInt() : null,
      heeftBetrouwbareScore: json['heeftBetrouwbareScore'] == true,
      uitleg: (json['uitleg'] as String?) ?? emptyExamenadvies.uitleg,
      sterkePunten: _stringList(json['sterkePunten']),
      nogOefenen: _stringList(json['nogOefenen']),
      ontwikkeling: (json['ontwikkeling'] as String?) ?? '',
      volgendeStap:
          (json['volgendeStap'] as String?) ?? emptyExamenadvies.volgendeStap,
      instructeurFeedback: json['instructeurFeedback'] as String?,
      categorieen: _categorieen(json['categorieen']),
      aantalBeoordelingen: json['aantalBeoordelingen'] is num
          ? (json['aantalBeoordelingen'] as num).toInt()
          : 0,
      resterendeLessen: (json['resterendeLessen'] as String?) ??
          emptyExamenadvies.resterendeLessen,
      gebaseerdOp: _stringList(json['gebaseerdOp']),
    );
  }
}

ExamenadviesStatus _statusFromRpc(Object? raw) {
  return switch (raw) {
    'klaarVoorExamen' => ExamenadviesStatus.klaarVoorExamen,
    'bijnaKlaar' => ExamenadviesStatus.bijnaKlaar,
    'nogOefenen' => ExamenadviesStatus.nogOefenen,
    'nogNietKlaar' => ExamenadviesStatus.nogNietKlaar,
    _ => ExamenadviesStatus.onvoldoendeData,
  };
}

List<double> _geschiedenis(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<num>()
      .map((n) => n.toDouble())
      .where((n) => n >= 1 && n <= 5)
      .toList();
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<String>().toList();
}

List<CategorieScore> _categorieen(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((item) {
    final json = Map<String, dynamic>.from(item);
    final trendRaw = json['trend'] as String?;
    return CategorieScore(
      naam: (json['naam'] as String?) ?? '',
      huidigOpVijf:
          json['huidigOpVijf'] is num ? (json['huidigOpVijf'] as num).toDouble() : null,
      trend: switch (trendRaw) {
        'stijgt' => VaardigheidTrend.stijgt,
        'daalt' => VaardigheidTrend.daalt,
        'stabiel' => VaardigheidTrend.stabiel,
        _ => VaardigheidTrend.onbekend,
      },
      terugkerendProbleem: json['terugkerendProbleem'] == true,
      geschiedenis: _geschiedenis(json['geschiedenis']),
    );
  }).toList();
}

const emptyExamenadvies = ExamenadviesData(
  status: ExamenadviesStatus.onvoldoendeData,
  score: null,
  heeftBetrouwbareScore: false,
  uitleg:
      'Er zijn nog te weinig vaardigheidsbeoordelingen van je instructeur om een betrouwbaar examenadvies te geven.',
  sterkePunten: [],
  nogOefenen: [],
  ontwikkeling: '',
  volgendeStap:
      'Volg lessen zodat je instructeur je vaardigheden kan beoordelen.',
  categorieen: [],
  aantalBeoordelingen: 0,
  resterendeLessen: 'Volg eerst meer lessen voor een advies',
  gebaseerdOp: [],
);
