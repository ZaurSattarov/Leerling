import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
<<<<<<< Updated upstream
import '../../shared/widgets/screen_header.dart';
=======
import '../../shared/widgets/coach_widgets.dart';
import '../../shared/widgets/main_tab_header.dart';
>>>>>>> Stashed changes
import 'lespakket_voortgang_provider.dart';
import 'voortgang_provider.dart';
import 'voortgang_trends_provider.dart';

// ── Semantische kleuren (geen pastel) ─────────────────────────────────────────

const _groen = Color(0xFF16A34A);
const _oranje = Color(0xFFD97706);
const _blauw = Color(0xFF2563EB);
const _paars = Color(0xFF5645D4);
const _rood = Color(0xFFE11D48);

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
<<<<<<< Updated upstream
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(mijnProfielProvider);
          ref.invalidate(lespakketVoortgangProvider);
          ref.invalidate(voortgangTrendsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF141C2B), Color(0xFF1A2D42)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: ScreenHeader(
                            label: 'VOORTGANG',
                            title: 'Mijn voortgang',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/notificaties'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.notifications_none_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
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
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Lespakket voortgang kaart
                      lespakketAsync.when(
                        data: (data) => data != null
                            ? _TotaleVoortgangCard(data: data)
                            : _TotaleVoortgangCard(
=======
      body: Column(
        children: [
          MainTabHeader(
            eyebrowText: 'VOORTGANG',
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
                          .map((competentie) =>
                              _CompetentieScore.fromVaardigheden(
                                competentie: competentie,
                                vaardigheden: vaardigheden,
                              ))
                          .toList();

                      return SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
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
                              loading: () => const SkeletonBox(
                                height: 200,
                                radius: 18,
                              ),
                              error: (_, __) => _TotaleVoortgangCard(
>>>>>>> Stashed changes
                                data:
                                    LespakketVoortgangData.fromProfielEnLessen(
                                  profiel: profiel,
                                  lessen: const [],
                                ),
                              ),
<<<<<<< Updated upstream
                        loading: () =>
                            const SkeletonBox(height: 200, radius: 18),
                        error: (_, __) => _TotaleVoortgangCard(
                          data: LespakketVoortgangData.fromProfielEnLessen(
                            profiel: profiel,
                            lessen: const [],
                          ),
=======
                            ),
                            const SizedBox(height: 16),
                            trendsAsync.when(
                              data: (trends) => _DezeWeekCard(data: trends),
                              loading: () => const SkeletonCard(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),
                            const SectionHeader(title: 'CBR-competenties'),
                            const SizedBox(height: 12),
                            ...competentieScores.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _CompetentieCard(
                                        score: entry.value, index: entry.key),
                                  ),
                                ),
                            const SizedBox(height: 10),
                            const SectionHeader(title: 'Voortgang in de tijd'),
                            const SizedBox(height: 12),
                            trendsAsync.when(
                              data: (trends) =>
                                  _VoortgangTrendsSection(data: trends),
                              loading: () => const SkeletonCard(),
                              error: (_, __) => const _VoortgangTrendsSection(
                                  data: emptyVoortgangTrends),
                            ),
                            const SizedBox(height: 16),
                          ]),
>>>>>>> Stashed changes
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SkeletonBox(height: 200, radius: 18),
                          const SizedBox(height: 14),
                          const SkeletonCard(),
                          const SizedBox(height: 10),
                          const SkeletonCard(),
                          const SizedBox(height: 10),
                          const SkeletonCard(),
                        ]),
                      ),
