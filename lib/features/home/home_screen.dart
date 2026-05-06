import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';
import '../../models/notificatie.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/coach_widgets.dart';
import '../../shared/widgets/status_pill.dart';
import '../les_logboek/les_logboek_item.dart';
import '../les_logboek/les_logboek_provider.dart';
import '../lesvoorbereiding/lesvoorbereiding_provider.dart';
import 'home_coach_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);
    final homeAsync = ref.watch(homeProvider);
    final homeCoach = ref.watch(homeCoachProvider);
    final laatsteLesLogboekItemAsync = ref.watch(laatsteLesLogboekItemProvider);
    final lesvoorbereiding = ref.watch(lesvoorbereidingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(mijnProfielProvider);
          ref.invalidate(homeProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.dark,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: profielAsync.when(
                        data: (profiel) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoi, ${profiel?.voornaam ?? ''}! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DatumUtils.langeDatum(DatumUtils.vandaagString()),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SkeletonBox(height: 40, radius: 6),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/notificaties'),
                      child: homeAsync.when(
                        data: (home) => Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.dark2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 22),
                            ),
                            if (home.ongelezenNotificaties > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        loading: () => const SizedBox(width: 44, height: 44),
                        error: (_, __) => const SizedBox(width: 44, height: 44),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body content
            homeAsync.when(
              data: (home) => SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _CoachReadinessCard(data: homeCoach),

                    const SizedBox(height: 14),

                    laatsteLesLogboekItemAsync.when(
                      data: (item) => _LaatsteLesLogboekCard(item: item),
                      loading: () => const SkeletonCard(),
                      error: (_, __) =>
                          _LaatsteLesLogboekCard(item: mockLesLogboek.first),
                    ),

                    const SizedBox(height: 14),

                    _LesvoorbereidingCard(data: lesvoorbereiding),

                    const SizedBox(height: 24),

                    // Next lesson
                    SectionHeader(
                      title: 'Volgende les',
                      action: 'Alle lessen',
                      onAction: () => context.go('/planning'),
                    ),
                    const SizedBox(height: 12),
                    home.heeftVolgendeLes
                        ? _VolgendeLesCard(les: home.volgendeLes!)
                        : AppCard(
                            child: const EmptyState(
                              icon: Icons.calendar_today_outlined,
                              title: 'Geen lessen gepland',
                              subtitle:
                                  'Je instructeur heeft nog geen nieuwe les ingepland.',
                            ),
                          ),

                    const SizedBox(height: 24),

                    // Progress summary
                    profielAsync.when(
                      data: (profiel) => profiel != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Mijn voortgang',
                                  action: 'Details',
                                  onAction: () => context.go('/voortgang'),
                                ),
                                const SizedBox(height: 12),
                                AppCard(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const IconBadge(
                                            icon: Icons.bar_chart_rounded,
                                            color: Color(0xFF3B82F6),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${profiel.lessenGevolgd} van ${profiel.lessenTotaal} lessen gevolgd',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Pakket: ${profiel.pakket.label}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${(profiel.voortgangPercent * 100).round()}%',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(99),
                                        child: LinearProgressIndicator(
                                          value: profiel.voortgangPercent,
                                          minHeight: 8,
                                          backgroundColor:
                                              AppColors.borderLight,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SkeletonCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Open invoices
                    if (home.heeftOpenFacturen) ...[
                      SectionHeader(
                        title: 'Openstaande facturen',
                        action: 'Alle facturen',
                        onAction: () => context.go('/facturen'),
                      ),
                      const SizedBox(height: 12),
                      ...home.openFacturen.take(3).map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FactuurCard(factuur: f),
                            ),
                          ),
                    ],

                    // Recent notifications
                    if (home.recenteNotificaties.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Recente meldingen',
                        action: 'Alle meldingen',
                        onAction: () => context.go('/notificaties'),
                      ),
                      const SizedBox(height: 12),
                      ...home.recenteNotificaties.map(
                        (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NotificatieCard(notificatie: n),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SkeletonCard(),
                    const SizedBox(height: 12),
                    const SkeletonCard(),
                    const SizedBox(height: 12),
                    const SkeletonCard(),
                  ]),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const IconBadge(
                          icon: Icons.wifi_off_rounded,
                          color: AppColors.dangerSolid,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        const Text('Kon gegevens niet laden',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text(e.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(homeProvider),
                          child: const Text('Opnieuw proberen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LesvoorbereidingCard extends StatelessWidget {
  final LesvoorbereidingData data;

  const _LesvoorbereidingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(
                icon: Icons.center_focus_strong_rounded,
                color: AppColors.dark3,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voorbereiding volgende les',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.focus,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.voorbereiding,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          InlineCtaLink(
            label: 'Bekijk voorbereiding',
            onPressed: () => context.push('/lesvoorbereiding'),
          ),
        ],
      ),
    );
  }
}

class _LaatsteLesLogboekCard extends StatelessWidget {
  final LesLogboekItem item;

  const _LaatsteLesLogboekCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.history_edu_rounded,
                color: AppColors.dark3,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laatste les',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.datumLabel}  ·  ${item.tijdLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.onderwerpen
                .map((label) => NeutralChip(label: label))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            item.feedback,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          InlineCtaLink(
            label: 'Bekijk logboek',
            onPressed: () => context.push('/les-logboek'),
          ),
        ],
      ),
    );
  }
}

