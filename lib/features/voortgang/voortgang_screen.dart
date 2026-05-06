import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/coach_widgets.dart';
import 'voortgang_provider.dart';
import 'voortgang_trends_provider.dart';

class VoortgangScreen extends ConsumerWidget {
  const VoortgangScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);
    final trendsAsync = ref.watch(voortgangTrendsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(mijnProfielProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.dark,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 110,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Text(
                  'Mijn Voortgang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
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
                final beoordeeld = vaardigheden.values
                    .where((v) => (v as num? ?? 0) > 0)
                    .length;
                final totaal = vaardighedenLabels.length;
                final competentieScores = cbrCompetenties
                    .map((competentie) => _CompetentieScore.fromVaardigheden(
                          competentie: competentie,
                          vaardigheden: vaardigheden,
                        ))
                    .toList();

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _VoortgangSamenvattingCard(),
                      const SizedBox(height: 14),
                      _TotaleVoortgangCard(
                        lessenGevolgd: profiel.lessenGevolgd,
                        lessenTotaal: profiel.lessenTotaal,
                        voortgangPercent: profiel.voortgangPercent,
                        beoordeeld: beoordeeld,
                        totaal: totaal,
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'CBR-competenties'),
                      const SizedBox(height: 12),
                      ...competentieScores.map(
                        (score) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CompetentieCard(score: score),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SectionHeader(title: 'Voortgang in de tijd'),
                      const SizedBox(height: 12),
                      trendsAsync.when(
                        data: (trends) => _VoortgangTrendsSection(data: trends),
                        loading: () => const SkeletonCard(),
                        error: (_, __) => const _VoortgangTrendsSection(
                            data: mockVoortgangTrends),
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
                    const SkeletonBox(height: 130, radius: 18),
                    const SizedBox(height: 14),
                    const SkeletonCard(),
                    const SizedBox(height: 10),
                    const SkeletonCard(),
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
    if (data.verschil < 0) return AppColors.warningSolid;
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
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TrendBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
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
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()..color = AppColors.primary;

    canvas.drawLine(Offset(0, size.height - 18),
        Offset(size.width, size.height - 18), axisPaint);
    if (points.isEmpty) return;

    final minScore = points.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final maxScore = points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
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
      canvas.drawCircle(offset, 4, dotPaint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${points[i].score}%',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
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
          (offset.dy - 18).clamp(0, size.height - 28),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _VoortgangSamenvattingCard extends StatelessWidget {
  const _VoortgangSamenvattingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.trending_up_rounded,
            color: AppColors.dark3,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Je bent goed op weg',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Focus deze week op zelfstandig rijden en kijkgedrag.',
                  style: TextStyle(
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

class _TotaleVoortgangCard extends StatelessWidget {
  final int lessenGevolgd;
  final int lessenTotaal;
  final double voortgangPercent;
  final int beoordeeld;
  final int totaal;

  const _TotaleVoortgangCard({
    required this.lessenGevolgd,
    required this.lessenTotaal,
    required this.voortgangPercent,
    required this.beoordeeld,
    required this.totaal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Totale voortgang',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '$lessenGevolgd / $lessenTotaal lessen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: voortgangPercent,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$beoordeeld van $totaal vaardigheden beoordeeld',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '${(voortgangPercent * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetentieScore {
  final CbrCompetentie competentie;
  final double percentage;
  final String status;
  final String uitleg;

  const _CompetentieScore({
    required this.competentie,
    required this.percentage,
    required this.status,
    required this.uitleg,
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
    final percentage = (gemiddeld / 5.0).clamp(0.0, 1.0);

    return _CompetentieScore(
      competentie: competentie,
      percentage: percentage,
      status: competentie.statusVoor(percentage),
      uitleg: competentie.uitlegVoor(percentage),
    );
  }
}

class _CompetentieCard extends StatelessWidget {
  final _CompetentieScore score;

  const _CompetentieCard({required this.score});

  Color get _statusColor {
    if (score.percentage >= 0.8) return AppColors.successSolid;
    if (score.percentage >= 0.5) return AppColors.infoSolid;
    return AppColors.warningSolid;
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
              IconBadge(
                icon: Icons.checklist_rounded,
                color: _statusColor,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.competentie.naam,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.uitleg,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(score.percentage * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _CompetentieStatusPill(
                    label: score.status,
                    color: _statusColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AccentProgressBar(value: score.percentage),
        ],
      ),
    );
  }
}

class _CompetentieStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CompetentieStatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
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