<<<<<<< Updated upstream
                      const SizedBox(height: 12),

                      // 2. Examen readiness + motivatie
                      trendsAsync.when(
                        data: (trends) =>
                            _ExamenReadinessCard(trends: trends),
                        loading: () =>
                            const SkeletonBox(height: 120, radius: 18),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),

                      // 3. CBR competenties — radar chart
                      const SectionHeader(title: 'CBR-competenties'),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),

                      // 4. Sterke punten + aandachtspunten
                      trendsAsync.when(
                        data: (trends) => _SterkAandachtRow(trends: trends),
                        loading: () =>
                            const SkeletonBox(height: 100, radius: 18),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),

                      // 5. Wat verandert er? — dynamische inzichten
                      const SectionHeader(title: 'Wat verandert er?'),
                      const SizedBox(height: 12),
                      trendsAsync.when(
                        data: (trends) => _InzichtenCard(trends: trends),
                        loading: () => const SkeletonCard(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),

                      // 6. Score lijn chart + stats
                      trendsAsync.when(
                        data: (trends) => trends.scoreHistorie.length >= 2
                            ? _ScoreChartCard(trends: trends)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),

                      // 7. Tijdlijn
                      const SectionHeader(title: 'Voortgang tijdlijn'),
                      const SizedBox(height: 12),
                      trendsAsync.when(
                        data: (trends) =>
                            _TijdlijnCard(items: trends.tijdlijn),
                        loading: () => const SkeletonCard(),
                        error: (_, __) =>
                            const _TijdlijnCard(items: []),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(20),
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
=======
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
>>>>>>> Stashed changes
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
    final total = data.afgerondeLessen + data.geplandeLessen + data.nogInTePlannen;
    return GestureDetector(
      onTap: () => context.push('/voortgang/lespakket'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.75),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CircularProgressWidget(value: data.percentageAfgerond),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.pakketLabel.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total' == '0'
                            ? '${data.afgerondeLessen}'
                            : '${data.afgerondeLessen}/$total',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        'lessen gevolgd',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      label: 'AFGEROND',
                      value: '${data.afgerondeLessen}',
                      valueColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _StatPill(
                      label: 'GEPLAND',
                      value: '${data.geplandeLessen}',
                      valueColor: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _StatPill(
                      label: 'RESTEREND',
                      value: '${data.nogInTePlannen}',
                      valueColor: AppColors.textPrimary,
                    ),
                  ),
                ],
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(72, 72),
                  painter: _CircularProgressPainter(
                    value: trends.huidigeScore / 100,
                    color: _scoreColor,
                  ),
                ),
                Center(
                  child: Text(
                    '${trends.huidigeScore}%',
                    style: TextStyle(
                      color: _scoreColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusChip(
                      label: _readinessLabel,
                      color: _scoreColor,
                    ),
                    const SizedBox(width: 8),
                    if (trends.verschil != 0)
                      _DeltaChip(verschil: trends.verschil),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  trends.motivatieTekst,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final labels = cbrCompetenties.map((c) => c.naam).toList();
    final effectiefWaarden = radarWaarden.length == 6
        ? radarWaarden
        : competentieScores.map((s) => s.percentage).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Radar chart
          SizedBox(
            height: 230,
            width: double.infinity,
            child: CustomPaint(
              painter: _RadarChartPainter(
                waarden: effectiefWaarden,
                labels: labels,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legenda
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: competentieScores.asMap().entries.map((entry) {
              return _CompetentieLegendaItem(score: entry.value);
            }).toList(),
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
        final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
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
      final pt =
          Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
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
      final pt =
          Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
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
      final competentieNaam = labels[i];
      // Shorten label for radar display
      final kortLabel = _kortLabel(competentieNaam);

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
                color: pct >= 100 ? _groen : pct >= 50 ? _oranje : _rood,
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
          (labelCenter.dx - textPainter.width / 2).clamp(0, size.width - textPainter.width),
          (labelCenter.dy - textPainter.height / 2)
              .clamp(0, size.height - textPainter.height),
        ),
      );
    }
  }

  String _kortLabel(String naam) {
    return switch (naam) {
      'Voertuigbeheersing' => 'Voertuig',
      'Kijkgedrag' => 'Kijken',
      'Verkeersinzicht' => 'Verkeer',
      'Bijzondere verrichtingen' => 'Verricht.',
      'Zelfstandig rijden' => 'Zelfst.',
      'Examenvoorbereiding' => 'Examen',
      _ => naam.length > 8 ? naam.substring(0, 7) : naam,
    };
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) =>
      old.waarden != waarden;
}

// ── Competentie legenda item ──────────────────────────────────────────────────

class _CompetentieLegendaItem extends StatelessWidget {
  final _CompetentieScore score;
  const _CompetentieLegendaItem({required this.score});

  Color get _kleur {
    if (score.percentage >= 1.0) return _groen;
    if (score.percentage >= 0.5) return _oranje;
    return _rood;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (score.percentage * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _kleur,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            score.competentie.naam,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kleur,
            ),
          ),
        ],
      ),
    );
  }
}

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
              titel: 'Sterk',
              icoon: Icons.star_rounded,
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
              titel: 'Aandacht',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kleur,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...punten.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 5, right: 7),
                      decoration: BoxDecoration(
                        color: kleur,
                        shape: BoxShape.circle,
                      ),
                    ),
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
          if (trends.lesAdvies.isNotEmpty) ...[
            const Divider(height: 20),
            _InzichtRij(
              item: InzichtItem(
                icon: Icons.lightbulb_outline_rounded,
                iconColor: _paars,
                tekst: trends.lesAdvies,
              ),
            ),
          ],
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
                item.tekst,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                      'Examenadvies trend',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trends.uitleg,
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
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(trends.scoreHistorie),
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
              Expanded(
                child: _MiniStat(
                  label: 'Huidig',
                  value: '${trends.huidigeScore}%',
                ),
              ),
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
                  child: Icon(_eventIcon, color: AppColors.textPrimary, size: 14),
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
                  // Event label + beoordeling badge
                  Row(
                    children: [
                      Text(
                        _eventLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      if (item.beoordelingLabel != 'Geen beoordeling')
                        _BeoordelingBadge(label: item.beoordelingLabel),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Datum + tijd + lestype
                  Text(
                    '${item.datumLabel} · ${item.tijdLabel}'
                    '${item.lesType != null ? ' · ${item.lesType}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Competentie verbeteringen
                  if (item.verbeteringen.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.verbeteringen.map((v) {
                        final kleur = v.delta >= 100
                            ? _groen
                            : v.delta >= 50
                                ? _oranje
                                : _rood;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFE2E2E7), width: 0.75),
                          ),
                          child: Text(
                            '${v.naam} ${v.delta}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: kleur,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Geoefende onderwerpen
                  if (item.onderwerpen.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Geoefend: ${item.onderwerpen.join(', ')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],

                  // Instructeur feedback
                  if (item.feedback.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE2E2E7), width: 0.75),
                      ),
                      child: Text(
                        item.feedback,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
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
            isPositief ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
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
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

<<<<<<< Updated upstream
=======
class _CircularProgressWidget extends StatelessWidget {
  final double value;

  const _CircularProgressWidget({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(90, 90),
            painter: _CircularProgressPainter(value: value),
          ),
          Center(
            child: Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
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

  const _CircularProgressPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = AppColors.dark3
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = AppColors.primary
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
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _DezeWeekCard extends StatelessWidget {
  final VoortgangTrendsData data;

  const _DezeWeekCard({required this.data});

  String get _titel {
    if (!data.heeftHistorie) return 'Start met je eerste lessen';
    if (data.verschil > 0) return 'Je bent goed op weg';
    if (data.verschil < 0) return 'Extra oefenen loont';
    return 'Stabiele voortgang';
  }

  String get _advies {
    if (!data.heeftHistorie) {
      return 'Volg meer lessen zodat we je voortgang kunnen bijhouden.';
    }
    if (data.competenties.isNotEmpty) {
      final zwakste = data.competenties.where((c) => c.verschil <= 0).toList();
      if (zwakste.isNotEmpty) {
        return 'Focus op ${zwakste.first.naam.toLowerCase()} voor meer verbetering.';
      }
      return '${data.competenties.first.naam} gaat goed, blijf oefenen.';
    }
    return data.beoordelingTrend;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.iconDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEZE WEEK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _titel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _advies,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoortgangTrendsSection extends StatelessWidget {
  final VoortgangTrendsData data;

  const _VoortgangTrendsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TrendSamenvattingCard(data: data),
        const SizedBox(height: 14),
        _TrendDetailsCard(data: data),
        const SizedBox(height: 14),
        _TijdlijnCard(items: data.tijdlijn),
      ],
    );
  }
}

class _TrendSamenvattingCard extends StatelessWidget {
  final VoortgangTrendsData data;

  const _TrendSamenvattingCard({required this.data});

  Color get _trendColor {
    if (data.verschil > 0) return AppColors.successSolid;
    if (data.verschil < 0) return AppColors.dangerSolid;
    return AppColors.infoSolid;
  }

  IconData get _trendIcon {
    if (data.verschil > 0) return Icons.trending_up_rounded;
    if (data.verschil < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: _trendIcon, color: _trendColor, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Examenadvies trend',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.uitleg,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _TrendBadge(label: data.trendLabel, color: _trendColor),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 118,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(data.scoreHistorie),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Vorige score',
                  value: '${data.vorigeScore}%',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Huidige score',
                  value: '${data.huidigeScore}%',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Verschil',
                  value: '${data.verschil >= 0 ? '+' : ''}${data.verschil}%',
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

class _TrendDetailsCard extends StatelessWidget {
  final VoortgangTrendsData data;

  const _TrendDetailsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wat verandert er?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _TrendInfoRow(
            icon: Icons.grade_rounded,
            label: 'Beoordelingen',
            value: data.gemiddeldeBeoordeling == null
                ? 'Nog onvoldoende data'
                : '${data.gemiddeldeBeoordeling!.toStringAsFixed(1)} / 3 gemiddeld',
            subtitle: data.beoordelingTrend,
          ),
          const SizedBox(height: 12),
          _TrendInfoRow(
            icon: Icons.checklist_rounded,
            label: 'Competenties',
            value: data.competentieTrend,
            subtitle: data.competenties.isEmpty
                ? 'Scores per les worden getoond zodra ze beschikbaar zijn.'
                : data.competenties
                    .map((c) =>
                        '${c.naam}: ${c.vorigeScore}% -> ${c.huidigeScore}%')
                    .take(2)
                    .join(' · '),
          ),
          const SizedBox(height: 12),
          _TrendInfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Lesritme',
            value: data.lessenPerWeekLabel,
            subtitle: 'Gebaseerd op zichtbare afgeronde lessen.',
          ),
        ],
      ),
    );
  }
}

class _TijdlijnCard extends StatelessWidget {
  final List<LesTijdlijnItem> items;

  const _TijdlijnCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tijdlijn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.take(5).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TimelineItem(item: item),
                ),
              ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final LesTijdlijnItem item;

  const _TimelineItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.datumLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _TrendBadge(
                    label: item.beoordelingLabel,
                    color: AppColors.dark3,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item.feedback,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.competentieLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _TrendInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: icon, color: AppColors.dark3, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

>>>>>>> Stashed changes
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
      margin: const EdgeInsets.only(right: 8),
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
  const _CircularProgressWidget({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(90, 90),
            painter: _CircularProgressPainter(value: value),
          ),
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

    canvas.drawLine(Offset(0, size.height - 18),
        Offset(size.width, size.height - 18), axisPaint);
    if (points.isEmpty) return;

<<<<<<< Updated upstream
    final minScore =
        points.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final maxScore =
        points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
=======
    final minScore = points.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final maxScore = points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
>>>>>>> Stashed changes
    final range = (maxScore - minScore).abs() < 8 ? 8 : maxScore - minScore;
    final usableHeight = size.height - 32;
    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);

    Offset offsetFor(int index) {
      final score = points[index].score;
      final normalized = (score - minScore) / range;
      return Offset(index * stepX, usableHeight - normalized * usableHeight);
    }

    final path = Path()..moveTo(offsetFor(0).dx, offsetFor(0).dy);
    for (var i = 1; i < points.length; i++) {
      final previous = offsetFor(i - 1);
      final current = offsetFor(i);
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(offsetFor(points.length - 1).dx, size.height - 18)
      ..lineTo(offsetFor(0).dx, size.height - 18)
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
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points;
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
