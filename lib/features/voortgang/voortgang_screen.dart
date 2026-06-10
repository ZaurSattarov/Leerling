import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/coach_widgets.dart';
import '../../shared/widgets/screen_header.dart';
import 'lespakket_voortgang_provider.dart';
import 'voortgang_provider.dart';
import 'voortgang_trends_provider.dart';

const List<Color> _competentieKleuren = [
  Color(0xFF0F172A),
  Color(0xFF0F172A),
  Color(0xFF0F172A),
  Color(0xFF0F172A),
  Color(0xFF0F172A),
  Color(0xFF0F172A),
];

class VoortgangScreen extends ConsumerWidget {
  const VoortgangScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);
    final lespakketAsync = ref.watch(lespakketVoortgangProvider);
    final trendsAsync = ref.watch(voortgangTrendsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(mijnProfielProvider);
          ref.invalidate(lespakketVoortgangProvider);
          ref.invalidate(voortgangTrendsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.dark,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 110,
              actions: [
                GestureDetector(
                  onTap: () => context.go('/notificaties'),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, top: 10),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.dark2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.fromLTRB(20, 0, 64, 16),
                title: ScreenHeader(
                    label: 'VOORTGANG', title: 'Mijn voortgang'),
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
                      lespakketAsync.when(
                        data: (data) => data != null
                            ? _TotaleVoortgangCard(data: data)
                            : _TotaleVoortgangCard(
                                data:
                                    LespakketVoortgangData.fromProfielEnLessen(
                                  profiel: profiel,
                                  lessen: const [],
                                ),
                              ),
                        loading: () => const SkeletonBox(
                          height: 200,
                          radius: 18,
                        ),
                        error: (_, __) => _TotaleVoortgangCard(
                          data: LespakketVoortgangData.fromProfielEnLessen(
                            profiel: profiel,
                            lessen: const [],
                          ),
                        ),
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

class _TotaleVoortgangCard extends StatelessWidget {
  final LespakketVoortgangData data;

  const _TotaleVoortgangCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final total =
        data.afgerondeLessen + data.geplandeLessen + data.nogInTePlannen;

    return GestureDetector(
      onTap: () => context.push('/voortgang/lespakket'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(18),
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
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'lessen gevolgd',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.dark2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DarkStat(
                      label: 'AFGEROND',
                      value: '${data.afgerondeLessen}',
                      valueColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _DarkStat(
                      label: 'GEPLAND',
                      value: '${data.geplandeLessen}',
                      valueColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: _DarkStat(
                      label: 'RESTEREND',
                      value: '${data.nogInTePlannen}',
                      valueColor: Colors.white,
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

class _DarkStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DarkStat({
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

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
      final zwakste = data.competenties
          .where((c) => c.verschil <= 0)
          .toList();
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

    final minScore =
        points.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final maxScore =
        points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    final range =
        (maxScore - minScore).abs() < 8 ? 8 : maxScore - minScore;
    final usableHeight = size.height - 32;
    final stepX =
        points.length == 1 ? 0.0 : size.width / (points.length - 1);

    Offset offsetFor(int index) {
      final score = points[index].score;
      final normalized = (score - minScore) / range;
      return Offset(
          index * stepX, usableHeight - normalized * usableHeight);
    }

    final path = Path()..moveTo(offsetFor(0).dx, offsetFor(0).dy);
    for (var i = 1; i < points.length; i++) {
      final previous = offsetFor(i - 1);
      final current = offsetFor(i);
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(
          midX, previous.dy, midX, current.dy, current.dx, current.dy);
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
  final int index;

  const _CompetentieCard({required this.score, required this.index});

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
                icon: Icons.adjust_rounded,
                color: _competentieKleuren[index % _competentieKleuren.length],
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
              Text(
                '${(score.percentage * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
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
