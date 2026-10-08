import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../features/notificaties/notificatie_instellingen_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/settings_design.dart';
import '../../shared/widgets/snackbar.dart';
import 'widgets/profiel_menu_widgets.dart';
import 'widgets/settings_action_row.dart';
import '../../core/constants/cool_icons.dart';

class BeveiligingScreen extends ConsumerStatefulWidget {
  const BeveiligingScreen({super.key});

  @override
  ConsumerState<BeveiligingScreen> createState() => _BeveiligingScreenState();
}

class _BeveiligingScreenState extends ConsumerState<BeveiligingScreen> {
  bool _resetLaden = false;
  bool _uitloggenLaden = false;

  String? get _authEmail {
    final email = StudentService.currentUser?.email?.trim();
    return email == null || email.isEmpty ? null : email;
  }

  Future<void> _stuurReset() async {
    final email = _authEmail;
    if (email == null || _resetLaden) return;

    setState(() => _resetLaden = true);
    try {
      await StudentService.stuurWachtwoordReset(email);
      if (mounted) {
        showAppSnackBar(
          context,
          'De resetlink is verstuurd. Controleer ook je spammap.',
          isSuccess: true,
        );
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Het versturen van de resetlink is mislukt. Probeer het later opnieuw.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _resetLaden = false);
    }
  }

  Future<void> _toonAccountInfo() async {
    final email = _authEmail;
    if (email == null || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingelogd account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'E-mailadres',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  email,
                  semanticsLabel: 'Ingelogd e-mailadres $email',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _bevestigUitloggen() async {
    if (_uitloggenLaden) return;

    final bevestig = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uitloggen op dit apparaat?'),
        content: const Text(
          'Je wordt uitgelogd op dit apparaat. Andere apparaten blijven ingelogd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uitloggen'),
          ),
        ],
      ),
    );
    if (bevestig != true || !mounted) return;

    setState(() => _uitloggenLaden = true);
    try {
      await StudentService.uitloggen();
      ref.invalidate(notificatieInstellingenProvider);
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Uitloggen lukt niet. Probeer het opnieuw.',
          isError: true,
        );
        setState(() => _uitloggenLaden = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authEmail;

    // Alleen acties, geen bewerkbare velden: dus geen groen vinkje. Het
    // wachtwoord wijzig je via een resetlink per e-mail (geen in-app veld).
    return SettingsScaffold(
      titel: 'Beveiliging',
      children: [
        SettingsWaarde(
          label: 'E-mailadres',
          waarde: email ?? 'Geen e-mailadres beschikbaar',
        ),
        const SizedBox(height: 24),
        ProfielMenuCard(
          children: [
            SettingsActionRow(
              key: const Key('beveiliging_ingelogd_account'),
              icon: CoolIcons.user01,
              title: 'Ingelogd account',
              subtitle: 'Bekijk je accountinformatie',
              semanticLabel: 'Ingelogd account',
              onTap: email == null ? null : _toonAccountInfo,
            ),
            const Divider(height: 1, indent: 62),
            SettingsActionRow(
              key: const Key('beveiliging_wachtwoord_herstellen'),
              icon: CoolIcons.lock,
              title: 'Wachtwoord herstellen',
              subtitle: _resetLaden
                  ? 'Resetlink wordt verstuurd...'
                  : 'Stuur een resetlink naar je e-mailadres',
              semanticLabel: 'Wachtwoord herstellen',
              onTap: email == null || _resetLaden ? null : _stuurReset,
            ),
            const Divider(height: 1, indent: 62),
            SettingsActionRow(
              key: const Key('beveiliging_uitloggen'),
              icon: CoolIcons.logOut,
              title: 'Uitloggen op dit apparaat',
              subtitle: _uitloggenLaden
                  ? 'Uitloggen wordt uitgevoerd...'
                  : 'Je wordt uitgelogd op dit apparaat',
              semanticLabel: 'Uitloggen op dit apparaat',
              onTap: _uitloggenLaden ? null : _bevestigUitloggen,
            ),
          ],
        ),
      ],
    );
  }
}
