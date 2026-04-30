import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'voortgang_provider.dart';

class VoortgangScreen extends ConsumerWidget {
  const VoortgangScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(mijnProfielProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.dark,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 110,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Text(
                  'Mijn Voortgang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
                final beoordeeld = vaardigheden.values
                    .where((v) => (v as num? ?? 0) > 0)
                    .length;
                final totaal = vaardighedenLabels.length;

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Overall summary card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Totale voortgang',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${profiel.lessenGevolgd} / ${profiel.lessenTotaal} lessen',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: profiel.voortgangPercent,
                                      minHeight: 8,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.25),
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                              Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$beoordeeld van $totaal vaardigheden beoordeeld',
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '${(profiel.voortgangPercent * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Skill categories
                      ...vaardighedenCategorieen.entries.map((cat) {
                        final keys = cat.value;
                        final scores = keys
                            .map((k) =>
                                (vaardigheden[k] as num? ?? 0).toDouble())
                            .toList();
                        final avg = scores.isEmpty
                            ? 0.0
                            : scores.reduce((a, b) => a + b) / scores.length;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CategoryCard(
                            naam: cat.key,
                            keys: keys,
                            vaardigheden: vaardigheden,
                            gemiddeld: avg,
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                    ]),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SkeletonBox(height: 130, radius: 18),
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

class _CategoryCard extends StatefulWidget {
  final String naam;
  final List<String> keys;
  final Map<String, dynamic> vaardigheden;
  final double gemiddeld;

  const _CategoryCard({
    required this.naam,
    required this.keys,
    required this.vaardigheden,
    required this.gemiddeld,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  Color get _scoreColor {
    if (widget.gemiddeld >= 4) return AppColors.successSolid;
    if (widget.gemiddeld >= 2.5) return AppColors.warningSolid;
    if (widget.gemiddeld > 0) return AppColors.dangerSolid;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.naam,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: widget.gemiddeld / 5.0,
                          minHeight: 6,
                          backgroundColor: AppColors.borderLight,
                          valueColor:
                              AlwaysStoppedAnimation(_scoreColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.gemiddeld > 0
                          ? widget.gemiddeld.toStringAsFixed(1)
                          : '–',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.gemiddeld > 0
                            ? _scoreColor
                            : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      'van 5',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.keys.map((key) {
              final score =
                  (widget.vaardigheden[key] as num? ?? 0).toDouble();
              final label = vaardighedenLabels[key] ?? key;
              return _SkillRow(label: label, score: score);
            }),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String label;
  final double score;

  const _SkillRow({required this.label, required this.score});

  Color get _dotColor {
    if (score >= 4) return AppColors.successSolid;
    if (score >= 2.5) return AppColors.warningSolid;
    if (score > 0) return AppColors.dangerSolid;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              return Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: i < score
                      ? _dotColor
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: i < score
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              );
            }),
          ),
        ],
      ),
    );
  }
}
