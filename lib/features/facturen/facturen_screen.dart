import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/nav_shell_tokens.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/factuur.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_tab_header.dart';
import '../../shared/widgets/status_pill.dart';
import 'facturen_provider.dart';

// ── Kleurconstanten ───────────────────────────────────────────────────────────
// Gebruik dezelfde semantische kleuren als voortgang_screen.dart.
// Alleen voor status-indicatoren, NIET voor waarden of bedragen.

const _groenStatus = Color(0xFF16A34A); // Betaald
const _roodWaarschuwing = Color(0xFFDC2626); // Verlopen
const _oranjeWaarschuwing = Color(0xFFF59E0B); // Openstaand
const _ringNeutraal = Color(0xFFE4E7EC); // Donut achtergrond ring

// ── Hoofd scherm ──────────────────────────────────────────────────────────────

class FacturenScreen extends ConsumerStatefulWidget {
  const FacturenScreen({super.key});

  @override
  ConsumerState<FacturenScreen> createState() => _FacturenScreenState();
}

class _FacturenScreenState extends ConsumerState<FacturenScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _chartAnim;
  late final TabController _tabCtrl;

  static const _tabs = ['Alle', 'Open', 'Betaald', 'Verlopen'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _chartAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _startAnim() {
    if (!_animCtrl.isCompleted) _animCtrl.forward();
  }

  List<Factuur> _filterFacturen(List<Factuur> all, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return all.where((f) => f.isOpen && !f.isVerlopen).toList();
      case 2:
        return all.where((f) => f.status == FactuurStatus.betaald).toList();
      case 3:
        return all.where((f) => f.isVerlopen).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final facturenAsync = ref.watch(facturenProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainTabHeader(
            title: 'Mijn facturen',
            actions: [
              MainHeaderIconKnop(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.go('/notificaties'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                _animCtrl.reset();
                ref.invalidate(facturenProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // Content
                  facturenAsync.when(
                    data: (facturen) {
                      if (facturen.isEmpty) {
                        return const SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Geen facturen',
                            subtitle: 'Je hebt nog geen facturen ontvangen.',
                          ),
                        );
                      }

                      final stats = _FactuurStats.van(facturen);
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _startAnim());

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 20, 20, NavShellTokens.contentBottomClearance),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // 1. Finance overzicht kaart
                            _FinanceOverzichtKaart(stats: stats),
                            const SizedBox(height: 12),

                            // 2. Status verdeling
                            _DonutChartKaart(
                                stats: stats, animation: _chartAnim),
                            const SizedBox(height: 24),

                            // 3. Facturenlijst
                            const SectionHeader(title: 'Alle facturen'),
                            const SizedBox(height: 12),
                            ...facturen.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FactuurCard(factuur: f),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 20, 20, NavShellTokens.contentBottomClearance),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SkeletonBox(height: 148, radius: 18),
                          const SizedBox(height: 12),
                          const SkeletonBox(height: 190, radius: 18),
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
                        title: 'Kon facturen niet laden',
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

// ── Stats model ───────────────────────────────────────────────────────────────

class _FactuurStats {
  final int totaalAantal;
  final int betaaldAantal;
  final int openstaandAantal;
  final int verlopenAantal;
  final int betaaldCents;
  final int openstaandCents;
  final String? eerstVolgendeVervaldag;

  const _FactuurStats({
    required this.totaalAantal,
    required this.betaaldAantal,
    required this.openstaandAantal,
    required this.verlopenAantal,
    required this.betaaldCents,
    required this.openstaandCents,
    required this.eerstVolgendeVervaldag,
  });

  factory _FactuurStats.van(List<Factuur> facturen) {
    final betaald = facturen.where((f) => f.status == FactuurStatus.betaald);
    final openstaand = facturen.where((f) => f.isOpen);
    final verlopen = facturen.where((f) => f.isVerlopen);

    final vervaldata = facturen
        .where((f) => f.isBetaalbaar && f.vervaldatum?.isNotEmpty == true)
        .map((f) => f.vervaldatum!)
        .where((d) {
      try {
        return DateTime.parse(d).isAfter(DateTime.now());
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort();

    return _FactuurStats(
      totaalAantal: facturen.length,
      betaaldAantal: betaald.length,
      openstaandAantal: openstaand.length,
      verlopenAantal: verlopen.length,
      betaaldCents: betaald.fold(0, (s, f) => s + f.bedragCents),
      openstaandCents: (openstaand.toList() + verlopen.toList())
          .fold(0, (s, f) => s + f.bedragCents),
      eerstVolgendeVervaldag: vervaldata.isNotEmpty ? vervaldata.first : null,
    );
  }

  String bedragLabel(int cents) {
    final euros = cents / 100;
    if (euros >= 1000) {
      return '€ ${euros.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }
    return '€ ${euros.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get openstaandLabel => bedragLabel(openstaandCents);
  String get betaaldLabel => bedragLabel(betaaldCents);
}

// ── Finance overzicht kaart ───────────────────────────────────────────────────

class _FinanceOverzichtKaart extends StatelessWidget {
  final _FactuurStats stats;
  const _FinanceOverzichtKaart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final heeftVervaldatum = stats.eerstVolgendeVervaldag != null;
    final vervalLabel = heeftVervaldatum
        ? DatumUtils.korteDatum(stats.eerstVolgendeVervaldag!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
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
          // Kaart header — zelfde patroon als voortgang kaarten
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Financieel overzicht',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Twee rijen stats
          Row(
            children: [
              Expanded(
                child: _OverzichtStat(
                  label: 'Openstaand',
                  waarde: stats.openstaandLabel,
                  icon: Icons.schedule_rounded,
                  accentKleur:
                      stats.openstaandCents > 0 ? AppColors.primary : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverzichtStat(
                  label: 'Betaald',
                  waarde: stats.betaaldLabel,
                  icon: Icons.check_circle_outline_rounded,
                  accentKleur: stats.betaaldCents > 0 ? _groenStatus : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OverzichtStat(
                  label: 'Facturen',
                  waarde: '${stats.totaalAantal}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverzichtStat(
                  label: 'Vervaldatum',
                  waarde: vervalLabel,
                  icon: Icons.event_outlined,
                  accentKleur: heeftVervaldatum ? _roodWaarschuwing : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Stat cel — waarde altijd donker navy, label altijd grijs.
// accentKleur: alleen voor het icoon bij uitzonderingen.
class _OverzichtStat extends StatelessWidget {
  final String label;
  final String waarde;
  final IconData icon;
  final Color? accentKleur;

  const _OverzichtStat({
    required this.label,
    required this.waarde,
    required this.icon,
    this.accentKleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: accentKleur ?? AppColors.textHint,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Waarde altijd donker — geen gekleurde bedragen
          Text(
            waarde,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donut chart kaart ─────────────────────────────────────────────────────────

class _DonutChartKaart extends StatelessWidget {
  final _FactuurStats stats;
  final Animation<double> animation;

  const _DonutChartKaart({required this.stats, required this.animation});

  @override
  Widget build(BuildContext context) {
    final totaal =
        stats.betaaldAantal + stats.openstaandAantal + stats.verlopenAantal;
    if (totaal == 0) return const SizedBox.shrink();

    // Segmenten: betaald licht groen, openstaand rood, verlopen donker rood.
    // Geen oranje — max 2 kleuren voor rust.
    final segmenten = [
      if (stats.betaaldAantal > 0)
        _DonutSegment(
          waarde: stats.betaaldAantal / totaal,
          kleur: _groenStatus,
          label: 'Betaald',
          aantal: stats.betaaldAantal,
          statusKleur: _groenStatus,
        ),
      if (stats.openstaandAantal > 0)
        _DonutSegment(
          waarde: stats.openstaandAantal / totaal,
          kleur: _oranjeWaarschuwing,
          label: 'Openstaand',
          aantal: stats.openstaandAantal,
          statusKleur: _oranjeWaarschuwing,
        ),
      if (stats.verlopenAantal > 0)
        _DonutSegment(
          waarde: stats.verlopenAantal / totaal,
          kleur: _roodWaarschuwing,
          label: 'Verlopen',
          aantal: stats.verlopenAantal,
          statusKleur: _roodWaarschuwing,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Factuurstatus verdeling',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => CustomPaint(
                    painter: _DonutPainter(
                      segmenten: segmenten,
                      voortgang: animation.value,
                      totalAantal: totaal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legenda
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: segmenten
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LegendeRij(segment: s),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  final double waarde;
  final Color kleur;
  final String label;
  final int aantal;
  final Color statusKleur;

  const _DonutSegment({
    required this.waarde,
    required this.kleur,
    required this.label,
    required this.aantal,
    required this.statusKleur,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segmenten;
  final double voortgang;
  final int totalAantal;

  _DonutPainter({
    required this.segmenten,
    required this.voortgang,
    required this.totalAantal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 16.0;
    const gap = 0.04;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Achtergrond ring — altijd neutraal lichtgrijs
    final bgPaint = Paint()
      ..color = _ringNeutraal
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    double startAngle = -pi / 2;
    final totalBoog = 2 * pi * voortgang;

    for (final seg in segmenten) {
      final segBoog = (totalBoog * seg.waarde) - gap;
      if (segBoog <= 0) continue;

      final paint = Paint()
        ..color = seg.kleur
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, segBoog, false, paint);
      startAngle += segBoog + gap;
    }

    // Getal in midden — zelfde stijl als voortgang radar
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$totalAantal\n',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const TextSpan(
            text: 'facturen',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.voortgang != voortgang;
}

class _LegendeRij extends StatelessWidget {
  final _DonutSegment segment;
  const _LegendeRij({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gekleurde stip — enige plek waar de segmentkleur gebruikt wordt
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: segment.statusKleur,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            segment.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Count badge — zelfde stijl als rest van de app (wit + border)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E2E7)),
          ),
          child: Text(
            '${segment.aantal}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Factuur kaart ─────────────────────────────────────────────────────────────

class _FactuurCard extends StatelessWidget {
  final Factuur factuur;
  const _FactuurCard({required this.factuur});

  // Icon kleur: semantisch maar ingetogen.
  // Verlopen = rood (echte waarschuwing), betaald = groen, rest = neutraal.
  Color get _iconKleur {
    if (factuur.isVerlopen) return _roodWaarschuwing;
    if (factuur.status == FactuurStatus.betaald) return _groenStatus;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/facturen/${factuur.id}'),
      child: Row(
        children: [
          // Icoon container — 40×40, borderRadius 12, zelfde als voortgang
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: _iconKleur,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),

          // Tekst info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factuur.beschrijving.isNotEmpty
                      ? factuur.beschrijving
                      : factuur.factuurnummer,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  factuur.factuurnummer,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                if (factuur.vervaldatum?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 11,
                        color: DatumUtils.isVerlopen(factuur.vervaldatum)
                            ? _roodWaarschuwing
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        DatumUtils.korteDatum(factuur.vervaldatum!),
                        style: TextStyle(
                          fontSize: 11,
                          color: DatumUtils.isVerlopen(factuur.vervaldatum)
                              ? _roodWaarschuwing
                              : AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Bedrag + status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                factuur.bedragEuro,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              StatusPill.factuur(factuur.status),
            ],
          ),
        ],
      ),
    );
  }
}
