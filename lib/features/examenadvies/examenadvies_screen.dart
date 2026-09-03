import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/coach_widgets.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'examenadvies_ontwikkeling.dart';
import 'examenadvies_provider.dart';
import 'examenadvies_sparkline.dart';
import 'examenadvies_status_style.dart';

class ExamenadviesScreen extends ConsumerWidget {
  const ExamenadviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(examenadviesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Examenadvies',
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const _ExamenadviesBody(advies: emptyExamenadvies),
              data: (advies) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(examenadviesProvider);
                  await ref.read(examenadviesProvider.future);
                },
                child: _ExamenadviesBody(advies: advies),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamenadviesBody extends StatelessWidget {
  final ExamenadviesData advies;

  const _ExamenadviesBody({required this.advies});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ScoreCard(advies: advies),
              const SizedBox(height: 14),
              _TextCard(
                icon: Icons.psychology_alt_rounded,
                iconColor: AppColors.infoSolid,
                title: 'Waarom dit advies?',
                body: advies.uitleg,
              ),
              if (advies.categorieen.isNotEmpty) ...[
                const SizedBox(height: 14),
                _VaardighedenCard(categorieen: advies.categorieen),
              ],
              if (advies.sterkePunten.isNotEmpty) ...[
                const SizedBox(height: 14),
                _BulletListCard(
                  title: 'Sterkste punten',
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.successSolid,
                  items: advies.sterkePunten,
                ),
              ],
              if (advies.nogOefenen.isNotEmpty) ...[
                const SizedBox(height: 14),
                _BulletListCard(
                  title: 'Aandachtspunten',
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.warningSolid,
                  items: advies.nogOefenen,
                ),
              ],
              const SizedBox(height: 14),
              _OntwikkelingCard(advies: advies),
              const SizedBox(height: 14),
              _TextCard(
                icon: Icons.event_available_rounded,
                iconColor: AppColors.dark3,
                title: 'Volgende stap',
                body: advies.volgendeStap,
              ),
              if (advies.gebaseerdOp.isNotEmpty) ...[
                const SizedBox(height: 14),
                _BasedOnCard(items: advies.gebaseerdOp),
              ],
              const SizedBox(height: 28),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final ExamenadviesData advies;

  const _ScoreCard({required this.advies});

  @override
  Widget build(BuildContext context) {
    final toonScore = advies.heeftBetrouwbareScore && advies.score != null;
    final statusKleur = examenadviesStatusAccent(advies.status);

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
                      advies.statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusKleur,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                toonScore ? '${advies.score}%' : '—',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AccentProgressBar(
            value: toonScore ? advies.score! / 100 : 0,
            minHeight: 9,
          ),
        ],
      ),
    );
  }
}

class _VaardighedenCard extends StatelessWidget {
  final List<CategorieScore> categorieen;

  const _VaardighedenCard({required this.categorieen});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vaardigheden',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...categorieen.map(
            (categorie) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CategorieRij(categorie: categorie),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorieRij extends StatelessWidget {
  final CategorieScore categorie;

  const _CategorieRij({required this.categorie});

  @override
  Widget build(BuildContext context) {
    final score = categorie.huidigOpVijf;
    final label = categorie.scoreLabel;
    final heeftData = categorie.heeftData && score != null && label != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                categorie.naam,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              heeftData ? '$label/${ExamenadviesRules.maxScoreOpVijf}' : 'Nog geen score',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: heeftData
                    ? AppColors.textSecondary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AccentProgressBar(
          value: heeftData ? score / ExamenadviesRules.maxScoreOpVijf : 0,
          minHeight: 7,
        ),
      ],
    );
  }
}

class _OntwikkelingCard extends StatelessWidget {
  final ExamenadviesData advies;

  const _OntwikkelingCard({required this.advies});

  @override
  Widget build(BuildContext context) {
    final sparkline = bouwOntwikkelingSparkline(advies);
    final tekst = advies.ontwikkeling.isNotEmpty
        ? advies.ontwikkeling
        : 'Na meerdere beoordelingen zie je hier je ontwikkeling.';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(
                icon: Icons.trending_up_rounded,
                color: AppColors.successSolid,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ontwikkeling',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tekst,
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
          const SizedBox(height: 12),
          ExamenadviesSparkline(data: sparkline),
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
