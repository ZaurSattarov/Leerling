import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import 'voortgang_provider.dart';

final voortgangTrendsProvider =
    FutureProvider.autoDispose<VoortgangTrendsData>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return emptyVoortgangTrends;

  try {
    final lessen = await StudentService.getMijnVorigeLessen(
      profiel.id,
      alleenZichtbaarLogboek: true,
    );
    return VoortgangTrendsCalculator.bereken(
      profiel: profiel,
      lessen: lessen,
    );
  } catch (_) {
    return emptyVoortgangTrends;
  }
});

// ── Data models ───────────────────────────────────────────────────────────────

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

  // New: enriched fields for redesigned UI
  final List<String> sterkeCompetenties;
  final List<String> aandachtspunten;
  final String lesAdvies;
  final String motivatieTekst;
  final List<InzichtItem> inzichten;
  final List<double> radarWaarden; // 0..1 per CBR-competentie (6 values)

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
    required this.sterkeCompetenties,
    required this.aandachtspunten,
    required this.lesAdvies,
    required this.motivatieTekst,
    required this.inzichten,
    required this.radarWaarden,
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

/// Eén inzicht-item voor "Wat verandert er?" sectie
class InzichtItem {
  final IconData icon;
  final Color iconColor;
  final String tekst;
  final String? delta;
  final Color? deltaColor;

  const InzichtItem({
    required this.icon,
    required this.iconColor,
    required this.tekst,
    this.delta,
    this.deltaColor,
  });
}

/// Tijdlijn item — rijker dan voorheen
class LesTijdlijnItem {
  final String datumLabel;
  final String tijdLabel;
  final String eventType; // 'les_afgerond' | 'beoordeling' | 'aandachtspunt'
  final String? lesType;
  final String beoordelingLabel;
  final String feedback;
  final String competentieLabel;
  final List<String> onderwerpen;
  final List<CompetentieDelta> verbeteringen;

  const LesTijdlijnItem({
    required this.datumLabel,
    required this.tijdLabel,
    required this.eventType,
    this.lesType,
    required this.beoordelingLabel,
    required this.feedback,
    required this.competentieLabel,
    this.onderwerpen = const [],
    this.verbeteringen = const [],
  });
}

class CompetentieDelta {
  final String naam;
  final int delta;

  const CompetentieDelta({required this.naam, required this.delta});
}

// ── Calculator ────────────────────────────────────────────────────────────────

class VoortgangTrendsCalculator {
  const VoortgangTrendsCalculator._();

