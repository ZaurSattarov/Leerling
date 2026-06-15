import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/avatar_service.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_pill.dart';
import '../lesvoorbereiding/lesvoorbereiding_provider.dart';
import 'home_coach_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);
    final homeAsync = ref.watch(homeProvider);
    final homeCoachAsync = ref.watch(homeCoachProvider);
    final lesvoorbereidingAsync = ref.watch(lesvoorbereidingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        displacement: 80,
        onRefresh: () async {
          ref.invalidate(mijnProfielProvider);
          ref.invalidate(homeProvider);
          ref.invalidate(lesvoorbereidingProvider);
          ref.invalidate(homeCoachProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Gradient header (Instrecteur style) ──────────────────────────
            SliverToBoxAdapter(
              child: _GradientHeader(
                profielAsync: profielAsync,
                homeAsync: homeAsync,
              ),
            ),

            // ── Body content ─────────────────────────────────────────────────
            homeAsync.when(
              data: (home) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats bento
                    _StatsRow(
                      profielAsync: profielAsync,
                      homeAsync: homeAsync,
                    ),
                    const SizedBox(height: 24),

                    // Volgende les
                    _SectionLabel(
                      title: 'Volgende les',
                      action: 'Alle lessen',
                      onAction: () => context.go('/planning'),
                    ),
                    const SizedBox(height: 10),
                    home.heeftVolgendeLes
                        ? _VolgendeLesHero(
                            les: home.volgendeLes!,
                            onTap: () => context.go('/planning'),
                          )
                        : _GeenLesCard(),

                    const SizedBox(height: 24),

                    // Examenadvies
                    homeCoachAsync.when(
                      data: (coach) => _ExamenadviesHero(
                        data: coach,
                        onTap: () => context.push('/examenadvies'),
                      ),
                      loading: () => const _SkeletonHero(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Mijn voortgang
                    profielAsync.when(
                      data: (profiel) => profiel != null
                          ? _VoortgangCard(
                              profiel: profiel,
                              onTap: () => context.go('/voortgang'),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SkeletonCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Lesvoorbereiding
                    lesvoorbereidingAsync.when(
                      data: (data) => _LesvoorbereidingCard(
                        data: data,
                        onTap: () => context.push('/lesvoorbereiding'),
                      ),
                      loading: () => const SkeletonCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Open facturen
                    if (home.heeftOpenFacturen) ...[
                      const SizedBox(height: 24),
                      _SectionLabel(
                        title: 'Openstaande facturen',
                        action: 'Alle facturen',
                        onAction: () => context.go('/facturen'),
                      ),
                      const SizedBox(height: 10),
                      ...home.openFacturen.take(2).map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _FactuurRij(factuur: f),
                            ),
                          ),
                    ],

                  ]),
                ),
              ),
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _SkeletonHero(),
                    const SizedBox(height: 16),
                    const _SkeletonHero(),
                    const SizedBox(height: 16),
                    const SkeletonCard(),
                  ]),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Kon dashboard niet laden',
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

// ── Gradient header ───────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final AsyncValue<LeerlingProfiel?> profielAsync;
  final AsyncValue<HomeData> homeAsync;

  const _GradientHeader({
    required this.profielAsync,
    required this.homeAsync,
  });

  @override
  Widget build(BuildContext context) {
    final profiel = profielAsync.valueOrNull;
    final home = homeAsync.valueOrNull;
    final naam = profiel?.voornaam ?? '';
    final initials = naam.isNotEmpty ? naam[0].toUpperCase() : '?';
    final avatarUrl = profiel?.avatarUrl;
    final avatarAsset = AvatarService.assetPathFor(profiel?.avatarId);

    Widget avatarChild;
    if (avatarUrl?.isNotEmpty == true) {
      avatarChild = CachedNetworkImage(
        imageUrl: avatarUrl!,
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        placeholder: (_, __) => Center(
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
        errorWidget: (_, __, ___) => Center(
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
      );
    } else if (avatarAsset != null) {
      avatarChild = Image.asset(avatarAsset,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          errorBuilder: (_, __, ___) => Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ));
    } else {
      avatarChild = Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      );
    }

    return Container(
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
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipOval(
                child: Container(
                  width: 36,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.15),
                  child: avatarChild,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Dashboard',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    profielAsync.when(
                      data: (p) => Text(
                        naam.isNotEmpty ? 'Hoi, $naam.' : 'Welkom terug.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      loading: () => const SkeletonBox(
                          height: 28, width: 160, radius: 6),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Notification bell
              GestureDetector(
                onTap: () => context.go('/notificaties'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if ((home?.ongelezenNotificaties ?? 0) > 0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              '${home!.ongelezenNotificaties}',
                              style: const TextStyle(
                                color: AppColors.dark,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats bento row ───────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final AsyncValue<LeerlingProfiel?> profielAsync;
  final AsyncValue<HomeData> homeAsync;

  const _StatsRow({required this.profielAsync, required this.homeAsync});

  @override
  Widget build(BuildContext context) {
    final profiel = profielAsync.valueOrNull;
    final home = homeAsync.valueOrNull;
    final isLoading = profielAsync.isLoading || homeAsync.isLoading;

    if (isLoading) {
      return Row(
        children: [
          Expanded(child: SkeletonBox(height: 80, radius: 16)),
          const SizedBox(width: 10),
          Expanded(child: SkeletonBox(height: 80, radius: 16)),
          const SizedBox(width: 10),
          Expanded(child: SkeletonBox(height: 80, radius: 16)),
        ],
      );
    }

    final lessenGevolgd = profiel?.lessenGevolgd ?? 0;
    final lessenTotaal = profiel?.lessenTotaal ?? 0;
    final voortgangPct = profiel != null
        ? (profiel.voortgangPercent * 100).round()
        : 0;
    final openFacturen = home?.openFacturen.length ?? 0;
    final heeftFacturen = (home?.heeftOpenFacturen ?? false);

    return Row(
      children: [
        _StatCard(
          label: 'Lessen',
          value: '$lessenGevolgd/$lessenTotaal',
          icon: Icons.school_rounded,
          iconColor: AppColors.iconBlue,
          onTap: () => context.go('/planning'),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Voortgang',
          value: '$voortgangPct%',
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.iconGreen,
          onTap: () => context.go('/voortgang'),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Facturen',
          value: '$openFacturen',
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.iconDark,
          showBadge: heeftFacturen,
          onTap: () => context.go('/facturen'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool showBadge;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.showBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: iconColor),
                  ),
                  if (showBadge)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionLabel({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.textPrimary),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Volgende les hero card ────────────────────────────────────────────────────

class _VolgendeLesHero extends StatelessWidget {
  final Les les;
  final VoidCallback onTap;

  const _VolgendeLesHero({required this.les, required this.onTap});

  String _dagAfk(String datum) {
    try {
      const days = ['MAA', 'DIN', 'WOE', 'DON', 'VRI', 'ZAT', 'ZON'];
      return days[DateTime.parse(datum).weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String _dagNr(String datum) {
    try {
      return DateTime.parse(datum).day.toString();
    } catch (_) {
      return '?';
    }
  }

  String _maandAfk(String datum) {
    try {
      const m = [
        'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
        'jul', 'aug', 'sep', 'okt', 'nov', 'dec',
      ];
      return m[DateTime.parse(datum).month - 1];
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Row(
          children: [
            // Date block — flat, clean
            Container(
              width: 58,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE2E2E7), width: 0.75),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dagAfk(les.datum),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    _dagNr(les.datum),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    _maandAfk(les.datum),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFE2E2E7), width: 0.75),
                    ),
                    child: const Text(
                      'Volgende les',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${les.starttijd} — ${les.eindtijd}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (les.instructeurNaam?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          les.instructeurNaam!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (les.locatie?.isNotEmpty == true)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            les.locatie!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _GeenLesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_outlined,
                size: 22, color: AppColors.textHint),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geen lessen gepland',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Je instructeur plant binnenkort een les in.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Examenadvies hero ─────────────────────────────────────────────────────────

class _ExamenadviesHero extends StatelessWidget {
  final HomeCoachData data;
  final VoidCallback onTap;

  const _ExamenadviesHero({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = data.readinessScore;
    final label = score >= 85
        ? 'Examenklaar!'
        : score >= 60
            ? 'Bijna examenklaar'
            : 'In ontwikkeling';
    final labelColor = score >= 85
        ? AppColors.successSolid
        : score >= 60
            ? AppColors.warningSolid
            : AppColors.infoSolid;

    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          children: [
            // Circular progress
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFFF0F2F5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 85
                            ? AppColors.successSolid
                            : score >= 60
                                ? AppColors.warningSolid
                                : AppColors.infoSolid,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFE2E2E7), width: 0.75),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: labelColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Examenadvies',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.advies.isNotEmpty
                        ? data.advies
                        : 'Bekijk je examengereedheid',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Voortgang card ────────────────────────────────────────────────────────────

class _VoortgangCard extends StatelessWidget {
  final LeerlingProfiel profiel;
  final VoidCallback onTap;

  const _VoortgangCard({required this.profiel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = profiel.voortgangPercent;

    return GestureDetector(
      onTap: onTap,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.iconGreen,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mijn voortgang',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profiel.lessenGevolgd} van ${profiel.lessenTotaal} lessen · ${profiel.pakket.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: const Color(0xFFF0F2F5),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint),
                ),
                Text(
                  'Examen',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lesvoorbereiding card ─────────────────────────────────────────────────────

class _LesvoorbereidingCard extends StatelessWidget {
  final LesvoorbereidingData? data;
  final VoidCallback onTap;

  const _LesvoorbereidingCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            const IconBadge(
              icon: Icons.checklist_rounded,
              color: AppColors.iconPurple,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voorbereiding volgende les',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data!.focus.isNotEmpty
                        ? data!.focus
                        : 'Bekijk wat er wordt geoefend',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bekijk',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.textPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Factuur rij ───────────────────────────────────────────────────────────────

class _FactuurRij extends StatelessWidget {
  final Factuur factuur;
  const _FactuurRij({required this.factuur});

  @override
  Widget build(BuildContext context) {
    final isVerlopen = factuur.isVerlopen;
    final borderColor = isVerlopen ? AppColors.dangerSolid : AppColors.warningSolid;

    return GestureDetector(
      onTap: () => context.push('/facturen/${factuur.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.75),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    factuur.beschrijving.isNotEmpty
                        ? factuur.beschrijving
                        : factuur.factuurnummer,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    factuur.factuurnummer,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  factuur.bedragEuro,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                StatusPill.factuur(factuur.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ── Skeleton hero ─────────────────────────────────────────────────────────────

class _SkeletonHero extends StatelessWidget {
  const _SkeletonHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.75),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const SkeletonBox(height: 74, width: 74, radius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonBox(height: 12, width: 80, radius: 6),
                const SizedBox(height: 8),
                const SkeletonBox(height: 20, radius: 6),
                const SizedBox(height: 6),
                const SkeletonBox(height: 12, width: 140, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
