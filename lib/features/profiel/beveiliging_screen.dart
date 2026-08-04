import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../features/notificaties/notificatie_instellingen_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'widgets/settings_action_row.dart';

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
                const Text(
                  'Ingelogd account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
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
                  style: const TextStyle(
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
    final bottom = MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const MainDetailHeader(
            eyebrowText: 'APP-INSTELLINGEN',
            title: 'Beveiliging',
            fallbackRoute: '/profiel/app-instellingen',
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
              children: [
                const _SectionTitle('WACHTWOORD'),
                _PasswordCard(
                  email: email,
                  loading: _resetLaden,
                  onReset: _stuurReset,
                ),
                const SizedBox(height: 24),
                const _SectionTitle('ACCOUNTBEVEILIGING'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsActionRow(
                        key: const Key('beveiliging_ingelogd_account'),
                        icon: Icons.person_outline_rounded,
                        title: 'Ingelogd account',
                        subtitle: 'Bekijk je accountinformatie',
                        semanticLabel: 'Ingelogd account',
                        onTap: email == null ? null : _toonAccountInfo,
                      ),
                      const Divider(height: 1, indent: 80),
                      SettingsActionRow(
                        key: const Key('beveiliging_wachtwoord_herstellen'),
                        icon: Icons.key_outlined,
                        title: 'Wachtwoord herstellen',
                        subtitle: 'Stel een nieuw wachtwoord in',
                        semanticLabel: 'Wachtwoord herstellen',
                        onTap:
                            email == null || _resetLaden ? null : _stuurReset,
                      ),
                      const Divider(height: 1, indent: 80),
                      SettingsActionRow(
                        key: const Key('beveiliging_uitloggen'),
                        icon: Icons.logout_rounded,
                        title: 'Uitloggen op dit apparaat',
                        subtitle: _uitloggenLaden
                            ? 'Uitloggen wordt uitgevoerd...'
                            : 'Je wordt uitgelogd op dit apparaat',
                        semanticLabel: 'Uitloggen op dit apparaat',
                        onTap: _uitloggenLaden ? null : _bevestigUitloggen,
                      ),
                    ],
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  final String? email;
  final bool loading;
  final VoidCallback onReset;

  const _PasswordCard({
    required this.email,
    required this.loading,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.lock_outline_rounded,
            color: AppColors.iconPrimary,
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wachtwoord herstellen',
                  semanticsLabel: 'Wachtwoord herstellen',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email == null
                      ? 'Er is geen e-mailadres beschikbaar voor dit account.'
                      : 'Wij sturen een veilige resetlink naar:\n$email',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 300
                        ? constraints.maxWidth * 0.62
                        : constraints.maxWidth;
                    return SizedBox(
                      width: width,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: email == null || loading ? null : onReset,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.mail_outline_rounded, size: 21),
                        label: Text(
                          loading ? 'Versturen...' : 'Resetlink versturen',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          disabledForegroundColor: AppColors.textHint,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
