import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/les.dart';
import '../examenadvies/examenadvies_ontwikkeling.dart';
import '../examenadvies/examenadvies_provider.dart';
import 'voortgang_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Voortgang-provider: uitsluitend een ADAPTER over canonical data.
//
// - Examenadvies %, categorieën, sterke punten, aandachtspunten, trend en
//   sparkline komen ALLEMAAL uit `examenadviesProvider` (→ Postgres RPC
//   `rpc_get_examenadvies` → `klantio_bereken_examenadvies`). Zelfde bron als
//   Home, geen tweede formule in Flutter. Zie
//   `Klantio-Knowledge/02 - FEATURES/Examenadvies.md`.
// - Alleen puur les-gebaseerde statistieken (lessen/week, laatste
//   beoordeling, tijdlijn) komen uit `student_lessen_view` — die vallen
//   bewust NIET onder Examenadvies.
// ─────────────────────────────────────────────────────────────────────────────

final voortgangTrendsProvider =
    FutureProvider.autoDispose<VoortgangTrendsData>((ref) async {
  final profielAsync = await ref.watch(mijnProfielProvider.future);
  if (profielAsync == null) return emptyVoortgangTrends;

  // Canonical Examenadvies-bron — exact dezelfde die Home gebruikt.
  final advies = await ref.watch(examenadviesProvider.future);

  // Aanvullende lesstatistieken (GEEN examenadvies-inhoud).
  List<Les> lessen;
  try {
    lessen = await StudentService.getMijnVorigeLessen(
      profielAsync.id,
      alleenZichtbaarLogboek: true,
    );
  } catch (_) {
    lessen = const [];
  }

  return VoortgangTrendsCalculator.fromCanonical(
    advies: advies,
    lessen: lessen,
  );
});

// ── Data models ───────────────────────────────────────────────────────────────

class VoortgangTrendsData {
  final bool isMock;

  /// Canonical Examenadvies-percentage (uit RPC `advies.score`). 0 als er
  /// nog geen betrouwbare score is. Nooit lokaal opnieuw berekend.
  final int huidigeScore;

  /// Canonical betrouwbaarheidsvlag: wanneer false hoort er GEEN percentage
  /// getoond te worden (dan tonen we een "onvoldoende data"-toestand).
  final bool heeftBetrouwbareScore;

  /// Statusklasse-label van Postgres (`advies.statusLabel`).
  final String statusLabel;

  /// Canonical uitlegtekst voor de ontwikkeling ("Je verkeersinzicht is
  /// verbeterd" etc.). Leeg wanneer de RPC niets geeft.
  final String ontwikkelingTekst;

  /// Bewust op 0 vastgezet: de canonical RPC levert geen totaal-%-delta.
  /// Trend-informatie leeft in `sparkline` en in `radarCategorieen[].trend`.
  final int vorigeScore;
  final int verschil;

  /// Canonical sparkline (uit `bouwOntwikkelingSparkline(advies)`) — zelfde
  /// helper als Home gebruikt voor de Ontwikkeling-kaart. `null` als er
  /// minder dan 2 canonical lespunten in enige categorie zijn.
  final ExamenadviesSparklineData? sparkline;

  /// UI-adapter over `sparkline.punten`: dezelfde punten in de bestaande
  /// TrendPoint-vorm zodat de bestaande `_LineChartPainter` niet hoeft te
  /// wijzigen. Schaalconversie 1..5 → 0..100, geen berekening.
  final List<TrendPoint> scoreHistorie;

  /// Canonical 6 categorieën uit `advies.categorieen`, altijd in
  /// vaste canonical volgorde (Voertuigbeheersing, Observatie, Manoeuvres,
  /// Verkeer, Wegpositie, Gedrag). Ontbrekende categorieën hebben
  /// `huidigOpVijf == null`. Zowel de radar als de rijen eronder consumeren
  /// deze lijst — één bron, geen tweede berekening.
  final List<CategorieScore> radarCategorieen;

  /// Sterke punten (canonical `advies.sterkePunten`).
  final List<String> sterkeCompetenties;

  /// Aandachtspunten (canonical `advies.nogOefenen`).
  final List<String> aandachtspunten;

  /// "Wat verandert er?"-rijen: canonical categorie-trends + puur
  /// les-gebaseerde statistieken (lesritme, laatste beoordeling).
  final List<InzichtItem> inzichten;

  /// Voor "Wat verandert er?"-lesritme (uit lessen, GEEN examenadvies).
  final String lessenPerWeekLabel;

  /// Voor de tijdlijn-card (uit lessen, GEEN examenadvies).
  final List<LesTijdlijnItem> tijdlijn;

  const VoortgangTrendsData({
    required this.isMock,
    required this.huidigeScore,
    required this.heeftBetrouwbareScore,
    required this.statusLabel,
    required this.ontwikkelingTekst,
    required this.vorigeScore,
    required this.verschil,
    required this.sparkline,
    required this.scoreHistorie,
    required this.radarCategorieen,
    required this.sterkeCompetenties,
    required this.aandachtspunten,
    required this.inzichten,
    required this.lessenPerWeekLabel,
    required this.tijdlijn,
  });
}

