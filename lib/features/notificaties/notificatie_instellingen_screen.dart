import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/leerling_notificatie_voorkeuren.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'notificatie_instellingen_provider.dart';

class NotificatieInstellingenScreen extends ConsumerWidget {
  const NotificatieInstellingenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificatieInstellingenProvider);
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 112;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const MainDetailHeader(
            eyebrowText: 'PROFIEL',
            title: 'Meldingen',
            fallbackRoute: '/profiel',
          ),
          Expanded(
            child: state.when(
              loading: () => const _LoadingState(),
              error: (_, __) => EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Instellingen laden lukt niet',
                subtitle: 'Probeer het later opnieuw.',
              ),
              data: (voorkeuren) => RefreshIndicator(
                onRefresh: () => ref.refresh(
                  notificatieInstellingenProvider.future,
                ),
                child: SwitchTheme(
                  data: _notificationSwitchTheme(context),
                  child: ListView(
                    key: const Key('notificatie_instellingen_lijst'),
                    padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
                    children: [
                      const AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconBadge(
                              icon: Icons.info_outline_rounded,
                              color: AppColors.iconPrimary,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Meldingsvoorkeuren worden opgeslagen voor je Klantio-account. Belangrijke berichten blijven altijd zichtbaar in de app. Meldingen buiten de app worden later ondersteund.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader(title: 'Lessen'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SwitchRow(
                              key: const Key('toggle_nieuwe_les'),
                              icon: Icons.event_available_outlined,
                              title: 'Nieuwe les',
                              subtitle:
                                  'Wanneer er een les voor je klaarstaat.',
                              value: voorkeuren.nieuweLes,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(nieuweLes: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              key: const Key('toggle_les_verplaatst'),
                              icon: Icons.swap_horiz_rounded,
                              title: 'Les verplaatst',
                              subtitle: 'Bij wijzigingen in je lesplanning.',
                              value: voorkeuren.lesVerplaatst,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(lesVerplaatst: value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader(title: 'Facturen'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SwitchRow(
                              key: const Key('toggle_nieuwe_factuur'),
                              icon: Icons.receipt_long_outlined,
                              title: 'Nieuwe factuur',
                              subtitle: 'Wanneer een factuur beschikbaar is.',
                              value: voorkeuren.nieuweFactuur,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(nieuweFactuur: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              key: const Key('toggle_betaling_ontvangen'),
                              icon: Icons.payments_outlined,
                              title: 'Betaling ontvangen',
                              subtitle:
                                  'Bevestiging na een verwerkte betaling.',
                              value: voorkeuren.betalingOntvangen,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(betalingOntvangen: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              key: const Key('toggle_factuurherinnering'),
                              icon: Icons.schedule_outlined,
                              title: 'Factuurherinnering',
                              subtitle:
                                  'Herinneringen rond openstaande facturen.',
                              value: voorkeuren.factuurHerinnering,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(factuurHerinnering: value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader(title: 'Voortgang'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SwitchRow(
                              key: const Key('toggle_nieuwe_evaluatie'),
                              icon: Icons.rate_review_outlined,
                              title: 'Nieuwe evaluatie',
                              subtitle:
                                  'Wanneer je instructeur feedback deelt.',
                              value: voorkeuren.nieuweEvaluatie,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(nieuweEvaluatie: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              key: const Key('toggle_lespakket_bijna_op'),
                              icon: Icons.layers_outlined,
                              title: 'Lespakket bijna op',
                              subtitle: 'Als je lessen bijna op zijn.',
                              value: voorkeuren.lespakketBijnaOp,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(lespakketBijnaOp: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              key: const Key('toggle_examenadvies'),
                              icon: Icons.school_outlined,
                              title: 'Examenadvies',
                              subtitle: 'Updates over je examenadvies.',
                              value: voorkeuren.examenadvies,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(examenadvies: value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader(title: 'Altijd actief'),
                      const SizedBox(height: 10),
                      const AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _LockedRow(
                              icon: Icons.verified_user_outlined,
                              title: 'Account- en beveiligingsmeldingen',
                              subtitle:
                                  'Nodig om je account veilig en bereikbaar te houden.',
                            ),
                            Divider(height: 1, indent: 72),
                            _LockedRow(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'Essentiele serviceberichten',
                              subtitle:
                                  'Belangrijke informatie over je lessen en account blijft zichtbaar.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    LeerlingNotificatieVoorkeuren voorkeuren,
  ) async {
    try {
      await ref
          .read(notificatieInstellingenProvider.notifier)
          .opslaan(voorkeuren);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(context, 'Opslaan mislukt', isError: true);
    }
  }
}

SwitchThemeData _notificationSwitchTheme(BuildContext context) {
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.textMuted;
      }
      return AppColors.white;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.borderLight;
      }
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.border;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryDark.withValues(alpha: 0.25);
      }
      return AppColors.textMuted.withValues(alpha: 0.35);
    }),
    trackOutlineWidth: const WidgetStatePropertyAll(1),
  );
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.iconPrimary, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LockedRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LockedRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.iconPrimary, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Altijd actief',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      itemBuilder: (_, index) => const SkeletonCard(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 5,
    );
  }
}
