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
    final homeCoachAsync = ref.watch(homeCoachProvider);
    final laatsteLesLogboekItemAsync = ref.watch(laatsteLesLogboekItemProvider);
    final lesvoorbereidingAsync = ref.watch(lesvoorbereidingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(mijnProfielProvider);
          ref.invalidate(homeProvider);
          ref.invalidate(lesvoorbereidingProvider);
          ref.invalidate(laatsteLesLogboekItemProvider);
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
                              DatumUtils.langeDatum(DatumUtils.vandaagString())
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hoi, ${profiel?.voornaam ?? ''}.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Klaar voor de volgende rit?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.dark2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 20),
                            ),
                            if (home.ongelezenNotificaties > 0)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  width: 9,
                                  height: 9,
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
                    homeCoachAsync.when(
                      data: (coachData) =>
                          _CoachReadinessCard(data: coachData),
                      loading: () => const SkeletonCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 14),

                    laatsteLesLogboekItemAsync.when(
                      data: (item) => item != null
                          ? _LaatsteLesLogboekCard(item: item)
                          : const SizedBox.shrink(),
                      loading: () => const SkeletonCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 14),

                    lesvoorbereidingAsync.when(
                      data: (data) => _LesvoorbereidingCard(data: data),
                      loading: () => const SkeletonCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXAMENADVIES',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ben je klaar voor het examen?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
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
                    '${data.readinessScore}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    data.status.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: data.readinessScore / 100,
              minHeight: 7,
              backgroundColor: AppColors.dark3,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.35))),
              Text('EXAMEN — 80%',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.35))),
            ],
          ),
          const SizedBox(height: 14),
          _DarkCoachRow(
            icon: Icons.flag_rounded,
            label: 'FOCUSPUNT',
            text: data.advies,
          ),
          const SizedBox(height: 10),
          _DarkCoachRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'VORIGE FEEDBACK',
            text: data.feedback,
          ),
          const SizedBox(height: 16),
          Text(
            'LAATST GEOEFEND',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.laatstGeoefend
                .map((label) => _DarkChip(label: label))
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/examenadvies'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bekijk examenadvies',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkCoachRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _DarkCoachRow(
      {required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DarkChip extends StatelessWidget {
  final String label;

  const _DarkChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.dark3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
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
            color: factuur.status == FactuurStatus.betaald
                ? AppColors.successSolid
                : factuur.isVerlopen
                    ? AppColors.dangerSolid
                    : factuur.status == FactuurStatus.geannuleerd
                        ? AppColors.dark3
                        : AppColors.primary,
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
      case 'lesson_planned':
      case 'lesson_changed':
        return Icons.directions_car_rounded;
      case 'voorbereiding':
        return Icons.task_alt_rounded;
      case 'feedback':
      case 'lesson_feedback':
        return Icons.rate_review_rounded;
      case 'factuur':
      case 'invoice_created':
      case 'invoice_paid':
        return Icons.receipt_long_rounded;
      case 'package_almost_empty':
        return Icons.inventory_2_rounded;
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
      case 'lesson_planned':
      case 'lesson_changed':
        return AppColors.infoSolid;
      case 'voorbereiding':
        return AppColors.dark3;
      case 'feedback':
      case 'lesson_feedback':
      case 'invoice_paid':
        return AppColors.successSolid;
      case 'factuur':
      case 'invoice_created':
      case 'package_almost_empty':
        return AppColors.primary;
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
