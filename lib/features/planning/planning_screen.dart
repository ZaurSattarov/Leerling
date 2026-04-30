import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
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
            expandedHeight: 110,
            automaticallyImplyLeading: false,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(20, 0, 20, 56),
              title: Text(
                'Mijn Planning',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Komende lessen'),
                Tab(text: 'Vorige lessen'),
              ],
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
          if (lessen.isEmpty) {
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
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: lessen.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _LesCard(les: lessen[i]),
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

class _LesCard extends StatelessWidget {
  final Les les;
  const _LesCard({required this.les});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/planning/${les.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date block
          Container(
            width: 52,
            height: 60,
            decoration: BoxDecoration(
              color: les.status == LesStatus.gepland
                  ? AppColors.primary
                  : AppColors.borderLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _dagNummer(les.datum),
                  style: TextStyle(
                    color: les.status == LesStatus.gepland
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _maandAfk(les.datum),
                  style: TextStyle(
                    color: les.status == LesStatus.gepland
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
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
                  children: [
                    Expanded(
                      child: Text(
                        '${les.starttijd} – ${les.eindtijd}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusPill.les(les.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DatumUtils.duurLabel(les.duurMinuten),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (les.locatie?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
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
                  ),
                ],
                if (les.instructeurNaam?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(
                        les.instructeurNaam!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
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
      final months = ['jan','feb','mrt','apr','mei','jun','jul','aug','sep','okt','nov','dec'];
      return months[DateTime.parse(datum).month - 1];
    } catch (_) {
      return '';
    }
  }
}
