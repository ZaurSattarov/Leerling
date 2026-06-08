import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/factuur.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_pill.dart';
import 'facturen_provider.dart';

class FacturenScreen extends ConsumerWidget {
  const FacturenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facturenAsync = ref.watch(facturenProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(facturenProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.dark,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 110,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.fromLTRB(20, 0, 64, 16),
                title: _ScreenHeader(
                    label: 'FACTUREN', title: 'Mijn facturen'),
              ),
            ),
            facturenAsync.when(
              data: (facturen) {
                if (facturen.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Geen facturen',
                      subtitle: 'Je hebt nog geen facturen ontvangen.',
                    ),
                  );
                }

                // Summary header
                final open = facturen.where((f) => f.isBetaalbaar).toList();
                final openBedrag =
                    open.fold(0, (sum, f) => sum + f.bedragCents);

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (open.isNotEmpty) ...[
                        _SummaryCard(
                          openAantal: open.length,
                          openBedragCents: openBedrag,
                        ),
                        const SizedBox(height: 20),
                      ],
                      const SectionHeader(title: 'Alle facturen'),
                      const SizedBox(height: 12),
                      ...facturen.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FactuurCard(factuur: f),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
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
                  title: 'Kon facturen niet laden',
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

class _SummaryCard extends StatelessWidget {
  final int openAantal;
  final int openBedragCents;

  const _SummaryCard({required this.openAantal, required this.openBedragCents});

  String get _bedragEuro =>
      'EUR ${(openBedragCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$openAantal openstaande factuur${openAantal > 1 ? 'en' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _bedragEuro,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
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
                ? AppColors.iconGreen
                : factuur.isVerlopen
                    ? AppColors.iconRed
                    : factuur.status == FactuurStatus.geannuleerd
                        ? AppColors.iconSlate
                        : AppColors.iconAmber,
          ),
          const SizedBox(width: 14),
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
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  factuur.factuurnummer,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (factuur.vervaldatum?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Vervaldatum: ${DatumUtils.korteDatum(factuur.vervaldatum!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: DatumUtils.isVerlopen(factuur.vervaldatum)
                          ? AppColors.dangerText
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                factuur.bedragEuro,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
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

class _ScreenHeader extends StatelessWidget {
  final String label;
  final String title;
  const _ScreenHeader({required this.label, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
