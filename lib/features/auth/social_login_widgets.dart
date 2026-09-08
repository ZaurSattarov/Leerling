import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// Gedeelde social-login-widgets, gebruikt op zowel het inlog- als het
/// registratiescherm (2026-09-08, professionele/consistente social-auth-UX).
///
/// Google en Facebook gebruiken dezelfde knop voor bestaande én nieuwe
/// gebruikers -- de OAuth-provider/Supabase bepaalt zelf of het om een
/// login of een nieuwe account-aanmaak gaat (`signInWithIdToken`/
/// `signInWithOAuth` maken automatisch een nieuwe `auth.users`-rij aan als
/// er nog geen account met dat e-mailadres bestaat, en hergebruiken anders
/// de bestaande). Er bestaat daarom bewust GEEN aparte "Registreren met
/// Google/Facebook"-variant -- vandaar de generieke "Doorgaan met ..."-tekst
/// op beide schermen.
class SocialLoginRij extends StatelessWidget {
  final VoidCallback? googleAan;
  final VoidCallback? facebookAan;

  const SocialLoginRij({
    super.key,
    required this.googleAan,
    required this.facebookAan,
  });

  Widget _googleKnop() {
    return SocialLoginKnop(
      label: 'Doorgaan met Google',
      onPressed: googleAan,
      child: Image.asset(
        'assets/icons/google_logo.png',
        height: 22,
        width: 22,
      ),
    );
  }

  Widget _facebookKnop() {
    return SocialLoginKnop(
      label: 'Doorgaan met Facebook',
      onPressed: facebookAan,
      // Officieel, herkenbaar Facebook-logo (ingebouwd Material-icoon, geen
      // los asset nodig) in het officiële Facebook-blauw.
      child: const Icon(
        Icons.facebook,
        size: 26,
        color: Color(0xFF1877F2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Google en Facebook altijd naast elkaar, op zowel Android als iOS --
    // zelfde rij-opbouw/styling als voorheen (Expanded + 12px tussenruimte).
    return Row(
      children: [
        Expanded(child: _googleKnop()),
        const SizedBox(width: 12),
        Expanded(child: _facebookKnop()),
      ],
    );
  }
}

class OfScheiding extends StatelessWidget {
  const OfScheiding({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.textHint.withValues(alpha: 0.3)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'of',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textHint.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

class SocialLoginKnop extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget child;

  const SocialLoginKnop({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hoogte = MediaQuery.sizeOf(context).height < 700 ? 48.0 : 52.0;
    return SizedBox(
      height: hoogte,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Semantics(
            button: true,
            label: label,
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
