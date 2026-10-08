import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_tab_header.dart';
import 'planning_provider.dart';
import 'widgets/framer_animated_timeline.dart';
import 'widgets/lesson_status_badge.dart';
import '../../core/constants/cool_icons.dart';
import '../../shared/widgets/main_scaffold.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
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
          const _NieuweLesFab(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const height = 40.0;
    const padding = 3.5;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2330) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final availableWidth = totalWidth - (padding * 2);
          final itemWidth = availableWidth / labels.length;
          final indicatorLeft = padding + (activeIndex * itemWidth);

          return Stack(
            children: [
              // 1-op-1 sliding animated selector pil zoals bij Instructeur app
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                top: padding,
                left: indicatorLeft,
                width: itemWidth,
                height: height - (padding * 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.15 : 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              // Klikbare opties en tekstkleuren exact conform Instructeur app
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = i == activeIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Container(
                        height: height,
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF111111)
                                    : Colors.white)
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF8A8A8E)),
                            letterSpacing: -0.2,
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
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
    final listPadding = EdgeInsets.fromLTRB(
        20, 20, 20, MainShellContentInset.bottomOf(context));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        HapticFeedback.selectionClick();
        ref.invalidate(komendeLessenProvider);
        ref.invalidate(vorigeLessenProvider);
      },
      child: lessenAsync.when(
        data: (lessen) {
          if (lessen.isEmpty) {
            return ListView(
              padding: listPadding,
              children: [
                _PlanningEmptyState(isKomend: isKomend),
              ],
            );
          }

          return AnimatedFramerTimeline(
            lessen: lessen,
            isKomend: isKomend,
            bottomPadding: listPadding.bottom,
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
              icon: CoolIcons.cloudOff,
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
            child: Icon(
              isKomend ? CoolIcons.calendarCheck : CoolIcons.listChecklist,
              color: AppColors.iconPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isKomend ? 'Geen komende lessen' : 'Nog geen afgeronde lessen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isKomend
                ? 'Zodra je instructeur een les plant, verschijnt die hier automatisch.'
                : 'Afgeronde lessen met zichtbare evaluatie verschijnen hier.',
            textAlign: TextAlign.center,
            style: TextStyle(
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

/// Zwevende, verticaal versleepbare knop (zoals de notitieknop in de
/// Instructeur-app) die "Nieuwe les aanvragen" opent.
class _NieuweLesFab extends StatefulWidget {
  const _NieuweLesFab();

  @override
  State<_NieuweLesFab> createState() => _NieuweLesFabState();
}

class _NieuweLesFabState extends State<_NieuweLesFab> {
  static const _prefsKey = 'planning_nieuwe_les_fab_top';
  static const _breedte = 40.0;
  static const _hoogte = 40.0;
  double? _top;

  @override
  void initState() {
    super.initState();
    _laadTop();
  }

  Future<void> _laadTop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_prefsKey);
      if (mounted && saved != null) setState(() => _top = saved);
    } catch (_) {}
  }

  Future<void> _bewaarTop(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, value);
    } catch (_) {}
  }

  double _clampTop(BuildContext context, double value) {
    final media = MediaQuery.of(context);
    final minTop = media.padding.top + 156;
    final maxTop = media.size.height - media.padding.bottom - 118 - _hoogte;
    if (maxTop <= minTop) return minTop;
    return value.clamp(minTop, maxTop).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final standaardTop =
        (media.size.height - media.padding.top - media.padding.bottom) / 2;
    final top = _clampTop(context, _top ?? standaardTop);

    return Positioned(
      right: 10,
      top: top,
      child: Semantics(
        button: true,
        label: 'Nieuwe les aanvragen',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/beschikbaarheid');
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              _top = _clampTop(context, (_top ?? top) + details.delta.dy);
            });
          },
          onVerticalDragEnd: (_) {
            final huidig = _top;
            if (huidig != null) _bewaarTop(huidig);
          },
          child: Container(
            width: _breedte,
            height: _hoogte,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              CoolIcons.calendarAdd,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
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

/// Fallback / contract-guard voor gedeelde leskaart en statusbadge.
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
    return LessonStatusBadge(status: les.status, isNext: isNext);
  }
}

extension _PlanningLesLabels on Les {
  String get titelLabel {
    final type = lesType?.trim();
    if (type != null && type.isNotEmpty) return type;
    final rijbewijs = rijbewijsSoort?.trim();
    if (rijbewijs != null && rijbewijs.isNotEmpty) {
      return 'Rijles $rijbewijs';
    }
    return 'Rijles';
  }

  void _guardCheck(Les les) {
    // Guard assertions voor DatumUtils duurLabel in metadata
    final _ = (tekst: DatumUtils.duurLabel(les.duurMinuten),);
  }
}
