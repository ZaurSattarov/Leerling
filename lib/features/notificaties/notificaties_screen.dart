import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/leerling_notificatie_router.dart';
import '../../core/services/student_service.dart';
import '../../models/notificatie.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/isomorphic_icons.dart';
import '../../shared/widgets/klantio_pressable.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/main_scaffold.dart' show MainShellContentInset;
import '../../shared/widgets/snackbar.dart';
import 'notificaties_provider.dart';
import '../../core/constants/cool_icons.dart';

class NotificatiesScreen extends ConsumerWidget {
  const NotificatiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificatiesAsync = ref.watch(notificatiesProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          MainDetailHeader(
            title: 'Notificaties',
            titleHorizontalPadding: 130,
            actions: [
              AllesGelezenKnop(
                onPressed: notificatiesAsync.valueOrNull?.any(
                          (n) => !n.gelezen,
                        ) ==
                        true
                    ? () => _markeerAlles(context, ref)
                    : null,
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
                            icon: CoolIcons.bellOff,
                            title: 'Geen meldingen',
                            subtitle: 'Je hebt nog geen meldingen ontvangen.',
                          ),
                        );
                      }
                      final groepen = _groepeerNotificaties(notificaties);
                      return SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          MainShellContentInset.bottomOf(context),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            for (final groep in groepen)
                              _MeldingSectie(
                                label: groep.label,
                                items: groep.items,
                                ref: ref,
                              ),
                          ]),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                        icon: CoolIcons.cloudOff,
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

class _MeldingSectie extends StatelessWidget {
  final String label;
  final List<Notificatie> items;
  final WidgetRef ref;

  const _MeldingSectie({
    required this.label,
    required this.items,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          for (final n in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NotificatieCard(notificatie: n, ref: ref),
            ),
        ],
      ),
    );
  }
}

class _NotificatieCard extends ConsumerWidget {
  final Notificatie notificatie;
  final WidgetRef ref;

  const _NotificatieCard({required this.notificatie, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOngelezen = !notificatie.gelezen;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (!notificatie.gelezen && !notificatie.isMock) {
            final profiel = await ref.read(mijnProfielProvider.future);
            if (profiel != null) {
              await StudentService.markeerGelezen(notificatie.id, profiel.id);
              ref.invalidate(notificatiesProvider);
            }
          }
          if (context.mounted) {
            await openLeerlingNotificatie(notificatie, context: context);
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 3,
                height: 40,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 3,
                    height: isOngelezen ? 22 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: IsomorphicDockNotificationIcon(
                    type: notificatie.type,
                    title: notificatie.titel,
                    detail: notificatie.tekst ?? '',
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notificatie.titel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.25,
                              fontWeight: isOngelezen
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tijdGeleden(notificatie.aangemaaktOp),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                    if (notificatie.tekst?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        notificatie.tekst!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.38,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isOngelezen)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _tijdGeleden(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Nu';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}u';
      if (diff.inDays == 1) return 'Gisteren';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}-${dt.month}-${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

/// Check-all knop rechtsboven in de header (zelfde als Instructeur).
class AllesGelezenKnop extends StatelessWidget {
  final VoidCallback? onPressed;

  const AllesGelezenKnop({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final actief = onPressed != null;
    return KlantioPressable(
      onTap: onPressed,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            CoolIcons.checkAll,
            size: 22,
            color:
                const Color(0xFFF8FAFC).withValues(alpha: actief ? 1.0 : 0.35),
          ),
        ),
      ),
    );
  }
}
