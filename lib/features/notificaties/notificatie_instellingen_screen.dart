import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/leerling_notificatie_voorkeuren.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/framer_toggle.dart';
import '../../shared/widgets/settings_design.dart';
import '../../shared/widgets/snackbar.dart';
import 'notificatie_instellingen_provider.dart';
import 'leerling_email_preference_registry.dart';
import '../../core/constants/cool_icons.dart';

class NotificatieInstellingenScreen extends ConsumerWidget {
  const NotificatieInstellingenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificatieInstellingenProvider);
    final saving = state.isLoading;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 112;

    // Opbouw 1-op-1 als de Instructeur-app (SettingsBodyScaffold). Schakelaars
    // worden direct opgeslagen -- dus geen groen vinkje op dit scherm.
    return SettingsBodyScaffold(
      titel: 'Notificaties',
      body: Column(
        children: [
          Expanded(
            child: state.when(
              loading: () => const _LoadingState(),
              error: (_, __) => EmptyState(
                icon: CoolIcons.bellOff,
                title: 'Instellingen laden lukt niet',
                subtitle: 'Probeer het later opnieuw.',
              ),
              data: (voorkeuren) => RefreshIndicator(
                onRefresh: () async {
                  if (saving) return;
                  return ref
                      .refresh(notificatieInstellingenProvider.future)
                      .then<void>((_) {});
                },
                child: SwitchTheme(
                  data: _notificationSwitchTheme(context),
                  child: ListView(
                    key: const Key('notificatie_instellingen_lijst'),
                    padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
                    children: [
                      Text(
                        'Pushmeldingen',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SectionHeader(title: 'Lessen'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_nieuwe_les'),
                              icon: CoolIcons.calendarCheck,
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
                              enabled: !saving,
                              key: const Key('toggle_les_verplaatst'),
                              icon: CoolIcons.arrowLeftRight,
                              title: 'Les verplaatst',
                              subtitle: 'Bij wijzigingen in je lesplanning.',
                              value: voorkeuren.lesVerplaatst,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(lesVerplaatst: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_les_herinnering'),
                              icon: CoolIcons.alarm,
                              title: 'Lesherinneringen',
                              subtitle:
                                  'Herinneringen 1 dag en 1 uur voor je rijles.',
                              value: voorkeuren.lesHerinnering,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(lesHerinnering: value),
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
                              enabled: !saving,
                              key: const Key('toggle_nieuwe_factuur'),
                              icon: CoolIcons.fileDocument,
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
                              enabled: !saving,
                              key: const Key('toggle_betaling_ontvangen'),
                              icon: CoolIcons.creditCard01,
                              title: 'Betaling verwerkt',
                              subtitle:
                                  'Bevestiging wanneer je betaling is ontvangen en verwerkt.',
                              value: voorkeuren.betalingOntvangen,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(betalingOntvangen: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_factuurherinnering'),
                              icon: CoolIcons.clock,
                              title: 'Factuurherinneringen',
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
                      const SectionHeader(title: 'Examens'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_examen_gepland'),
                              icon: CoolIcons.calendar,
                              title: 'Examen ingepland',
                              subtitle:
                                  'Als je instructeur een examen voor je plant.',
                              value: voorkeuren.examenGepland,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(examenGepland: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_examen_herinnering'),
                              icon: CoolIcons.alarm,
                              title: 'Examenherinneringen',
                              subtitle:
                                  'Herinneringen 7 dagen en 1 dag voor je examen.',
                              value: voorkeuren.examenHerinnering,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(examenHerinnering: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_examen_resultaat'),
                              icon: CoolIcons.star,
                              title: 'Examenresultaat',
                              subtitle:
                                  'Als je instructeur je examenresultaat toevoegt.',
                              value: voorkeuren.examenResultaat,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(examenResultaat: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 72),
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_examenadvies'),
                              icon: CoolIcons.bookOpen,
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
                      const SectionHeader(title: 'Voortgang'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SwitchRow(
                              enabled: !saving,
                              key: const Key('toggle_nieuwe_evaluatie'),
                              icon: CoolIcons.chatDots,
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
                              enabled: !saving,
                              key: const Key('toggle_lespakket_bijna_op'),
                              icon: CoolIcons.layers,
                              title: 'Lespakket bijna op',
                              subtitle: 'Als je lessen bijna op zijn.',
                              value: voorkeuren.lespakketBijnaOp,
                              onChanged: (value) => _save(
                                context,
                                ref,
                                voorkeuren.copyWith(lespakketBijnaOp: value),
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
                              icon: CoolIcons.calendarClose,
                              title: 'Les geannuleerd',
                              subtitle:
                                  'Je hoort altijd wanneer een geplande les niet doorgaat.',
                            ),
                            Divider(height: 1, indent: 72),
                            _LockedRow(
                              icon: CoolIcons.timer,
                              title: 'Les start binnenkort',
                              subtitle:
                                  'Korte verplichte melding vlak voor aanvang van je rijles.',
                            ),
                            Divider(height: 1, indent: 72),
                            _LockedRow(
                              icon: CoolIcons.mail,
                              title: 'Bericht van je instructeur',
                              subtitle:
                                  'Directe berichten via Klantio — niet uit te zetten.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SectionHeader(
                        key: Key('email_meldingen'),
                        title: 'E-mailmeldingen',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kies welke e-mails je wilt ontvangen. Deze keuzes staan los van je pushmeldingen.',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context)
                              .withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: _SwitchRow(
                          key: const Key('toggle_email_notificaties'),
                          enabled: !saving,
                          icon: CoolIcons.mail,
                          title: 'E-mailmeldingen ontvangen',
                          subtitle: 'Zet aan en kies hieronder je onderwerpen. '
                              'Account- en beveiligingsmails ontvang je altijd.',
                          value: voorkeuren.emailNotificaties,
                          onChanged: (value) => _saveEmail(
                            context,
                            ref,
                            voorkeuren.copyWith(emailNotificaties: value),
                          ),
                        ),
                      ),
                      for (final group in const [
                        'Rijlessen',
                        'Lespakketten',
                        'Voortgang',
                        'Examens',
                      ]) ...[
                        const SizedBox(height: 22),
                        SectionHeader(title: group),
                        const SizedBox(height: 10),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            for (final topic in leerlingEmailPreferenceToggles
                                .where((topic) => topic.group == group)) ...[
                              if (topic !=
                                  leerlingEmailPreferenceToggles.firstWhere(
                                      (topic) => topic.group == group))
                                const Divider(height: 1, indent: 72),
                              _SwitchRow(
                                key: Key('email_topic_${topic.topicKey}'),
                                enabled:
                                    !saving && voorkeuren.emailNotificaties,
                                icon: CoolIcons.mail,
                                title: topic.title,
                                subtitle: topic.subtitle,
                                value: voorkeuren
                                    .emailTopicEnabled(topic.topicKey),
                                onChanged: (value) => _saveEmail(
                                  context,
                                  ref,
                                  voorkeuren.copyWith(emailTopics: {
                                    ...voorkeuren.emailTopics,
                                    topic.topicKey: value,
                                  }),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ],
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

  Future<void> _saveEmail(
    BuildContext context,
    WidgetRef ref,
    LeerlingNotificatieVoorkeuren voorkeuren,
  ) async {
    try {
      await ref
          .read(notificatieInstellingenProvider.notifier)
          .opslaanEmail(voorkeuren);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        'E-mailvoorkeuren opslaan mislukt. Probeer het opnieuw.',
        isError: true,
      );
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
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    super.key,
    this.enabled = true,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $subtitle',
      toggled: value,
      enabled: enabled,
      onTap: enabled ? () => onChanged(!value) : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context)
                            .withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Zelfde schakelaar als de Instructeur-app (FramerToggle).
              FramerToggle(
                value: value,
                onChanged: enabled ? onChanged : null,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ],
          ),
        ),
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
          Icon(icon, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
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
