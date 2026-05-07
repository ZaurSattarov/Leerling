import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import '../voortgang/voortgang_provider.dart';
import 'examenadvies_data.dart';

class ExamenadviesCalculator {
  const ExamenadviesCalculator._();

  static ExamenadviesData bereken({
    required LeerlingProfiel profiel,
    required List<Les> zichtbareAfgerondeLessen,
  }) {
    final vaardigheidPercentages =
        _competentiePercentages(profiel.vaardigheden ?? const {});
    final vaardigheidScore = vaardigheidPercentages.isEmpty
        ? null
        : _average(vaardigheidPercentages.values) * 100;
    final lesProgressScore = profiel.voortgangPercent * 100;
    final beoordelingScore = _beoordelingScore(zichtbareAfgerondeLessen);
    final lesCompetentieScore = _lesCompetentieScore(zichtbareAfgerondeLessen);
    final scoreOnderdelen = _scoreOnderdelen(
      lesProgressScore: lesProgressScore,
      vaardigheidScore: vaardigheidScore,
      lesCompetentieScore: lesCompetentieScore,
      beoordelingScore: beoordelingScore,
    );
    final heeftEchteInput = profiel.lessenGevolgd > 0 ||
        zichtbareAfgerondeLessen.isNotEmpty ||
        vaardigheidScore != null ||
        lesCompetentieScore != null;

    if (!heeftEchteInput) return mockExamenadvies;

    final gewogen = <_WeightedScore>[
      _WeightedScore(lesProgressScore, 0.40),
      if (vaardigheidScore != null) _WeightedScore(vaardigheidScore, 0.30),
      if (lesCompetentieScore != null)
        _WeightedScore(lesCompetentieScore, 0.15),
      if (beoordelingScore != null) _WeightedScore(beoordelingScore, 0.15),
    ];
    final score = _weightedAverage(gewogen).round().clamp(0, 100);
    final status = _statusVoor(score);
    final sterkePunten = _sterkePunten(vaardigheidPercentages,
        zichtbareAfgerondeLessen: zichtbareAfgerondeLessen);
    final nogOefenen = _nogOefenen(vaardigheidPercentages,
        zichtbareAfgerondeLessen: zichtbareAfgerondeLessen);

    return ExamenadviesData(
      score: score,
      status: status,
      uitleg: _uitleg(
        score: score,
        lesProgressScore: lesProgressScore,
        vaardigheidScore: vaardigheidScore,
        beoordelingScore: beoordelingScore,
      ),
      sterkePunten: sterkePunten.isEmpty
          ? mockExamenadvies.sterkePunten
          : sterkePunten.take(4).toList(),
      nogOefenen: nogOefenen.isEmpty
          ? mockExamenadvies.nogOefenen
          : nogOefenen.take(4).toList(),
      resterendeLessen: _resterendeLessen(score, profiel),
      gebaseerdOp: [
        'Gevolgde lessen',
        if (vaardigheidScore != null) 'Vaardigheidsscores',
        if (zichtbareAfgerondeLessen.isNotEmpty) 'Instructeur feedback',
        if (lesCompetentieScore != null) 'Competentie scores',
        if (beoordelingScore != null) 'Beoordelingen',
      ],
      scoreOnderdelen: scoreOnderdelen,
    );
  }

  static List<ScoreOnderdeel> _scoreOnderdelen({
    required double lesProgressScore,
    required double? vaardigheidScore,
    required double? lesCompetentieScore,
    required double? beoordelingScore,
  }) {
    return [
      ScoreOnderdeel(
        naam: 'Gevolgde lessen',
        score: lesProgressScore,
        gewicht: 0.40,
        teltMee: true,
        scoreLabel: '${lesProgressScore.round()}% voortgang',
        uitleg: 'Aantal gevolgde lessen ten opzichte van je lespakket.',
      ),
      ScoreOnderdeel(
        naam: 'Vaardigheidsscores',
        score: vaardigheidScore,
        gewicht: 0.30,
        teltMee: vaardigheidScore != null,
        scoreLabel: vaardigheidScore == null
            ? 'Nog onvoldoende data'
            : '${vaardigheidScore.round()}% gemiddeld',
        uitleg: vaardigheidScore == null
            ? 'Nog geen of te weinig vaardigheidsscores. Beschikbare onderdelen tellen tijdelijk zwaarder mee.'
            : 'Gemiddelde van beoordeelde CBR-achtige vaardigheden.',
      ),
      ScoreOnderdeel(
        naam: 'Competenties per les',
        score: lesCompetentieScore,
        gewicht: 0.15,
        teltMee: lesCompetentieScore != null,
        scoreLabel: lesCompetentieScore == null
            ? 'Nog onvoldoende data'
            : '${lesCompetentieScore.round()}% gemiddeld',
        uitleg: lesCompetentieScore == null
            ? 'Nog geen competentiescores per les. Beschikbare onderdelen tellen tijdelijk zwaarder mee.'
            : 'Gemiddelde van competentiescores uit zichtbare afgeronde lessen.',
      ),
      ScoreOnderdeel(
        naam: 'Beoordelingen',
        score: beoordelingScore,
        gewicht: 0.15,
        teltMee: beoordelingScore != null,
        scoreLabel: beoordelingScore == null
            ? 'Nog onvoldoende data'
            : '${beoordelingScore.round()}% gemiddeld',
        uitleg: beoordelingScore == null
            ? 'Nog geen beoordelingen van zichtbare afgeronde lessen. Beschikbare onderdelen tellen tijdelijk zwaarder mee.'
            : 'Gemiddelde beoordeling van zichtbare afgeronde lessen.',
      ),
    ];
  }

