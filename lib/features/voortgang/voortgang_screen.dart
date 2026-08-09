import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_tab_header.dart';
import 'lespakket_voortgang_provider.dart';
import 'voortgang_provider.dart';
import 'voortgang_trends_provider.dart';

// ── Semantische kleuren (geen pastel) ─────────────────────────────────────────

const _groen = Color(0xFF16A34A);
const _oranje = Color(0xFFD97706);
const _blauw = Color(0xFF2563EB);
const _rood = Color(0xFFE11D48);
const _mutedSurface = Color(0xFFF0F2F5);
const _softSurface = Color(0xFFF8F8FA);

const _screenPadding = 20.0;
const _sectionGap = 24.0;
const _sectionTitleGap = 12.0;
const _cardPadding = 16.0;
const _cardRadius = 16.0;

// ── Hoofd scherm ──────────────────────────────────────────────────────────────

class VoortgangScreen extends ConsumerWidget {
  const VoortgangScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);
    final lespakketAsync = ref.watch(lespakketVoortgangProvider);
    final trendsAsync = ref.watch(voortgangTrendsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainTabHeader(
            title: 'Mijn voortgang',
            actions: [
              MainHeaderIconKnop(
                icon: Icons.notifications_outlined,
                onTap: () => context.go('/notificaties'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(mijnProfielProvider);
                ref.invalidate(lespakketVoortgangProvider);
                ref.invalidate(voortgangTrendsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  profielAsync.when(
                    data: (profiel) {
                      if (profiel == null) {
                        return const SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.person_off_outlined,
                            title: 'Geen profiel gevonden',
                          ),
                        );
                      }

                      final vaardigheden =
                          profiel.vaardigheden ?? <String, dynamic>{};
                      final competentieScores = cbrCompetenties
                          .map((c) => _CompetentieScore.fromVaardigheden(
                                competentie: c,
                                vaardigheden: vaardigheden,
                              ))
                          .toList();

                      return SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          _screenPadding,
                          16,
                          _screenPadding,
                          MediaQuery.paddingOf(context).bottom + 96,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // 1. Lespakket voortgang kaart
                            lespakketAsync.when(
                              data: (data) => data != null
                                  ? _TotaleVoortgangCard(data: data)
                                  : _TotaleVoortgangCard(
                                      data: LespakketVoortgangData
                                          .fromProfielEnLessen(
                                        profiel: profiel,
                                        lessen: const [],
                                      ),
                                    ),
                              loading: () =>
                                  const SkeletonBox(height: 200, radius: 18),
                              error: (_, __) => _TotaleVoortgangCard(
                                data:
                                    LespakketVoortgangData.fromProfielEnLessen(
                                  profiel: profiel,
                                  lessen: const [],
                                ),
                              ),
                            ),
                            const SizedBox(height: _sectionTitleGap),

                            // 2. Examen readiness + motivatie
                            trendsAsync.when(
                              data: (trends) =>
                                  _ExamenReadinessCard(trends: trends),
                              loading: () =>
                                  const SkeletonBox(height: 120, radius: 18),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: _sectionGap),

                            // 3. CBR competenties — radar chart
                            const SectionHeader(title: 'CBR-competenties'),
                            const SizedBox(height: _sectionTitleGap),
                            trendsAsync.when(
                              data: (trends) => _CbrRadarCard(
                                competentieScores: competentieScores,
                                radarWaarden: trends.radarWaarden,
                              ),
                              loading: () =>
                                  const SkeletonBox(height: 280, radius: 18),
                              error: (_, __) => _CbrRadarCard(
                                competentieScores: competentieScores,
                                radarWaarden: List.filled(6, 0.0),
                              ),
                            ),
                            const SizedBox(height: _sectionTitleGap),

                            // 4. Sterke punten + aandachtspunten
                            trendsAsync.when(
                              data: (trends) =>
                                  _SterkAandachtRow(trends: trends),
                              loading: () =>
                                  const SkeletonBox(height: 100, radius: 18),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: _sectionGap),

                            // 5. Wat verandert er? — dynamische inzichten
                            const SectionHeader(title: 'Wat verandert er?'),
                            const SizedBox(height: _sectionTitleGap),
                            trendsAsync.when(
                              data: (trends) => _InzichtenCard(trends: trends),
                              loading: () => const SkeletonCard(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: _sectionTitleGap),

                            // 6. Score lijn chart + stats
                            trendsAsync.when(
                              data: (trends) => _ScoreChartCard(trends: trends),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: _sectionGap),

                            // 7. Tijdlijn
                            const SectionHeader(title: 'Voortgang tijdlijn'),
                            const SizedBox(height: _sectionTitleGap),
                            trendsAsync.when(
                              data: (trends) =>
                                  _TijdlijnCard(items: trends.tijdlijn),
                              loading: () => const SkeletonCard(),
                              error: (_, __) => const _TijdlijnCard(items: []),
                            ),
                          ]),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        _screenPadding,
                        16,
                        _screenPadding,
                        MediaQuery.paddingOf(context).bottom + 96,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SkeletonBox(height: 200, radius: 18),
                          const SizedBox(height: 14),
                          const SkeletonCard(),
                          const SizedBox(height: 10),
                          const SkeletonBox(height: 280, radius: 18),
                          const SizedBox(height: 10),
                          const SkeletonCard(),
                        ]),
                      ),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Kon voortgang niet laden',
                        subtitle: e.toString(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lespakket voortgang kaart (ongewijzigd) ───────────────────────────────────

class _TotaleVoortgangCard extends StatelessWidget {
  final LespakketVoortgangData data;
  const _TotaleVoortgangCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final totaal = data.totaalLessen;
    final percentage = data.percentageLabel;
    final voortgangZin = totaal > 0
        ? '${data.afgerondeLessen} van $totaal lessen, $percentage% afgerond'
        : 'Geen lespakket ingesteld';

    return Semantics(
      button: true,
      label:
          '$voortgangZin. ${data.afgerondeLessen} afgerond, ${data.geplandeLessen} gepland, ${data.nogInTePlannen} resterend.',
      child: AppCard(
        onTap: () => context.push('/voortgang/lespakket'),
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pakketvoortgang',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totaal > 0
                            ? '${data.afgerondeLessen} van $totaal lessen'
                            : '${data.afgerondeLessen} lessen',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$percentage% afgerond',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (data.heeftPakket) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.pakketLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: data.percentageAfgerond.clamp(0.0, 1.0),
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _mutedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Afgerond',
                        value: '${data.afgerondeLessen}',
                        valueColor: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _StatPill(
                        label: 'Gepland',
                        value: '${data.geplandeLessen}',
                        valueColor: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: _StatPill(
                        label: 'Resterend',
                        value: '${data.nogInTePlannen}',
                        valueColor: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Examen readiness card ─────────────────────────────────────────────────────

class _ExamenReadinessCard extends StatelessWidget {
  final VoortgangTrendsData trends;
  const _ExamenReadinessCard({required this.trends});

  Color get _scoreColor {
    if (trends.huidigeScore >= 100) return _groen;
    if (trends.huidigeScore >= 50) return _oranje;
    return _rood;
  }

  String get _readinessLabel {
    if (trends.huidigeScore >= 85) return 'Klaar voor examen';
    if (trends.huidigeScore >= 70) return 'Bijna examenklaar';
    if (trends.huidigeScore >= 50) return 'Goed op weg';
    return 'Nog meer oefenen';
  }

  @override
  Widget build(BuildContext context) {
    final trendLabel = trends.verschil == 0
        ? 'Geen vorige meting'
        : '${trends.verschil > 0 ? '+' : ''}${trends.verschil}% sinds vorige meting';

    return Semantics(
      label:
          'Examenadvies ${trends.huidigeScore} procent. $_readinessLabel. $trendLabel.',
      child: AppCard(
        padding: const EdgeInsets.all(_cardPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Examenadvies',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trends.huidigeScore}%',
                        style: TextStyle(
                          color: _scoreColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            _readinessLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  trends.verschil == 0
                      ? const _NeutralBadge(label: 'Geen vorige meting')
                      : _DeltaChip(verschil: trends.verschil),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CircularProgressWidget(
              value: trends.huidigeScore / 100,
              color: _scoreColor,
              size: 64,
              showLabel: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ── CBR Radar chart card ──────────────────────────────────────────────────────

class _CbrRadarCard extends StatelessWidget {
  final List<_CompetentieScore> competentieScores;
  final List<double> radarWaarden;

  const _CbrRadarCard({
    required this.competentieScores,
    required this.radarWaarden,
  });

  @override
  Widget build(BuildContext context) {
    final labels = cbrCompetenties.map(_radarLabelVoor).toList();
    final effectiefWaarden = radarWaarden.length == 6
        ? radarWaarden
        : competentieScores.map((s) => s.percentage).toList();
    final samenvatting = competentieScores
        .map((score) =>
            '${score.competentie.naam} ${(score.percentage * 100).round()} procent')
        .join(', ');

    return Semantics(
      label: 'CBR competenties. $samenvatting.',
      child: AppCard(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = min(constraints.maxWidth, 260.0);
                return Center(
                  child: SizedBox.square(
                    dimension: chartSize,
                    child: CustomPaint(
                      painter: _RadarChartPainter(
                        waarden: effectiefWaarden,
                        labels: labels,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Column(
              children: competentieScores.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: entry.key == 0 ? 0 : 10,
                  ),
                  child: _CompetentieProgressRow(score: entry.value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

String _radarLabelVoor(CbrCompetentie competentie) {
  return switch (competentie.naam) {
    'Voertuigbeheersing' => 'Voertuig',
    'Kijkgedrag' => 'Kijkgedrag',
    'Verkeersinzicht' => 'Inzicht',
    'Bijzondere verrichtingen' => 'Verrichtingen',
    'Zelfstandig rijden' => 'Zelfstandig',
    'Examenvoorbereiding' => 'Examen',
    _ => competentie.naam,
  };
}

class _CompetentieProgressRow extends StatelessWidget {
  final _CompetentieScore score;
  const _CompetentieProgressRow({required this.score});

  Color get _kleur {
    if (score.percentage >= 0.8) return _groen;
    if (score.percentage >= 0.5) return _oranje;
    return _rood;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (score.percentage * 100).round();
    return Semantics(
      label: '${score.competentie.naam}: $pct procent.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: _kleur,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  score.competentie.naam,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _kleur,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: score.percentage.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_kleur),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> waarden;
  final List<String> labels;

  const _RadarChartPainter({required this.waarden, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.62;
    final n = waarden.length;
    if (n == 0) return;

    // Grid ringen
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E2E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 3; ring++) {
      final r = radius * ring / 3;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -pi / 2 + i * 2 * pi / n;
        final pt =
            Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Assen
    final axisPaint = Paint()
      ..color = const Color(0xFFE2E2E7)
      ..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * 2 * pi / n;
      final end = Offset(
          center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(center, end, axisPaint);
    }

    // Data vlak
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * 2 * pi / n;
      final r = radius * waarden[i].clamp(0.0, 1.0);
      final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        dataPath.moveTo(pt.dx, pt.dy);
      } else {
        dataPath.lineTo(pt.dx, pt.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Punten
    final dotPaint = Paint()..color = AppColors.primary;
    final dotBgPaint = Paint()..color = Colors.white;
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * 2 * pi / n;
      final r = radius * waarden[i].clamp(0.0, 1.0);
      final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      canvas.drawCircle(pt, 5, dotBgPaint);
      canvas.drawCircle(pt, 4, dotPaint);
    }

    // Labels
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * 2 * pi / n;
      final labelRadius = radius * 1.22;
      final labelCenter = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      final pct = (waarden[i] * 100).round();
      final kortLabel = labels[i];

      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$kortLabel\n',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            TextSpan(
              text: '$pct%',
              style: TextStyle(
                color: pct >= 100
                    ? _groen
                    : pct >= 50
                        ? _oranje
                        : _rood,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 60);

      textPainter.paint(
        canvas,
        Offset(
          (labelCenter.dx - textPainter.width / 2)
              .clamp(0, size.width - textPainter.width),
          (labelCenter.dy - textPainter.height / 2)
              .clamp(0, size.height - textPainter.height),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) =>
      old.waarden != waarden;
}

// ── Competentie legenda item ──────────────────────────────────────────────────

// ── Sterk / aandacht rij ──────────────────────────────────────────────────────

class _SterkAandachtRow extends StatelessWidget {
  final VoortgangTrendsData trends;
  const _SterkAandachtRow({required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.sterkeCompetenties.isEmpty && trends.aandachtspunten.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trends.sterkeCompetenties.isNotEmpty)
          Expanded(
            child: _PuntenKaart(
              titel: 'Sterke punten',
              icoon: Icons.check_rounded,
              kleur: _groen,
              punten: trends.sterkeCompetenties,
            ),
          ),
        if (trends.sterkeCompetenties.isNotEmpty &&
            trends.aandachtspunten.isNotEmpty)
          const SizedBox(width: 10),
        if (trends.aandachtspunten.isNotEmpty)
          Expanded(
            child: _PuntenKaart(
              titel: 'Aandachtspunten',
              icoon: Icons.flag_rounded,
              kleur: _oranje,
              punten: trends.aandachtspunten,
            ),
          ),
      ],
    );
  }
}

class _PuntenKaart extends StatelessWidget {
  final String titel;
  final IconData icoon;
  final Color kleur;
  final List<String> punten;

  const _PuntenKaart({
    required this.titel,
    required this.icoon,
    required this.kleur,
    required this.punten,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppColors.border, width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icoon, color: kleur, size: 16),
              const SizedBox(width: 6),
              Text(
                titel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...punten.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icoon == Icons.check_rounded
                          ? Icons.check_circle_rounded
                          : Icons.flag_circle_rounded,
                      color: kleur,
                      size: 14,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Inzichten card ────────────────────────────────────────────────────────────

class _InzichtenCard extends StatelessWidget {
  final VoortgangTrendsData trends;
  const _InzichtenCard({required this.trends});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trends.inzichten.isEmpty)
            const Text(
              'Volg meer lessen om inzichten te zien.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
          else
            ...trends.inzichten.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(
                      bottom: entry.key < trends.inzichten.length - 1 ? 12 : 0),
                  child: _InzichtRij(item: entry.value),
                )),
        ],
      ),
    );
  }
}

class _InzichtRij extends StatelessWidget {
  final InzichtItem item;
  const _InzichtRij({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.titel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.oudeWaarde != null && item.nieuweWaarde != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${item.oudeWaarde} → ${item.nieuweWaarde}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (item.waarde != null) ...[
                const SizedBox(height: 3),
                Text(
                  item.waarde!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (item.delta != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E2E7)),
            ),
            child: Text(
              item.delta!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: item.deltaColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Score lijn chart card ─────────────────────────────────────────────────────

class _ScoreChartCard extends StatelessWidget {
  final VoortgangTrendsData trends;
  const _ScoreChartCard({required this.trends});

  Color get _trendColor {
    if (trends.verschil > 0) return _groen;
    if (trends.verschil < 0) return _rood;
    return _blauw;
  }

  IconData get _trendIcon {
    if (trends.verschil > 0) return Icons.trending_up_rounded;
    if (trends.verschil < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: _trendIcon, color: _trendColor, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Examenadviestrend',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trends.scoreHistorie.length >= 2
                          ? 'Vorige, huidig en verschil'
                          : 'Nog niet genoeg meetpunten voor een lijn',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: trends.trendLabel,
                color: _trendColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (trends.scoreHistorie.length >= 2)
            SizedBox(
              height: 110,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(trends.scoreHistorie),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: _mutedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                trends.scoreHistorie.isEmpty
                    ? 'Nog geen meetpunten beschikbaar.'
                    : 'Eén meetpunt beschikbaar: ${trends.huidigeScore}%.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Vorige',
                  value: '${trends.vorigeScore}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Huidig',
                  value: '${trends.huidigeScore}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Verschil',
                  value:
                      '${trends.verschil >= 0 ? '+' : ''}${trends.verschil}%',
                  valueColor: _trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rijke tijdlijn card ───────────────────────────────────────────────────────

class _TijdlijnCard extends StatelessWidget {
  final List<LesTijdlijnItem> items;
  const _TijdlijnCard({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppCard(
        child: EmptyState(
          icon: Icons.timeline_rounded,
          title: 'Nog geen tijdlijn',
          subtitle: 'Afgeronde lessen verschijnen hier.',
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return _TijdlijnRij(item: entry.value, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _TijdlijnRij extends StatelessWidget {
  final LesTijdlijnItem item;
  final bool isLast;

  const _TijdlijnRij({required this.item, required this.isLast});

  IconData get _eventIcon {
    return switch (item.eventType) {
      'beoordeling' => Icons.grade_rounded,
      'aandachtspunt' => Icons.flag_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
  }

  String get _eventLabel {
    return switch (item.eventType) {
      'beoordeling' => 'Beoordeling',
      'aandachtspunt' => 'Aandachtspunt',
      _ => 'Les afgerond',
    };
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tijdlijn staaf
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F5),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(_eventIcon, color: AppColors.textPrimary, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE2E2E7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _eventLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (item.beoordelingLabel != 'Geen beoordeling')
                        _BeoordelingBadge(label: item.beoordelingLabel),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Datum + tijd + lestype
                  Text(
                    '${item.datumLabel} · ${item.tijdLabel}'
                    '${item.lesType != null ? ' · ${item.lesType}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // Competentie verbeteringen
                  if (item.verbeteringen.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _mutedSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children:
                            item.verbeteringen.asMap().entries.map((entry) {
                          return Padding(
                            padding:
                                EdgeInsets.only(top: entry.key == 0 ? 0 : 6),
                            child: _TijdlijnScoreRij(score: entry.value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Geoefende onderwerpen
                  if (item.onderwerpen.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Geoefend',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.onderwerpen.join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],

                  // Instructeur feedback
                  if (item.feedback.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Opmerking',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _softSurface,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.border, width: 0.75),
                      ),
                      child: Text(
                        item.feedback,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gedeelde hulpwidgets ──────────────────────────────────────────────────────

class _TijdlijnScoreRij extends StatelessWidget {
  final CompetentieDelta score;
  const _TijdlijnScoreRij({required this.score});

  Color get _kleur {
    if (score.delta >= 80) return _groen;
    if (score.delta >= 50) return _oranje;
    return _rood;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            score.naam,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            '${score.delta}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _kleur,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _BeoordelingBadge extends StatelessWidget {
  final String label;
  const _BeoordelingBadge({required this.label});

  Color get _kleur {
    return switch (label) {
      '5/5' || 'Goed' => _groen,
      '4/5' || 'Voldoende' => _oranje,
      _ => _rood,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7), width: 0.75),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kleur,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _NeutralBadge extends StatelessWidget {
  final String label;
  const _NeutralBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _mutedSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final int verschil;
  const _DeltaChip({required this.verschil});

  @override
  Widget build(BuildContext context) {
    final isPositief = verschil > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositief
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 10,
            color: isPositief ? _groen : _rood,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositief ? '+' : ''}$verschil%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isPositief ? _groen : _rood,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: valueColor,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MiniStat({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: valueColor)),
        ],
      ),
    );
  }
}

// ── CustomPainters ────────────────────────────────────────────────────────────

class _CircularProgressWidget extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  final bool showLabel;

  const _CircularProgressWidget({
    required this.value,
    this.color = AppColors.primary,
    this.size = 90,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(value: value, color: color),
          ),
          if (showLabel)
            Center(
              child: Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double value;
  final Color color;

  const _CircularProgressPainter({
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFEAECF0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    final sweepAngle = 2 * pi * value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.value != value || old.color != color;
}

class _LineChartPainter extends CustomPainter {
  final List<TrendPoint> points;
  _LineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 12.0;
    const right = 12.0;
    const top = 16.0;
    const bottom = 22.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()..color = AppColors.primary;

    canvas.drawLine(Offset(left, size.height - bottom),
        Offset(size.width - right, size.height - bottom), axisPaint);
    if (points.isEmpty) return;

    final minScore = points.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final maxScore = points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    final range = (maxScore - minScore).abs() < 8 ? 8 : maxScore - minScore;
    final stepX = points.length == 1 ? 0.0 : chartWidth / (points.length - 1);

    Offset offsetFor(int index) {
      final score = points[index].score;
      final normalized = (score - minScore) / range;
      return Offset(
        left + index * stepX,
        top + chartHeight - normalized * chartHeight,
      );
    }

    final path = Path()..moveTo(offsetFor(0).dx, offsetFor(0).dy);
    for (var i = 1; i < points.length; i++) {
      final previous = offsetFor(i - 1);
      final current = offsetFor(i);
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(offsetFor(points.length - 1).dx, size.height - bottom)
      ..lineTo(offsetFor(0).dx, size.height - bottom)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final offset = offsetFor(i);
      canvas.drawCircle(offset, 3.5, dotPaint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${points[i].score}%',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (offset.dx - textPainter.width / 2)
              .clamp(0, size.width - textPainter.width),
          (offset.dy - 16).clamp(0, size.height - 26),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.points != points;
}

// ── CompetentieScore helper ───────────────────────────────────────────────────

class _CompetentieScore {
  final CbrCompetentie competentie;
  final double percentage;

  const _CompetentieScore({
    required this.competentie,
    required this.percentage,
  });

  factory _CompetentieScore.fromVaardigheden({
    required CbrCompetentie competentie,
    required Map<String, dynamic> vaardigheden,
  }) {
    final scores = competentie.vaardigheidKeys
        .map((key) => (vaardigheden[key] as num? ?? 0).toDouble())
        .where((score) => score > 0)
        .toList();
    final gemiddeld =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    return _CompetentieScore(
      competentie: competentie,
      percentage: (gemiddeld / 5.0).clamp(0.0, 1.0),
    );
  }
}
