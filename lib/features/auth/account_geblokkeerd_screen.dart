import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

/// Klantio Intern Beheerplatform — accountblokkade (Optie B, 2026-09-01).
///
/// Toont een nette, expliciete melding wanneer de auth-redirect detecteert
/// dat `access_status` niet 'active' is. De gebruiker is op dat moment al
/// server-side uitgelogd (zie _AuthNotifier in app.dart) — deze route
/// bestaat uitsluitend om die uitleg te tonen, geen eigen inlog-/
/// koppelcode-/profielafrondingslogica.
class AccountGeblokkeerdScreen extends StatelessWidget {
  const AccountGeblokkeerdScreen({super.key, required this.accessStatus});

  /// 'blocked' of 'suspended'.
  final String accessStatus;

  @override
  Widget build(BuildContext context) {
    final isSuspended = accessStatus == 'suspended';
    final title = isSuspended
        ? 'Je Klantio-account is tijdelijk opgeschort.'
        : 'Je Klantio-account is geblokkeerd.';

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuspended ? Icons.pause_circle_outline : Icons.block,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Neem contact op met Klantio Support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Terug naar inloggen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
