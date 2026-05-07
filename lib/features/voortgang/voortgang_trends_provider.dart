import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import '../../shared/providers/auth_provider.dart';
import 'voortgang_provider.dart';

final voortgangTrendsProvider =
    FutureProvider.autoDispose<VoortgangTrendsData>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return mockVoortgangTrends;

  try {
    final lessen = await StudentService.getMijnVorigeLessen(
      profiel.id,
      alleenZichtbaarLogboek: true,
    );
    final data = VoortgangTrendsCalculator.bereken(
      profiel: profiel,
      lessen: lessen,
    );
    return data.heeftHistorie ? data : mockVoortgangTrends;
  } catch (_) {
    return mockVoortgangTrends;
  }
});

class VoortgangTrendsData {
  final bool isMock;
  final int huidigeScore;
  final int vorigeScore;
  final int verschil;
  final String trendLabel;
  final String uitleg;
  final double? gemiddeldeBeoordeling;
  final String beoordelingTrend;
  final String competentieTrend;
  final String lessenPerWeekLabel;
  final List<TrendPoint> scoreHistorie;
  final List<CompetentieTrend> competenties;
  final List<LesTijdlijnItem> tijdlijn;

  const VoortgangTrendsData({
    required this.isMock,
    required this.huidigeScore,
    required this.vorigeScore,
    required this.verschil,
    required this.trendLabel,
    required this.uitleg,
    required this.gemiddeldeBeoordeling,
    required this.beoordelingTrend,
    required this.competentieTrend,
    required this.lessenPerWeekLabel,
    required this.scoreHistorie,
    required this.competenties,
    required this.tijdlijn,
  });

  bool get heeftHistorie => scoreHistorie.length >= 2 || tijdlijn.length >= 2;
}

class TrendPoint {
  final String label;
  final int score;

  const TrendPoint({required this.label, required this.score});
}

class CompetentieTrend {
  final String naam;
  final int huidigeScore;
  final int vorigeScore;
  final int verschil;
  final String label;

  const CompetentieTrend({
    required this.naam,
    required this.huidigeScore,
    required this.vorigeScore,
    required this.verschil,
    required this.label,
  });
}

class LesTijdlijnItem {
  final String datumLabel;
  final String beoordelingLabel;
  final String feedback;
  final String competentieLabel;

  const LesTijdlijnItem({
    required this.datumLabel,
    required this.beoordelingLabel,
    required this.feedback,
    required this.competentieLabel,
  });
}

class VoortgangTrendsCalculator {
  const VoortgangTrendsCalculator._();

  static VoortgangTrendsData bereken({
    required LeerlingProfiel profiel,
    required List<Les> lessen,
  }) {
    final chronologisch = [...lessen]..sort((a, b) =>
        '${a.datum} ${a.starttijd}'.compareTo('${b.datum} ${b.starttijd}'));
    if (chronologisch.isEmpty) return mockVoortgangTrends;

    final scoreHistorie = <TrendPoint>[];
    for (var i = 0; i < chronologisch.length; i++) {
      final subset = chronologisch.take(i + 1).toList();
      scoreHistorie.add(
        TrendPoint(
          label: _dagMaand(chronologisch[i].datum),
          score: _readinessVoor(
            profiel: profiel,
            lessenTotNu: subset,
            gevolgdeLessenTotNu: i + 1,
          ),
        ),
      );
    }

    final huidige = scoreHistorie.last.score;
    final vorige = scoreHistorie.length >= 2
        ? scoreHistorie[scoreHistorie.length - 2].score
        : huidige;
    final verschil = huidige - vorige;
    final recente = chronologisch.length > 4
        ? chronologisch.sublist(chronologisch.length - 4)
        : chronologisch;

    return VoortgangTrendsData(
      isMock: false,
      huidigeScore: huidige,
      vorigeScore: vorige,
      verschil: verschil,
      trendLabel: _trendLabel(verschil),
      uitleg: _scoreUitleg(vorige, huidige, verschil),
      gemiddeldeBeoordeling: _gemiddeldeBeoordeling(recente),
      beoordelingTrend: _beoordelingTrend(chronologisch),
      competentieTrend: _competentieTrend(chronologisch),
      lessenPerWeekLabel: _lessenPerWeekLabel(chronologisch),
      scoreHistorie: scoreHistorie.takeLast(6),
      competenties: _competentieTrends(chronologisch).take(4).toList(),
      tijdlijn: chronologisch.reversed.take(6).map(_tijdlijnItem).toList(),
    );
  }

  static int _readinessVoor({
    required LeerlingProfiel profiel,
    required List<Les> lessenTotNu,
    required int gevolgdeLessenTotNu,
  }) {
    final lesProgress = profiel.lessenTotaal <= 0
        ? 0.0
        : (gevolgdeLessenTotNu / profiel.lessenTotaal * 100)
            .clamp(0, 100)
            .toDouble();
    final beoordeling = _beoordelingScore(lessenTotNu);
    final competenties = _competentieScore(lessenTotNu);

    final onderdelen = <_WeightedScore>[
      _WeightedScore(lesProgress, 0.40),
      if (competenties != null) _WeightedScore(competenties, 0.35),
      if (beoordeling != null) _WeightedScore(beoordeling, 0.25),
    ];
    return _weightedAverage(onderdelen).round().clamp(0, 100).toInt();
  }

