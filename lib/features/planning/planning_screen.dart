import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/status_pill.dart';
import 'planning_provider.dart';

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
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: AppColors.dark,
            pinned: true,
            floating: false,
            expandedHeight: 120,
            automaticallyImplyLeading: false,
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
              titlePadding: EdgeInsets.fromLTRB(20, 0, 64, 56),
              title: ScreenHeader(label: 'PLANNING', title: 'Mijn lessen'),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: AnimatedBuilder(
                  animation: _tabs,
                  builder: (_, __) => _PillTabBar(
                    activeIndex: _tabs.index,
                    labels: const ['Komende lessen', 'Afgerond'],
                    onTap: (i) => _tabs.animateTo(i),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _LessenTab(provider: komendeLessenProvider, isKomend: true),
            _LessenTab(provider: vorigeLessenProvider, isKomend: false),
          ],
        ),
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == activeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(komendeLessenProvider);
        ref.invalidate(vorigeLessenProvider);
      },
      child: lessenAsync.when(
        data: (lessen) {
          if (lessen.isEmpty && !isKomend) {
            return ListView(
              children: [
                EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: isKomend
                      ? 'Geen komende lessen'
                      : 'Nog geen lessen gevolgd',
                  subtitle: isKomend
                      ? 'Je instructeur heeft nog geen les ingepland.'
                      : 'Afgeronde lessen verschijnen hier.',
                ),
              ],
            );
          }
          final total = lessen.length + (isKomend ? 1 : 0);
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: total,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == lessen.length) {
                return _NieuweLesButton();
              }
              return _LesCard(
                les: lessen[i],
                isNext: isKomend && i == 0,
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const SkeletonCard(),
        ),
        error: (e, _) => ListView(
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

class _NieuweLesButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/beschikbaarheid'),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Nieuwe les aanvragen'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LesCard extends StatelessWidget {
  final Les les;
  final bool isNext;

  const _LesCard({required this.les, this.isNext = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/planning/${les.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 76,
            decoration: BoxDecoration(
              color: isNext ? AppColors.primary : AppColors.dark,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isNext
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _dagAfk(les.datum),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _dagNummer(les.datum),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  _maandAfk(les.datum),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${les.starttijd} — ${les.eindtijd}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isNext) const _VolgendeBadge(),
                    if (!isNext) StatusPill.les(les.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  les.geoefendeOnderwerpen.isNotEmpty
                      ? les.geoefendeOnderwerpen.join(' · ')
                      : DatumUtils.duurLabel(les.duurMinuten),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (les.instructeurNaam?.isNotEmpty == true ||
                    les.locatie?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (les.instructeurNaam?.isNotEmpty == true) ...[
                        const Icon(Icons.person_outline_rounded,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(les.instructeurNaam!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint)),
                        const SizedBox(width: 10),
                      ],
                      if (les.locatie?.isNotEmpty == true) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            les.locatie!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dagAfk(String datum) {
    try {
      const days = ['MAA', 'DIN', 'WOE', 'DON', 'VRI', 'ZAT', 'ZON'];
      return days[DateTime.parse(datum).weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String _dagNummer(String datum) {
    try {
      return DateTime.parse(datum).day.toString();
    } catch (_) {
      return '?';
    }
  }

  String _maandAfk(String datum) {
    try {
      const months = [
        'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
        'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
      ];
      return months[DateTime.parse(datum).month - 1];
    } catch (_) {
      return '';
    }
  }
}

class _VolgendeBadge extends StatelessWidget {
  const _VolgendeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Volgende',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
