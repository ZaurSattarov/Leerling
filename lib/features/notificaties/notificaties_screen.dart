import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../models/notificatie.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'notificaties_provider.dart';

class NotificatiesScreen extends ConsumerWidget {
  const NotificatiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificatiesAsync = ref.watch(notificatiesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainDetailHeader(
            eyebrowText: 'MELDINGEN',
            title: 'Mijn meldingen',
            actions: [
              notificatiesAsync.when(
                data: (list) {
                  final heeftOngelezen = list.any((n) => !n.gelezen);
                  if (!heeftOngelezen) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () => _markeerAlles(context, ref),
                    child: const Text('Alles gelezen',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(notificatiesProvider),
              child: CustomScrollView(
                slivers: [
                  notificatiesAsync.when(
                    data: (notificaties) {
                      if (notificaties.isEmpty) {
                        return const SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.notifications_off_outlined,
                            title: 'Geen meldingen',
                            subtitle: 'Je hebt nog geen meldingen ontvangen.',
                          ),
                        );
                      }
                      final groepen = _groepeerNotificaties(notificaties);
                      return SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            for (final groep in groepen) ...[
                              SectionHeader(title: groep.label),
                              const SizedBox(height: 12),
                              for (final notificatie in groep.items)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _NotificatieCard(
                                      notificatie: notificatie, ref: ref),
                                ),
                              const SizedBox(height: 12),
                            ],
                          ]),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: SkeletonCard(),
                          ),
                          childCount: 5,
                        ),
                      ),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Kon meldingen niet laden',
                        subtitle: e.toString(),
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

  Future<void> _markeerAlles(BuildContext context, WidgetRef ref) async {
    final profiel = await ref.read(mijnProfielProvider.future);
    if (profiel == null) return;
    final meldingen = ref.read(notificatiesProvider).valueOrNull ?? const [];
    if (meldingen.any((n) => !n.isMock)) {
      await StudentService.markeerAllesGelezen(profiel.id);
    }
    ref.invalidate(notificatiesProvider);
    if (context.mounted) {
      showAppSnackBar(context, 'Alle meldingen gemarkeerd als gelezen',
          isSuccess: true);
    }
  }
}

class _NotificatieGroep {
  final String label;
  final List<Notificatie> items;

  const _NotificatieGroep(this.label, this.items);
}

List<_NotificatieGroep> _groepeerNotificaties(List<Notificatie> notificaties) {
  final vandaag = <Notificatie>[];
  final dezeWeek = <Notificatie>[];
  final eerder = <Notificatie>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final notificatie in notificaties) {
    final created = DateTime.tryParse(notificatie.createdAt)?.toLocal();
    if (created == null) {
      eerder.add(notificatie);
      continue;
    }
    final day = DateTime(created.year, created.month, created.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      vandaag.add(notificatie);
    } else if (diff < 7) {
      dezeWeek.add(notificatie);
    } else {
      eerder.add(notificatie);
    }
  }

  return [
    if (vandaag.isNotEmpty) _NotificatieGroep('Vandaag', vandaag),
    if (dezeWeek.isNotEmpty) _NotificatieGroep('Deze week', dezeWeek),
    if (eerder.isNotEmpty) _NotificatieGroep('Eerder', eerder),
  ];
}

class _NotificatieCard extends ConsumerWidget {
  final Notificatie notificatie;
  final WidgetRef ref;

  const _NotificatieCard({required this.notificatie, required this.ref});

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
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      backgroundColor:
          notificatie.gelezen ? AppColors.white : AppColors.primaryLight,
      onTap: () async {
        if (!notificatie.gelezen && !notificatie.isMock) {
          final profiel = await ref.read(mijnProfielProvider.future);
          if (profiel != null) {
            await StudentService.markeerGelezen(notificatie.id, profiel.id);
            ref.invalidate(notificatiesProvider);
          }
        }
        if (context.mounted) context.go(notificatie.targetRoute);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: _icon, color: _color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notificatie.titel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notificatie.gelezen
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!notificatie.gelezen)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (notificatie.tekst?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    notificatie.tekst!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _tijdGeleden(notificatie.aangemaaktOp),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    if (_absoluteDatum(notificatie.aangemaaktOp)
                        .isNotEmpty) ...[
                      const SizedBox(width: 6),
                      const Text('·',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                      const SizedBox(width: 6),
                      Text(
                        _absoluteDatum(notificatie.aangemaaktOp),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tijdGeleden(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Zojuist';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min geleden';
      if (diff.inHours < 24) return '${diff.inHours} uur geleden';
      if (diff.inDays == 1) return 'Gisteren';
      return '${diff.inDays} dagen geleden';
    } catch (_) {
      return '';
    }
  }

  String _absoluteDatum(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