  static List<CompetentieTrend> _competentieTrends(List<Les> lessen) {
    if (lessen.length < 2) return const [];
    final vorigeLessen = lessen.take(lessen.length - 1).toList();
    final huidigeScores = _competentieGemiddelden(lessen);
    final vorigeScores = _competentieGemiddelden(vorigeLessen);

    final result = <CompetentieTrend>[];
    for (final entry in huidigeScores.entries) {
      final vorige = vorigeScores[entry.key] ?? entry.value;
      final verschil = (entry.value - vorige).round();
      result.add(CompetentieTrend(
        naam: _competentieNaam(entry.key),
        huidigeScore: entry.value.round(),
        vorigeScore: vorige.round(),
        verschil: verschil,
        label: _trendLabel(verschil),
      ));
    }
    result.sort((a, b) => b.verschil.abs().compareTo(a.verschil.abs()));
    return result;
  }

  static Map<String, double> _competentieGemiddelden(List<Les> lessen) {
    final values = <String, List<double>>{};
    for (final les in lessen) {
      final scores = les.competentieScores ?? const <String, dynamic>{};
      for (final entry in scores.entries) {
        final raw = entry.value;
        final score = raw is num ? raw.toDouble() : null;
        if (score == null || score <= 0) continue;
        values.putIfAbsent(entry.key, () => []).add(
              score <= 5 ? score / 5 * 100 : score.clamp(0, 100),
            );
      }
    }
    return values.map((key, scores) => MapEntry(key, _average(scores)));
  }

  static LesTijdlijnItem _tijdlijnItem(Les les) {
    final besteCompetentie = _besteCompetentie(les);
    return LesTijdlijnItem(
      datumLabel: '${_dagMaand(les.datum)} · ${les.starttijd}',
      beoordelingLabel: _beoordelingLabel(les.beoordeling),
      feedback: (les.instructeurFeedback ?? '').trim().isNotEmpty
          ? les.instructeurFeedback!.trim()
          : 'Feedback is zichtbaar gemaakt voor je logboek.',
      competentieLabel: besteCompetentie,
    );
  }

  static String _besteCompetentie(Les les) {
    final scores = les.competentieScores ?? const <String, dynamic>{};
    MapEntry<String, dynamic>? beste;
    for (final entry in scores.entries) {
      final raw = entry.value;
      if (raw is! num) continue;
      if (beste == null || raw.toDouble() > (beste.value as num).toDouble()) {
        beste = entry;
      }
    }
    if (beste == null) {
      return les.geoefendeOnderwerpen.isEmpty
          ? 'Nog geen competentiescore'
          : 'Geoefend: ${les.geoefendeOnderwerpen.take(2).join(', ')}';
    }
    return '${_competentieNaam(beste.key)} scoorde ${beste.value}/5';
  }

  static double? _gemiddeldeBeoordeling(List<Les> lessen) {
    final scores = lessen.map(_beoordelingWaarde).whereType<double>().toList();
    return scores.isEmpty ? null : _average(scores);
  }

  static double? _beoordelingScore(List<Les> lessen) {
    final gemiddelde = _gemiddeldeBeoordeling(lessen);
    if (gemiddelde == null) return null;
    return (gemiddelde / 5 * 100).clamp(0, 100);
  }

  static double? _competentieScore(List<Les> lessen) {
    final scores = _competentieGemiddelden(lessen).values.toList();
    return scores.isEmpty ? null : _average(scores);
  }

  static double? _beoordelingWaarde(Les les) {
    return switch (les.beoordeling) {
      '5' => 5,
      '4' => 4,
      '3' => 3,
      '2' => 2,
      '1' => 1,
      'goed' => 4,
      'voldoende' => 3,
      'onvoldoende' => 2,
      _ => null,
    };
  }

  static String _beoordelingTrend(List<Les> lessen) {
    final scores = lessen.map(_beoordelingWaarde).whereType<double>().toList();
    if (scores.length < 2) return 'Nog onvoldoende beoordelingsdata';
    final verschil = scores.last - scores.first;
    if (verschil > 0.3) return 'Je beoordelingen verbeteren';
    if (verschil < -0.3) return 'Meer oefenen nodig op beoordeling';
    return 'Je beoordelingen zijn stabiel';
  }

  static String _competentieTrend(List<Les> lessen) {
    final trends = _competentieTrends(lessen);
    if (trends.isEmpty) return 'Nog onvoldoende competentiedata';
    final stabiel = trends.firstWhere(
      (trend) => trend.verschil.abs() <= 4,
      orElse: () => trends.first,
    );
    if (stabiel.verschil.abs() <= 4) {
      return '${stabiel.naam} is ${lessen.length.clamp(2, 3)} lessen stabiel gebleven';
    }
    if (trends.first.verschil > 0) return '${trends.first.naam} gaat vooruit';
    return '${trends.first.naam} vraagt extra aandacht';
  }