class TrendPoint {
  final String label;
  final int score;

  const TrendPoint({required this.label, required this.score});
}

/// Eén inzicht-item voor "Wat verandert er?" sectie
class InzichtItem {
  final IconData icon;
  final Color iconColor;
  final String titel;
  final String? oudeWaarde;
  final String? nieuweWaarde;
  final String? waarde;
  final String? delta;
  final Color? deltaColor;

  const InzichtItem({
    required this.icon,
    required this.iconColor,
    required this.titel,
    this.oudeWaarde,
    this.nieuweWaarde,
    this.waarde,
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

// ── Canonical adapter ─────────────────────────────────────────────────────────

class VoortgangTrendsCalculator {
  const VoortgangTrendsCalculator._();

  /// Zet canonical `ExamenadviesData` + lesdata om in de UI-shape van
  /// `VoortgangTrendsData`. Geen businesslogica; alleen mappen/labelen.
  static VoortgangTrendsData fromCanonical({
    required ExamenadviesData advies,
    required List<Les> lessen,
  }) {
    final chronologisch = [...lessen]..sort((a, b) =>
        '${a.datum} ${a.starttijd}'.compareTo('${b.datum} ${b.starttijd}'));

    final radarCats = _canonicalRadar(advies);
    final sparkline = bouwOntwikkelingSparkline(advies);
    final scoreHistorie = _sparklineNaarTrendPoints(sparkline);

    return VoortgangTrendsData(
      isMock: false,
      huidigeScore: advies.score ?? 0,
      heeftBetrouwbareScore: advies.heeftBetrouwbareScore,
      statusLabel: advies.statusLabel,
      ontwikkelingTekst: advies.ontwikkeling,
      vorigeScore: 0,
      verschil: 0,
      sparkline: sparkline,
      scoreHistorie: scoreHistorie,
      radarCategorieen: radarCats,
      sterkeCompetenties: advies.sterkePunten,
      aandachtspunten: advies.nogOefenen,
      inzichten: _inzichten(
        advies: advies,
        chronologisch: chronologisch,
      ),
      lessenPerWeekLabel: _lessenPerWeekLabel(chronologisch),
      tijdlijn: chronologisch.reversed.map(_tijdlijnItem).toList(),
    );
  }

  // ── Canonical radar-categorieën ──────────────────────────────────────────
  //
  // Altijd 6 canonieke categorieën in vaste volgorde. Wanneer de RPC voor
  // een categorie geen rij heeft (bv. bij `onvoldoendeData`), tonen we die
  // categorie met `huidigOpVijf == null` en trend `onbekend` — dat is de
  // canonical "leeg"-toestand, geen verzonnen waarde.

  static List<CategorieScore> _canonicalRadar(ExamenadviesData advies) {
    final perNaam = <String, CategorieScore>{
      for (final c in advies.categorieen) c.naam: c,
    };
    return [
      for (final cat in examenVaardigheidCategorieen)
        perNaam[cat.naam] ??
            CategorieScore(
              naam: cat.naam,
              huidigOpVijf: null,
              trend: VaardigheidTrend.onbekend,
            ),
    ];
  }

  static List<TrendPoint> _sparklineNaarTrendPoints(
    ExamenadviesSparklineData? sparkline,
  ) {
    if (sparkline == null || sparkline.punten.length < 2) return const [];
    // Canonical historie is op 1..5-schaal. UI-schaalconversie naar 0..100
    // zodat de bestaande `_LineChartPainter` en `%`-labels blijven werken.
    return [
      for (var i = 0; i < sparkline.punten.length; i++)
        TrendPoint(
          label: '${i + 1}',
          score: (sparkline.punten[i] * 20).round().clamp(0, 100),
        ),
    ];
  }

  // ── "Wat verandert er?" ──────────────────────────────────────────────────

  static List<InzichtItem> _inzichten({
    required ExamenadviesData advies,
    required List<Les> chronologisch,
  }) {
    final items = <InzichtItem>[];

    // Canonical categorie-trends (uit de RPC, geen lokale delta-berekening).
    final stijgend = advies.categorieen
        .where((c) => c.trend == VaardigheidTrend.stijgt && c.heeftData)
        .toList();
    for (final c in stijgend.take(2)) {
      items.add(InzichtItem(
        icon: Icons.arrow_upward_rounded,
        iconColor: const Color(0xFF16A34A),
        titel: c.naam,
        // Bestaande UI-shape blijft (`oudeWaarde` / `nieuweWaarde`); we
        // hangen er canonical categoriewaarden aan i.p.v. verzonnen deltas.
        oudeWaarde: 'Vorige les',
        nieuweWaarde: '${c.scoreLabel}/5',
        delta: 'Stijgt',
        deltaColor: const Color(0xFF16A34A),
      ));
    }

    final dalend = advies.categorieen
        .where((c) => c.trend == VaardigheidTrend.daalt && c.heeftData)
        .toList();
    for (final c in dalend.take(1)) {
      items.add(InzichtItem(
        icon: Icons.arrow_downward_rounded,
        iconColor: const Color(0xFFD97706),
        titel: c.naam,
        oudeWaarde: 'Vorige les',
        nieuweWaarde: '${c.scoreLabel}/5',
        delta: 'Daalt',
        deltaColor: const Color(0xFFD97706),
      ));
    }

    final stabiel = advies.categorieen
        .where((c) => c.trend == VaardigheidTrend.stabiel && c.heeftData)
        .toList();
    if (stabiel.isNotEmpty) {
      final c = stabiel.first;
      items.add(InzichtItem(
        icon: Icons.remove_rounded,
        iconColor: const Color(0xFF64748B),
        titel: c.naam,
        waarde: '${c.scoreLabel}/5 stabiel',
      ));
    }

    // Puur les-gebaseerde statistieken (GEEN examenadvies-inhoud).
    if (chronologisch.length >= 2) {
      items.add(InzichtItem(
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF2563EB),
        titel: 'Gemiddeld aantal lessen',
        waarde: _lessenPerWeekLabel(chronologisch),
      ));
    }

    final laatste = chronologisch.isNotEmpty ? chronologisch.last : null;
    if (laatste?.beoordeling != null &&
        _beoordelingLabel(laatste!.beoordeling) != 'Geen beoordeling') {
      items.add(InzichtItem(
        icon: Icons.grade_rounded,
        iconColor: const Color(0xFFD97706),
        titel: 'Laatste beoordeling',
        waarde:
            '${_beoordelingLabel(laatste.beoordeling)} · ${_langeDatum(laatste.datum)}',
      ));
    }

    return items.take(5).toList();
  }

  // ── Tijdlijn (puur uit lesdata — geen examenadvies-formule) ──────────────

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
    return '${_competentieNaamKort(beste.key)} ${beste.value}/5';
  }

  static List<CompetentieDelta> _deltaVoorLes(Les les) {
    final scores = les.competentieScores ?? const <String, dynamic>{};
    final result = <CompetentieDelta>[];
    for (final entry in scores.entries) {
      final raw = entry.value;
      if (raw is! num || raw.toDouble() <= 0) continue;
      final pct = (raw.toDouble() / 5 * 100).round();
      result.add(CompetentieDelta(
        naam: _competentieNaamKort(entry.key),
        delta: pct,
      ));
    }
    result.sort((a, b) => b.delta.compareTo(a.delta));
    return result.take(3).toList();
  }

  static String _competentieNaamKort(String key) {
    // Puur voor de tijdlijn-labels (opsomming van geoefende skills per les).
    // NIET voor Examenadvies-categorisering — die komt volledig uit de RPC.
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

  // ── Kleine format-helpers ────────────────────────────────────────────────

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
    return '${_formatAantal(perWeek)} lessen per week';
  }

  static String _langeDatum(String datum) {
    final parsed = DateTime.tryParse(datum);
    if (parsed == null) return datum;
    const maanden = [
      'januari',
      'februari',
      'maart',
      'april',
      'mei',
      'juni',
      'juli',
      'augustus',
      'september',
      'oktober',
      'november',
      'december',
    ];
    return '${parsed.day} ${maanden[parsed.month - 1]} ${parsed.year}';
  }

  static String _formatAantal(double value) {
    final afgerond = value.roundToDouble();
    if ((value - afgerond).abs() < 0.05) return afgerond.toInt().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

// ── Empty-state (nooit een verzonnen percentage) ─────────────────────────────

const emptyVoortgangTrends = VoortgangTrendsData(
  isMock: true,
  huidigeScore: 0,
  heeftBetrouwbareScore: false,
  statusLabel: 'Nog onvoldoende data',
  ontwikkelingTekst: '',
  vorigeScore: 0,
  verschil: 0,
  sparkline: null,
  scoreHistorie: [],
  radarCategorieen: [
    CategorieScore(
        naam: 'Voertuigbeheersing',
        huidigOpVijf: null,
        trend: VaardigheidTrend.onbekend),
    CategorieScore(
        naam: 'Observatie',
        huidigOpVijf: null,
        trend: VaardigheidTrend.onbekend),
    CategorieScore(
        naam: 'Manoeuvres',
        huidigOpVijf: null,
        trend: VaardigheidTrend.onbekend),
    CategorieScore(
        naam: 'Verkeer',
        huidigOpVijf: null,
        trend: VaardigheidTrend.onbekend),
    CategorieScore(
        naam: 'Wegpositie',
        huidigOpVijf: null,
        trend: VaardigheidTrend.onbekend),
    CategorieScore(
        naam: 'Gedrag',
        huidigOpVijf: null,
        trend: VaardigheidTrend.onbekend),
  ],
  sterkeCompetenties: [],
  aandachtspunten: [],
  inzichten: [],
  lessenPerWeekLabel: 'Nog geen afgeronde lessen',
  tijdlijn: [],
);