class _CoachReadinessCard extends StatelessWidget {
  final HomeCoachData data;

  const _CoachReadinessCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(
                icon: Icons.school_rounded,
                color: AppColors.dark3,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ben ik klaar voor examen?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.status,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.successText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${data.readinessScore}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AccentProgressBar(value: data.readinessScore / 100),
          const SizedBox(height: 16),
          _CoachInfoRow(
            icon: Icons.flag_rounded,
            iconColor: AppColors.infoSolid,
            label: data.advies,
          ),
          const SizedBox(height: 10),
          _CoachInfoRow(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.successSolid,
            label: data.feedback,
          ),
          const SizedBox(height: 16),
          const Text(
            'Laatst geoefend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.laatstGeoefend
                .map((label) => NeutralChip(label: label))
                .toList(),
          ),
          const SizedBox(height: 14),
          InlineCtaLink(
            label: 'Bekijk examenadvies',
            onPressed: () => context.push('/examenadvies'),
          ),
        ],
      ),
    );
  }
}

class _CoachInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _CoachInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VolgendeLesCard extends StatelessWidget {
  final Les les;
  const _VolgendeLesCard({required this.les});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/planning/${les.id}'),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DatumUtils.relatiefDatum(les.datum),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${les.starttijd} – ${les.eindtijd}  ·  ${DatumUtils.duurLabel(les.duurMinuten)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                if (les.locatie?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    les.locatie!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          StatusPill.les(les.status),
        ],
      ),
    );
  }
}

class _FactuurCard extends StatelessWidget {
  final Factuur factuur;
  const _FactuurCard({required this.factuur});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/facturen/${factuur.id}'),
      child: Row(
        children: [
          IconBadge(
            icon: Icons.receipt_long_rounded,
            color: factuur.isVerlopen
                ? AppColors.dangerSolid
                : AppColors.warningSolid,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  factuur.factuurnummer,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              StatusPill.factuur(factuur.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificatieCard extends StatelessWidget {
  final Notificatie notificatie;
  const _NotificatieCard({required this.notificatie});

  IconData get _icon {
    switch (notificatie.type) {
      case 'les':
      case 'les_reminder':
        return Icons.directions_car_rounded;
      case 'voorbereiding':
        return Icons.task_alt_rounded;
      case 'feedback':
        return Icons.rate_review_rounded;
      case 'factuur':
        return Icons.receipt_long_rounded;
      case 'voortgang':
      case 'examenadvies':
        return Icons.bar_chart_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (notificatie.type) {
      case 'les':
      case 'les_reminder':
        return AppColors.infoSolid;
      case 'voorbereiding':
        return AppColors.dark3;
      case 'feedback':
        return AppColors.successSolid;
      case 'factuur':
        return AppColors.warningSolid;
      case 'voortgang':
      case 'examenadvies':
        return AppColors.successSolid;
      default:
        return AppColors.dark3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(notificatie.targetRoute),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: _icon, color: _color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificatie.titel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        notificatie.gelezen ? FontWeight.w500 : FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (notificatie.tekst?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    notificatie.tekst!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (!notificatie.gelezen)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4, left: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
