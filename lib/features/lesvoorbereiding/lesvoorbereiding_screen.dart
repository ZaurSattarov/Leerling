import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
<<<<<<< Updated upstream
import '../../shared/widgets/gradient_header.dart';
=======
import '../../shared/widgets/main_detail_header.dart';
>>>>>>> Stashed changes
import 'lesvoorbereiding_provider.dart';

class LesvoorbereidingScreen extends ConsumerWidget {
  const LesvoorbereidingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voorbereidingAsync = ref.watch(lesvoorbereidingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
<<<<<<< Updated upstream
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: DetailGradientHeader(title: 'Lesvoorbereiding'),
=======
      body: Column(
        children: [
          const MainDetailHeader(
            eyebrowText: 'VOORBEREIDING',
            title: 'Lesvoorbereiding',
>>>>>>> Stashed changes
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                voorbereidingAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) =>
                      const SliverFillRemaining(child: SizedBox()),
                  data: (voorbereiding) => SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _FocusCard(data: voorbereiding),
                        if (voorbereiding.tips.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ListCard(
                            title: 'Aandachtspunten volgende les',
                            icon: Icons.lightbulb_outline_rounded,
                            iconColor: AppColors.warningSolid,
                            items: voorbereiding.tips,
                          ),
                        ],
                        if (voorbereiding.oefenen.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ListCard(
                            title: 'Dit ga je oefenen',
                            icon: Icons.route_rounded,
                            iconColor: AppColors.infoSolid,
                            items: voorbereiding.oefenen,
                          ),
                        ],
                        if (voorbereiding.motivatie.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const IconBadge(
                                  icon: Icons.favorite_border_rounded,
                                  color: AppColors.successSolid,
                                  size: 38,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Feedback instructeur',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        voorbereiding.motivatie,
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
                          ),
                        ],
                        const SizedBox(height: 28),
                      ]),
                    ),
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

class _FocusCard extends StatelessWidget {
  final LesvoorbereidingData data;

  const _FocusCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.center_focus_strong_rounded,
                color: AppColors.dark3,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Focus van je volgende les',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.focus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.voorbereiding,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  const _ListCard({
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
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
