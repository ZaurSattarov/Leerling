import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/coach_widgets.dart';
<<<<<<< Updated upstream
import '../../shared/widgets/gradient_header.dart';
=======
import '../../shared/widgets/main_detail_header.dart';
>>>>>>> Stashed changes
import 'examenadvies_provider.dart';

class ExamenadviesScreen extends ConsumerWidget {
  const ExamenadviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advies = ref.watch(examenadviesProvider).maybeWhen(
          data: (data) => data,
          orElse: () => emptyExamenadvies,
        );

    return Scaffold(
      backgroundColor: AppColors.surface,
<<<<<<< Updated upstream
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: DetailGradientHeader(title: 'Examenadvies'),
=======
      body: Column(
        children: [
          const MainDetailHeader(
            eyebrowText: 'ADVIES',
            title: 'Examenadvies',
>>>>>>> Stashed changes
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                _ScoreCard(advies: advies),
                const SizedBox(height: 14),
                _ScoreBreakdownCard(items: advies.scoreOnderdelen),
                const SizedBox(height: 14),
                _TextCard(
                  icon: Icons.psychology_alt_rounded,
                  iconColor: AppColors.infoSolid,
                  title: 'Waarom deze score?',
                  body: advies.uitleg,
                ),
                const SizedBox(height: 14),
                _BulletListCard(
                  title: 'Sterke punten',
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.successSolid,
                  items: advies.sterkePunten,
                ),
                const SizedBox(height: 14),
                _BulletListCard(
                  title: 'Nog oefenen',
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.warningSolid,
                  items: advies.nogOefenen,
                ),
                const SizedBox(height: 14),
                _TextCard(
                  icon: Icons.event_available_rounded,
                  iconColor: AppColors.dark3,
                  title: 'Verwachting',
                  body: advies.resterendeLessen,
                ),
                const SizedBox(height: 14),
                _BasedOnCard(items: advies.gebaseerdOp),
                const SizedBox(height: 28),
              ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final ExamenadviesData advies;

  const _ScoreCard({required this.advies});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.school_rounded,
                color: AppColors.dark3,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ben ik klaar voor examen?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      advies.status,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${advies.score}%',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AccentProgressBar(value: advies.score / 100, minHeight: 9),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _TextCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: iconColor, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdownCard extends StatelessWidget {
  final List<ScoreOnderdeel> items;

  const _ScoreBreakdownCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.stacked_bar_chart_rounded,
                color: AppColors.dark3,
                size: 38,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Score-opbouw',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'De score verandert door een combinatie van gevolgde lessen, vaardigheidsscores, competenties en beoordelingen. Een les kan invloed hebben, maar de score kijkt naar het totaalbeeld.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ScoreOnderdeelRow(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreOnderdeelRow extends StatelessWidget {
  final ScoreOnderdeel item;

  const _ScoreOnderdeelRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final score = (item.score ?? 0).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.naam,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            NeutralChip(
              label: 'telt voor ${(item.gewicht * 100).round()}%',
              backgroundColor: AppColors.white,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          item.scoreLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color:
                item.teltMee ? AppColors.textSecondary : AppColors.warningText,
          ),
        ),
        const SizedBox(height: 8),
        AccentProgressBar(
          value: item.teltMee ? score / 100 : 0,
          minHeight: 7,
        ),
        const SizedBox(height: 7),
        Text(
          item.uitleg,
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BulletListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  const _BulletListCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: iconColor, size: 36),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
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

class _BasedOnCard extends StatelessWidget {
  final List<String> items;

  const _BasedOnCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gebaseerd op',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((label) => NeutralChip(label: label)).toList(),
          ),
        ],
      ),
    );
  }
}