  static VoortgangTrendsData bereken({
    required LeerlingProfiel profiel,
    required List<Les> lessen,
  }) {
    final chronologisch = [...lessen]..sort((a, b) =>
        '${a.datum} ${a.starttijd}'.compareTo('${b.datum} ${b.starttijd}'));
    if (chronologisch.isEmpty) return emptyVoortgangTrends;

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

    final competentieTrends = _competentieTrends(chronologisch).take(4).toList();
    final sterke = _sterkeCompetenties(chronologisch);
    final aandacht = _aandachtspunten(chronologisch);
    final radarWaarden = _radarWaarden(profiel);

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
      competenties: competentieTrends,
      tijdlijn: chronologisch.reversed.take(8).map(_tijdlijnItem).toList(),
      sterkeCompetenties: sterke,
      aandachtspunten: aandacht,
      lesAdvies: _lesAdvies(aandacht, chronologisch),
      motivatieTekst: _motivatieTekst(huidige, verschil, sterke),
      inzichten: _inzichten(
        competentieTrends: competentieTrends,
        chronologisch: chronologisch,
        huidige: huidige,
        vorige: vorige,
        verschil: verschil,
      ),
      radarWaarden: radarWaarden,
    );
  }

  // ── Radar waarden (per CBR-competentie in volgorde van cbrCompetenties) ─────

  static List<double> _radarWaarden(LeerlingProfiel profiel) {
    final vaardigheden = profiel.vaardigheden ?? <String, dynamic>{};
    return cbrCompetenties.map((c) {
      final scores = c.vaardigheidKeys
          .map((key) => (vaardigheden[key] as num? ?? 0).toDouble())
          .where((s) => s > 0)
          .toList();
      if (scores.isEmpty) return 0.0;
      return (scores.reduce((a, b) => a + b) / scores.length / 5.0)
          .clamp(0.0, 1.0);
    }).toList();
  }

  // ── Sterke / aandacht punten ──────────────────────────────────────────────

  static List<String> _sterkeCompetenties(List<Les> lessen) {
    final gemiddelden = _competentieGemiddelden(lessen);
    final gesorteerd = gemiddelden.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return gesorteerd
        .where((e) => e.value >= 60)
        .take(3)
        .map((e) => _competentieNaam(e.key))
        .toList();
  }

  static List<String> _aandachtspunten(List<Les> lessen) {
    final gemiddelden = _competentieGemiddelden(lessen);
    final gesorteerd = gemiddelden.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return gesorteerd
        .where((e) => e.value < 65)
        .take(3)
        .map((e) => _competentieNaam(e.key))
        .toList();
  }

  // ── Les advies & motivatie ────────────────────────────────────────────────

  static String _lesAdvies(List<String> aandacht, List<Les> lessen) {
    if (aandacht.isEmpty) return 'Blijf consistent oefenen en focus op je sterkste punten.';
    if (aandacht.length == 1) return 'Focus de volgende les op ${aandacht.first.toLowerCase()}.';
    return 'Focus de volgende les op ${aandacht.first.toLowerCase()} en ${aandacht[1].toLowerCase()}.';
  }

  static String _motivatieTekst(int huidige, int verschil, List<String> sterk) {
    if (huidige >= 85) return 'Je bent klaar voor het examen! Blijf consistent.';
    if (huidige >= 70) return 'Goed bezig, je bent bijna examenklaar.';
    if (verschil > 0) {
      if (sterk.isNotEmpty) {
        return 'Mooi! Je ${sterk.first.toLowerCase()} gaat steeds beter.';
      }
      return 'Je bent goed op weg, blijf zo doorgaan.';
    }
    if (verschil < 0) return 'Extra oefenen loont — focus op de aandachtspunten.';
    return 'Je voortgang is stabiel. Meer lessen helpen je verder.';
  }

  // ── Dynamische inzichten ──────────────────────────────────────────────────

  static List<InzichtItem> _inzichten({
    required List<CompetentieTrend> competentieTrends,
    required List<Les> chronologisch,
    required int huidige,
    required int vorige,
    required int verschil,
  }) {
    final items = <InzichtItem>[];

    // Score verandering
    if (verschil != 0) {
      items.add(InzichtItem(
        icon: verschil > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        iconColor: verschil > 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFE11D48),
        tekst: verschil > 0
            ? 'Je examenadvies steeg van $vorige% naar $huidige%.'
            : 'Je examenadvies daalde van $vorige% naar $huidige%.',
        delta: '${verschil >= 0 ? '+' : ''}$verschil%',
        deltaColor: verschil > 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFE11D48),
      ));
    }

    // Stijgende competentie
    final stijgend = competentieTrends.where((c) => c.verschil >= 5).toList();
    for (final c in stijgend.take(2)) {
      items.add(InzichtItem(
        icon: Icons.arrow_upward_rounded,
        iconColor: const Color(0xFF16A34A),
        tekst: 'Je ${c.naam.toLowerCase()} verbeterde van ${c.vorigeScore}% naar ${c.huidigeScore}%.',
        delta: '+${c.verschil}%',
        deltaColor: const Color(0xFF16A34A),
      ));
    }

    // Dalende competentie
    final dalend = competentieTrends.where((c) => c.verschil <= -5).toList();
    for (final c in dalend.take(1)) {
      items.add(InzichtItem(
        icon: Icons.arrow_downward_rounded,
        iconColor: const Color(0xFFD97706),
        tekst: '${c.naam} vraagt extra aandacht (${c.huidigeScore}%).',
        delta: '${c.verschil}%',
        deltaColor: const Color(0xFFD97706),
      ));
    }

    // Stabiele competentie
    final stabiel = competentieTrends
        .where((c) => c.verschil.abs() < 5 && c.huidigeScore >= 60)
        .toList();
    if (stabiel.isNotEmpty) {
      items.add(InzichtItem(
        icon: Icons.remove_rounded,
        iconColor: const Color(0xFF64748B),
        tekst: '${stabiel.first.naam} blijft stabiel op ${stabiel.first.huidigeScore}%.',
      ));
    }

    // Lesritme
    if (chronologisch.length >= 2) {
      items.add(InzichtItem(
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF2563EB),
        tekst: _lessenPerWeekLabel(chronologisch),
      ));
    }

    // Laatste beoordeling
    final laatste = chronologisch.isNotEmpty ? chronologisch.last : null;
    if (laatste?.beoordeling != null &&
        _beoordelingLabel(laatste!.beoordeling) != 'Geen beoordeling') {
      items.add(InzichtItem(
        icon: Icons.grade_rounded,
        iconColor: const Color(0xFFD97706),
        tekst: 'Laatste beoordeling: ${_beoordelingLabel(laatste.beoordeling)} op ${_dagMaand(laatste.datum)}.',
      ));
    }

    return items.take(5).toList();
  }

  // ── Tijdlijn ──────────────────────────────────────────────────────────────

  static LesTijdlijnItem _tijdlijnItem(Les les) {
    final besteCompetentie = _besteCompetentie(les);
    final competentieDeltas = _deltaVoorLes(les);
    final heeftBeoordeling = les.beoordeling != null &&
        _beoordelingLabel(les.beoordeling) != 'Geen beoordeling';
    final heeftAandachtspunt = les.instructeurFeedback?.isNotEmpty == true &&
        les.zichtbaarVoorLeerling;

    String eventType;
    if (heeftBeoordeling) {
      eventType = 'beoordeling';
    } else if (heeftAandachtspunt) {
      eventType = 'aandachtspunt';
    } else {
      eventType = 'les_afgerond';
    }

    return LesTijdlijnItem(
      datumLabel: _langeDatum(les.datum),
      tijdLabel: les.starttijd,
      eventType: eventType,
      lesType: les.lesType,
      beoordelingLabel: _beoordelingLabel(les.beoordeling),
      feedback: les.zichtbaarVoorLeerling &&
              les.instructeurFeedback?.trim().isNotEmpty == true
          ? les.instructeurFeedback!.trim()
          : '',
      competentieLabel: besteCompetentie,
      onderwerpen: les.geoefendeOnderwerpen.take(3).toList(),
      verbeteringen: competentieDeltas,
    );
  }

  static List<CompetentieDelta> _deltaVoorLes(Les les) {
    final scores = les.competentieScores ?? const <String, dynamic>{};
    final result = <CompetentieDelta>[];
    for (final entry in scores.entries) {
      final raw = entry.value;
      if (raw is! num || raw.toDouble() <= 0) continue;
      final pct = (raw.toDouble() / 5 * 100).round();
      result.add(CompetentieDelta(
        naam: _competentieNaam(entry.key),
        delta: pct,
      ));
    }
    result.sort((a, b) => b.delta.compareTo(a.delta));
    return result.take(3).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
          ? ''
          : les.geoefendeOnderwerpen.take(2).join(', ');
    }
    return '${_competentieNaam(beste.key)} ${beste.value}/5';
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
    return 'Je rijdt gemiddeld ${perWeek.toStringAsFixed(1)} lessen per week.';
  }

  static String _scoreUitleg(int vorige, int huidige, int verschil) {
    if (verschil > 0) return 'Je examenadvies steeg van $vorige% naar $huidige%.';
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
      '5' => '5/5',
      '4' => '4/5',
      '3' => '3/5',
      '2' => '2/5',
      '1' => '1/5',
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

  static String _langeDatum(String datum) {
    final parsed = DateTime.tryParse(datum);
    if (parsed == null) return datum;
    const maanden = [
      'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    return '${parsed.day} ${maanden[parsed.month - 1]} ${parsed.year}';
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

const emptyVoortgangTrends = VoortgangTrendsData(
  isMock: true,
  huidigeScore: 0,
  vorigeScore: 0,
  verschil: 0,
  trendLabel: 'Nog onvoldoende data',
  uitleg: 'Volg meer lessen om je voortgang te zien.',
  gemiddeldeBeoordeling: null,
  beoordelingTrend: 'Nog onvoldoende beoordelingsdata',
  competentieTrend: 'Nog onvoldoende competentiedata',
  lessenPerWeekLabel: 'Nog geen afgeronde lessen',
  scoreHistorie: [],
  competenties: [],
  tijdlijn: [],
  sterkeCompetenties: [],
  aandachtspunten: [],
  lesAdvies: 'Volg meer lessen voor persoonlijk lesadvies.',
  motivatieTekst: 'Volg je eerste les om je voortgang bij te houden.',
  inzichten: [],
  radarWaarden: [0, 0, 0, 0, 0, 0],
);