  static String _lessenPerWeekLabel(List<Les> lessen) {
    if (lessen.length < 2) return 'Nog te weinig lessen voor weektrend';
    final eerste = DateTime.tryParse(lessen.first.datum);
    final laatste = DateTime.tryParse(lessen.last.datum);
    if (eerste == null || laatste == null) {
      return '${lessen.length} afgeronde lessen';
    }
    final dagen = laatste.difference(eerste).inDays.abs().clamp(1, 365);
    final weken = (dagen / 7).clamp(1, 99);
    final perWeek = lessen.length / weken;
    return '${perWeek.toStringAsFixed(1)} afgeronde lessen per week';
  }

  static String _scoreUitleg(int vorige, int huidige, int verschil) {
    if (verschil > 0) {
      return 'Je examenadvies steeg van $vorige% naar $huidige%.';
    }
    if (verschil < 0) {
      return 'Je examenadvies ging van $vorige% naar $huidige%; focus op consistentie.';
    }
    return 'Je examenadvies bleef stabiel op $huidige%.';
  }

  static String _trendLabel(int verschil) {
    if (verschil >= 3) return 'Stijgend';
    if (verschil <= -3) return 'Meer oefenen nodig';
    return 'Stabiel';
  }

  static String _beoordelingLabel(String? beoordeling) {
    return switch (beoordeling) {
      '5' => '5 van 5',
      '4' => '4 van 5',
      '3' => '3 van 5',
      '2' => '2 van 5',
      '1' => '1 van 5',
      'goed' => 'Goed',
      'voldoende' => 'Voldoende',
      'onvoldoende' => 'Onvoldoende',
      _ => 'Geen beoordeling',
    };
  }

  static String _competentieNaam(String key) {
    return switch (key) {
      'voertuigbeheersing' => 'Voertuigbeheersing',
      'kijkgedrag' => 'Kijkgedrag',
      'verkeersinzicht' => 'Verkeersinzicht',
      'bijzondere_verrichtingen' => 'Bijzondere verrichtingen',
      'zelfstandig_rijden' => 'Zelfstandig rijden',
      'examenvoorbereiding' => 'Examenvoorbereiding',
      _ => key.replaceAll('_', ' '),
    };
  }

  static String _dagMaand(String datum) {
    final parsed = DateTime.tryParse(datum);
    if (parsed == null) return datum;
    return '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}';
  }

  static double _weightedAverage(List<_WeightedScore> scores) {
    final totaal = scores.fold<double>(0, (sum, item) => sum + item.weight);
    if (scores.isEmpty || totaal == 0) return 0;
    return scores.fold<double>(
            0, (sum, item) => sum + item.score * item.weight) /
        totaal;
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

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return this;
    return sublist(length - count);
  }
}

const mockVoortgangTrends = VoortgangTrendsData(
  isMock: true,
  huidigeScore: 67,
  vorigeScore: 58,
  verschil: 9,
  trendLabel: 'Stijgend',
  uitleg: 'Je examenadvies steeg van 58% naar 67%.',
  gemiddeldeBeoordeling: 2.3,
  beoordelingTrend: 'Je beoordelingen verbeteren',
  competentieTrend: 'Kijkgedrag is 3 lessen stabiel gebleven',
  lessenPerWeekLabel: '1.5 afgeronde lessen per week',
  scoreHistorie: [
    TrendPoint(label: '08-04', score: 48),
    TrendPoint(label: '15-04', score: 53),
    TrendPoint(label: '22-04', score: 58),
    TrendPoint(label: '29-04', score: 62),
    TrendPoint(label: '06-05', score: 67),
  ],
  competenties: [
    CompetentieTrend(
      naam: 'Kijkgedrag',
      huidigeScore: 68,
      vorigeScore: 65,
      verschil: 3,
      label: 'Stabiel',
    ),
    CompetentieTrend(
      naam: 'Zelfstandig rijden',
      huidigeScore: 55,
      vorigeScore: 48,
      verschil: 7,
      label: 'Stijgend',
    ),
  ],
  tijdlijn: [
    LesTijdlijnItem(
      datumLabel: '06-05 · 10:15',
      beoordelingLabel: 'Voldoende',
      feedback: 'Je keek beter vooruit, blijf rust houden bij kruispunten.',
      competentieLabel: 'Kijkgedrag scoorde 3/5',
    ),
    LesTijdlijnItem(
      datumLabel: '29-04 · 11:00',
      beoordelingLabel: 'Voldoende',
      feedback: 'Rotondes gingen rustiger, spiegelen blijft aandachtspunt.',
      competentieLabel: 'Zelfstandig rijden scoorde 3/5',
    ),
  ],
);
