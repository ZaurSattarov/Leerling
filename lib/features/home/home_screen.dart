import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/nav_shell_tokens.dart';
import '../../core/services/push_service.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/home_header.dart';
import '../examenadvies/examenadvies_provider.dart';
import '../examenadvies/examenadvies_sparkline.dart';
import '../examenadvies/examenadvies_status_style.dart';
import '../lesvoorbereiding/lesvoorbereiding_provider.dart';
import 'home_coach_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Push-tap kan vuren vóór home zichtbaar is; retry zodra home mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.onAppResumed();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          ref.invalidate(examenadviesProvider);
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
            // Vaste hiërarchie: kerncijfers → volgende les → voorbereiding
            // → voortgang → examenadvies → (optioneel) urgente factuuractie.
            // Facturen krijgen hier bewust geen volledige lijst meer -- die
            // hoort in de Facturen-tab.
            homeAsync.when(
              data: (home) {
                final urgenteActie =
                    _bepaalUrgenteFactuurActie(home.openFacturen);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 20, 20, NavShellTokens.contentBottomClearance),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Kerncijfers
                      _StatsRow(
                        profielAsync: profielAsync,
                        homeAsync: homeAsync,
                      ),
                      const SizedBox(height: 24),

                      // Volgende les
                      SectionHeader(
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

                      // Voorbereiding volgende les (zelfde workflow als
                      // hierboven -- daarom direct eronder)
                      lesvoorbereidingAsync.when(
                        data: (data) => _LesvoorbereidingCard(
                          data: data,
                          onTap: () => context.push('/lesvoorbereiding'),
                        ),
                        loading: () => const SkeletonCard(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),

                      // Mijn voortgang (lespakket/lesvoortgang)
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

                      // Examenadvies (semantisch iets anders dan
                      // lesvoortgang -- eigen kaart, eigen scherm)
                      homeCoachAsync.when(
                        data: (coach) => _ExamenadviesHero(
                          data: coach,
                          onTap: () => context.push('/examenadvies'),
                        ),
                        loading: () => const _SkeletonHero(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Urgente factuuractie -- alleen wanneer een factuur
                      // echt actie vereist (verlopen, of vervalt binnen
                      // enkele dagen). Geen enkele kaart wanneer niet nodig.
                      if (urgenteActie != null) ...[
                        const SizedBox(height: 24),
                        _UrgenteFactuurCard(actie: urgenteActie),
                      ],
                    ]),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, NavShellTokens.contentBottomClearance),
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
//
// HomeHeader zelf staat in shared/widgets/home_header.dart (herbruikbaar,
// zelfde bouwpatroon als de andere gedeelde headers in shared/widgets/).
// Deze kleine wrapper leest alleen de twee providers uit en geeft de losse
// waarden door -- HomeHeader kent zelf geen Riverpod-afhankelijkheid.

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

    return HomeHeader(
      avatarUrl: profiel?.avatarUrl,
      naam: profiel?.voornaam ?? '',
      ongelezenNotificaties: home?.ongelezenNotificaties,
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
    final voortgangPct =
        profiel != null ? (profiel.voortgangPercent * 100).round() : 0;
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

// ── Volgende les hero card ────────────────────────────────────────────────────

class _VolgendeLesHero extends StatelessWidget {
  final Les les;
  final VoidCallback onTap;

  const _VolgendeLesHero({required this.les, required this.onTap});

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
            // Date block — flat, clean. Geen vaste hoogte: schaalt mee met
            // tekstschaal zonder ooit te overflowen (Impeccable: text moet
            // nooit zijn container overflowen).
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E2E7), width: 0.75),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DatumUtils.dagAfkorting(les.datum),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    DatumUtils.dagNummer(les.datum),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    DatumUtils.maandAfkorting(les.datum),
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
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lesvoorbereiding card ─────────────────────────────────────────────────────

class _LesvoorbereidingCard extends StatelessWidget {
  final PreparationViewModel? data;
  final VoidCallback onTap;

  const _LesvoorbereidingCard({required this.data, required this.onTap});

  // Kort, letterlijk-afgeleid onderschrift -- zelfde prioriteitsvolgorde
  // als het Lesvoorbereiding-scherm zelf (focus > aandacht > sterk >
  // feedback), puur ter identificatie welke voorbereiding klaarstaat.
  @override
  Widget build(BuildContext context) {
    final vm = data;
    final voorbereiding = vm?.preparationNote?.trim();
    // Alleen tonen als er echte canonical instructeurstekst is.
    // Geen skill-label, geen "Goede les", geen lege kaart.
    if (vm == null ||
        vm.emptyState == PreparationEmptyState.geenVolgendeLes ||
        voorbereiding == null ||
        voorbereiding.isEmpty) {
      return const SizedBox.shrink();
    }

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
                    voorbereiding,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
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
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
                Text(
                  'Examen',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Examenadvies hero ─────────────────────────────────────────────────────────
// Semantisch los van "Mijn voortgang" hierboven: dit is een examengereedheid-
// inschatting, geen lespakketvoortgang.

class _ExamenadviesHero extends StatelessWidget {
  final HomeCoachData data;
  final VoidCallback onTap;

  const _ExamenadviesHero({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = data.readinessScore;
    final toonScore = data.heeftBetrouwbareScore && score != null;
    final label = data.status;
    final labelColor = examenadviesStatusAccentVanLabel(label);
    const kaartGrijs = Color(0xFFF0F2F5);
    const badgeBorder = Color(0xFFE2E2E7);

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
                          value: toonScore ? score / 100 : 0,
                          strokeWidth: 6,
                          backgroundColor: kaartGrijs,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(labelColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        toonScore ? '$score%' : '—',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: kaartGrijs,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeBorder, width: 0.75),
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
                            Flexible(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            if (data.ontwikkeling != null &&
                data.ontwikkeling!.heeftChart) ...[
              const SizedBox(height: 12),
              ExamenadviesSparkline(data: data.ontwikkeling),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Urgente factuuractie ──────────────────────────────────────────────────────
// Verschijnt bewust ALLEEN wanneer een bestaande factuur echt actie vereist
// (verlopen, of vervalt binnen enkele dagen). Geen permanente factuursectie,
// geen nieuwe databron -- puur afgeleid van HomeData.openFacturen.

class _FactuurActie {
  final Factuur factuur;
  final bool isVerlopen;
  final int? dagenTotVervaldatum;
  final int aantalVerlopen;

  const _FactuurActie({
    required this.factuur,
    required this.isVerlopen,
    this.dagenTotVervaldatum,
    this.aantalVerlopen = 1,
  });
}

const _kUrgentieDrempelDagen = 3;

int? _dagenTotVervaldatum(String? vervaldatum) {
  if (vervaldatum == null || vervaldatum.trim().isEmpty) return null;
  try {
    final datum = DateTime.parse(vervaldatum);
    final vandaag = DateTime.now();
    final vandaagZonderTijd =
        DateTime(vandaag.year, vandaag.month, vandaag.day);
    final datumZonderTijd = DateTime(datum.year, datum.month, datum.day);
    return datumZonderTijd.difference(vandaagZonderTijd).inDays;
  } catch (_) {
    return null;
  }
}

_FactuurActie? _bepaalUrgenteFactuurActie(List<Factuur> facturen) {
  final verlopen = facturen.where((f) => f.isVerlopen).toList();
  if (verlopen.isNotEmpty) {
    return _FactuurActie(
      factuur: verlopen.first,
      isVerlopen: true,
      aantalVerlopen: verlopen.length,
    );
  }

  for (final f in facturen.where((f) => f.isOpen)) {
    final dagen = _dagenTotVervaldatum(f.vervaldatum);
    if (dagen != null && dagen >= 0 && dagen <= _kUrgentieDrempelDagen) {
      return _FactuurActie(
        factuur: f,
        isVerlopen: false,
        dagenTotVervaldatum: dagen,
      );
    }
  }

  return null;
}

class _UrgenteFactuurCard extends StatelessWidget {
  final _FactuurActie actie;

  const _UrgenteFactuurCard({required this.actie});

  @override
  Widget build(BuildContext context) {
    final f = actie.factuur;
    final kleur =
        actie.isVerlopen ? AppColors.dangerSolid : AppColors.warningSolid;

    final String titel;
    if (actie.isVerlopen) {
      titel = actie.aantalVerlopen > 1
          ? '${actie.aantalVerlopen} facturen verlopen'
          : 'Factuur is verlopen';
    } else {
      final dagen = actie.dagenTotVervaldatum ?? 0;
      titel = dagen == 0
          ? 'Factuur verloopt vandaag'
          : 'Factuur verloopt over $dagen dag${dagen == 1 ? '' : 'en'}';
    }
    final actieLabel = actie.isVerlopen ? 'Bekijk factuur' : 'Betaal factuur';

    return GestureDetector(
      onTap: () => actie.isVerlopen && actie.aantalVerlopen > 1
          ? context.go('/facturen')
          : context.push('/facturen/${f.id}'),
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
            IconBadge(
              icon: actie.isVerlopen
                  ? Icons.warning_rounded
                  : Icons.receipt_long_rounded,
              color: kleur,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f.beschrijving.isNotEmpty
                        ? f.beschrijving
                        : f.factuurnummer,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Flexible i.p.v. een vast formaat: garandeert dat de actielabel
            // nooit de kaart doet overflowen op smalle schermen/grote
            // tekstschaal -- de content links (Expanded) blijft leidend.
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      actieLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.textPrimary),
                ],
              ),
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