  static Map<String, double> _competentiePercentages(
      Map<String, dynamic> vaardigheden) {
    final result = <String, double>{};
    for (final competentie in cbrCompetenties) {
      final scores = competentie.vaardigheidKeys
          .map((key) => (vaardigheden[key] as num?)?.toDouble() ?? 0)
          .where((score) => score > 0)
          .toList();
      if (scores.isEmpty) continue;
      result[competentie.naam] = (_average(scores) / 5).clamp(0, 1);
    }
    return result;
  }

  static double? _beoordelingScore(List<Les> lessen) {
    final scores = lessen
        .map((les) => switch (les.beoordeling) {
              '5' => 100.0,
              '4' => 82.0,
              '3' => 64.0,
              '2' => 46.0,
              '1' => 28.0,
              'goed' => 90.0,
              'voldoende' => 72.0,
              'onvoldoende' => 42.0,
              _ => null,
            })
        .whereType<double>()
        .toList();
    return scores.isEmpty ? null : _average(scores);
  }

  static double? _lesCompetentieScore(List<Les> lessen) {
    final scores = <double>[];
    for (final les in lessen) {
      final rawScores = les.competentieScores?.values ?? const [];
      for (final raw in rawScores) {
        final score = raw is num ? raw.toDouble() : null;
        if (score == null || score <= 0) continue;
        scores.add(score <= 5 ? score / 5 * 100 : score.clamp(0, 100));
      }
    }
    return scores.isEmpty ? null : _average(scores);
  }

  static List<String> _sterkePunten(
    Map<String, double> percentages, {
    required List<Les> zichtbareAfgerondeLessen,
  }) {
    final punten = percentages.entries
        .where((entry) => entry.value >= 0.75)
        .map((entry) => '${entry.key} gaat sterk en wordt steeds consistenter.')
        .toList();
    final goedeOnderwerpen = _onderwerpFrequenties(zichtbareAfgerondeLessen)
        .entries
        .where((entry) => entry.value >= 2)
        .map((entry) => '${entry.key} is meerdere keren geoefend.')
        .toList();
    return [...punten, ...goedeOnderwerpen];
  }

  static List<String> _nogOefenen(
    Map<String, double> percentages, {
    required List<Les> zichtbareAfgerondeLessen,
  }) {
    final aandacht = percentages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final items = aandacht
        .where((entry) => entry.value < 0.70)
        .map((entry) => 'Blijf oefenen op ${entry.key.toLowerCase()}.')
        .toList();
    if (items.isNotEmpty) return items;

    final recenteOnderwerpen = zichtbareAfgerondeLessen
        .expand((les) => les.geoefendeOnderwerpen)
        .take(3)
        .map((onderwerp) => 'Maak ${onderwerp.toLowerCase()} nog consistenter.')
        .toList();
    return recenteOnderwerpen;
  }

  static Map<String, int> _onderwerpFrequenties(List<Les> lessen) {
    final result = <String, int>{};
    for (final onderwerp in lessen.expand((les) => les.geoefendeOnderwerpen)) {
      result[onderwerp] = (result[onderwerp] ?? 0) + 1;
    }
    return result;
  }

  static String _uitleg({
    required int score,
    required double lesProgressScore,
    required double? vaardigheidScore,
    required double? beoordelingScore,
  }) {
    final onderdelen = <String>[
      'Deze score is berekend uit je gevolgde lessen',
      if (vaardigheidScore != null) 'vaardigheidsscores',
      if (beoordelingScore != null) 'beoordelingen van afgeronde lessen',
    ];
    final basis = onderdelen.join(', ');
    if (score >= 80) {
      return '$basis. Je rijdt op meerdere onderdelen stabiel genoeg om richting examenadvies te werken.';
    }
    if (score >= 55) {
      return '$basis. Je bent goed op weg, maar de score laat zien dat een paar onderdelen nog consistenter moeten worden.';
    }
    return '$basis. De basis wordt opgebouwd; focus eerst op vaste routines en controle in meerdere lessituaties.';
  }

  static String _resterendeLessen(int score, LeerlingProfiel profiel) {
    final resterendPakket =
        (profiel.lessenTotaal - profiel.lessenGevolgd).clamp(0, 99);
    if (score >= 85) return 'Waarschijnlijk nog enkele lessen tot examenadvies';
    if (score >= 70) return 'Nog ongeveer 4-6 lessen tot examenadvies';
    if (score >= 55) return 'Nog ongeveer 8-10 lessen tot examenadvies';
    if (resterendPakket > 0) {
      return 'Nog ongeveer $resterendPakket lessen in je huidige pakket';
    }
    return mockExamenadvies.resterendeLessen;
  }

  static String _statusVoor(int score) {
    if (score >= 85) return 'Bijna klaar';
    if (score >= 60) return 'Goed op weg';
    return 'Nog oefenen';
  }

  static double _weightedAverage(List<_WeightedScore> scores) {
    final totaalGewicht = scores.fold<double>(0, (sum, s) => sum + s.weight);
    if (totaalGewicht == 0) return mockExamenadvies.score.toDouble();
    return scores.fold<double>(0, (sum, s) => sum + s.score * s.weight) /
        totaalGewicht;
  }

  static double _average(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}

class _WeightedScore {
  final double score;
  final double weight;

  const _WeightedScore(this.score, this.weight);
}
