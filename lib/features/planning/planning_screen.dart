import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_tab_header.dart';
import 'planning_provider.dart';
import 'widgets/lesson_status_badge.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainTabHeader(
            title: 'Mijn lessen',
            actions: [MainHeaderNotificatieKnop()],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: AnimatedBuilder(
              animation: _tabs,
              builder: (_, __) => _PillTabBar(
                activeIndex: _tabs.index,
                labels: const ['Komende lessen', 'Afgerond'],
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  _tabs.animateTo(i);
                },
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _LessenTab(provider: komendeLessenProvider, isKomend: true),
                _LessenTab(provider: vorigeLessenProvider, isKomend: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTabBar extends StatelessWidget {
  final int activeIndex;
  final List<String> labels;
  final void Function(int) onTap;

  const _PillTabBar({
    required this.activeIndex,
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E2E7), width: 0.75),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == activeIndex;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minHeight: 40),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      height: 1,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LessenTab extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<Les>>> provider;
  final bool isKomend;

  const _LessenTab({required this.provider, required this.isKomend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessenAsync = ref.watch(provider);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listPadding = EdgeInsets.fromLTRB(20, 20, 20, 96 + safeBottom);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        HapticFeedback.selectionClick();
        ref.invalidate(komendeLessenProvider);
        ref.invalidate(vorigeLessenProvider);
      },
      child: lessenAsync.when(
        data: (lessen) {
          final total = lessen.length + (isKomend ? 1 : 0);

          if (lessen.isEmpty) {
            return ListView(
              padding: listPadding,
              children: [
                _PlanningEmptyState(isKomend: isKomend),
                if (isKomend) ...[
                  const SizedBox(height: 14),
                  const _NieuweLesButton(),
                ],
              ],
            );
          }

          return ListView.separated(
            padding: listPadding,
            itemCount: total,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == lessen.length) {
                return const _NieuweLesButton();
              }
              return _LessonCard(
                les: lessen[i],
                isNext: isKomend && i == 0,
                showCompletedSummary: !isKomend,
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: listPadding,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const _PlanningSkeletonCard(),
        ),
        error: (e, _) => ListView(
          padding: listPadding,
          children: [
            EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Kon lessen niet laden',
              subtitle: e.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningEmptyState extends StatelessWidget {
  final bool isKomend;

  const _PlanningEmptyState({required this.isKomend});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isKomend
                  ? Icons.event_available_outlined
                  : Icons.fact_check_outlined,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isKomend ? 'Geen komende lessen' : 'Nog geen afgeronde lessen',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isKomend
                ? 'Zodra je instructeur een les plant, verschijnt die hier automatisch.'
                : 'Afgeronde lessen met zichtbare evaluatie verschijnen hier.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NieuweLesButton extends StatelessWidget {
  const _NieuweLesButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/beschikbaarheid');
        },
        icon: const Icon(Icons.add_rounded, size: 19),
        label: const Text('Nieuwe les aanvragen'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Les les;
  final bool isNext;
  final bool showCompletedSummary;

  const _LessonCard({
    required this.les,
    this.isNext = false,
    this.showCompletedSummary = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/planning/${les.id}');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LessonDateBlock(datum: les.datum),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        les.tijdvakLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LessonStatusBadge(status: les.status, isNext: isNext),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  les.titelLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 9),
                _LessonMetaRow(les: les),
                if (showCompletedSummary && les.afgerondInfoLabel != null) ...[
                  const SizedBox(height: 10),
                  _LessonInfoText(text: les.afgerondInfoLabel!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonDateBlock extends StatelessWidget {
  final String datum;

  const _LessonDateBlock({required this.datum});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E7), width: 0.75),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DatumUtils.dagAfkorting(datum),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DatumUtils.dagNummer(datum),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DatumUtils.maandAfkorting(datum),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonMetaRow extends StatelessWidget {
  final Les les;

  const _LessonMetaRow({required this.les});

  static bool _isEmail(String s) => s.contains('@');

  @override
  Widget build(BuildContext context) {
    final naam = les.instructeurNaam;
    final toonNaam = naam != null && naam.isNotEmpty && !_isEmail(naam);
    final items = <({IconData icon, String tekst})>[
      if (toonNaam) (icon: Icons.person_outline_rounded, tekst: naam),
      if (les.locatie?.isNotEmpty == true)
        (icon: Icons.location_on_outlined, tekst: les.locatie!),
      (
        icon: Icons.timer_outlined,
        tekst: DatumUtils.duurLabel(les.duurMinuten)
      ),
    ];

    return Wrap(
      spacing: 11,
      runSpacing: 6,
      children: items
          .map(
            (item) => _LessonMetaItem(
              icon: item.icon,
              label: item.tekst,
            ),
          )
          .toList(),
    );
  }
}

class _LessonMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LessonMetaItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonInfoText extends StatelessWidget {
  final String text;

  const _LessonInfoText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PlanningSkeletonCard extends StatelessWidget {
  const _PlanningSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          SkeletonBox(height: 70, width: 58, radius: 12),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBox(height: 12, width: 92),
                    Spacer(),
                    SkeletonBox(height: 24, width: 72, radius: 8),
                  ],
                ),
                SizedBox(height: 10),
                SkeletonBox(height: 16, width: 150),
                SizedBox(height: 12),
                SkeletonBox(height: 12, width: 220),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _PlanningLesLabels on Les {
  String get tijdvakLabel => '$starttijd - $eindtijd';

  String get titelLabel {
    final type = lesType?.trim();
    if (type != null && type.isNotEmpty) return type;
    final rijbewijs = rijbewijsSoort?.trim();
    if (rijbewijs != null && rijbewijs.isNotEmpty) {
      return 'Rijles $rijbewijs';
    }
    return 'Rijles';
  }

  String? get afgerondInfoLabel {
    if (geoefendeOnderwerpen.isNotEmpty) {
      return 'Geoefend: ${geoefendeOnderwerpen.join(', ')}';
    }
    final rating = beoordeling?.trim();
    if (rating != null && rating.isNotEmpty) {
      return 'Evaluatie: $rating';
    }
    final advies = volgendeLesAdvies?.trim();
    if (advies != null && advies.isNotEmpty) {
      return 'Volgende focus: $advies';
    }
    return null;
  }
}
