import 'package:flutter/material.dart';

/// Kleurtokens -- 1-op-1 het Klantio-design-systeem van de Instructeur-app
/// (rijschool-planner-flutter/lib/core/constants/app_colors.dart). Alleen
/// [splashBackground] en de extra icoon-aliassen zijn Leerling-eigen.
class AppColors {
  AppColors._();

  // Brand primary accent
  static const Color primary = Color(0xFFD72F62);
  static const Color primaryLight = Color(0xFFFFF0F4);
  static const Color primaryDark = Color(0xFFC02856);
  static const Color accent = Color(0xFF1A2332);

  // Dark theme
  static const Color dark = Color(0xFF0F1629);
  static const Color dark2 = Color(0xFF1A2332);
  static const Color dark3 = Color(0xFF2F3A4C);

  // Splashscreen-achtergrond van de Leerling-app: hetzelfde donker als het
  // app-icoon ("Behaald"), zodat icoon -> splash naadloos overloopt.
  static const Color splashBackground = Color(0xFF1C2636);

  // Light theme backgrounds (Klantio Admin Dashboard 1-op-1: pure white canvas)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF1F1F1);
  static const Color shadow = Color(0x0C0F172A);

  // Dark theme tokens (Klantio Admin Dashboard .dark 1-op-1)
  static const Color darkBackground = Color(0xFF161922);
  static const Color darkSurface = Color(0xFF1E2330);
  static const Color darkCard = Color(0xFF1E2330);
  static const Color darkBorder = Color(0xFF2D3748);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);
  static const Color darkTextMuted = Color(0xFF475569);

  // Text (Klantio Admin Dashboard 1-op-1)
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF8A8A8E);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFFD1D5DB);

  // Thema-icoon accent — vervangt rode primary voor icon-only gebruik (#1C2938)
  static const Color iconAccent = Color(0xFF1C2938);

  // Icon colors
  static const Color iconPrimary = Color(0xFF111827);
  static const Color iconBlue = Color(0xFF111827);
  static const Color iconGreen = Color(0xFF111827);
  static const Color iconOrange = Color(0xFF111827);
  static const Color iconRed = Color(0xFF111827);
  static const Color iconDark = Color(0xFF111827);
  static const Color iconTeal = Color(0xFF111827);
  static const Color iconPurple = Color(0xFF111827);
  static const Color iconAmber = Color(0xFF111827);
  static const Color iconSlate = Color(0xFF111827);

  // Soft icon surfaces for the global SaaS visual language (Admin dashboard title/table bar: #F1F1F1)
  static const Color iconPrimaryBg = Color(0xFFF1F1F1);
  static const Color iconBlueBg = Color(0xFFF1F1F1);
  static const Color iconGreenBg = Color(0xFFF1F1F1);
  static const Color iconOrangeBg = Color(0xFFF1F1F1);
  static const Color iconRedBg = Color(0xFFF1F1F1);
  static const Color iconNeutralBg = Color(0xFFF1F1F1);

  // Status: success
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successText = Color(0xFF065F46);
  static const Color successBorder = Color(0xFFD1FAE5);

  static const Color successSolid =
      Color(0xFF16A34A); // alias for badge semantic clarity

  // Status: danger
  static const Color dangerSolid =
      Color(0xFFDC2626); // solid red for danger badges/chips
  static const Color dangerBg = Color(0xFFFEF2F2); // soft crisp danger bg
  static const Color dangerText =
      Color(0xFF991B1B); // deep readable crimson text
  static const Color dangerBorder = Color(0xFFFECACA); // soft elegant border
  static const Color dangerBorderSubtle = Color(0xFFFEE2E2);

  // Status: warning
  static const Color warningBg = Color(0xFFFFF9EC);
  static const Color warningText = Color(0xFF92400E);
  static const Color warningBorder = Color(0xFFFEF3C7);
  static const Color warningSolid = Color(0xFFF59E0B);

  // Status: info
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoText = Color(0xFF1D4ED8);
  static const Color infoBorder = Color(0xFFDEEBFF);
  static const Color infoSolid = Color(0xFF3B82F6);

  // Status: neutral (Single unified grey title/header bar: #F1F1F1)
  static const Color neutralBg = Color(0xFFF1F1F1);
  static const Color neutralText = Color(0xFF6B7280);

  // WhatsApp
  static const Color whatsapp = Color(0xFF25D366);

  // Stripe/payment
  static const Color stripe = Color(0xFF635BFF);

  // Chart
  static const Color graphPurple = Color(0xFF7B61FF);
  static const Color graphYellow = Color(0xFFFFB800);

  // Loading / progress
  static const Color loadingPrimary = Color(0x29222936);
  static const Color loadingSecondary = Color(0x14222936);
  static const Color loadingAccent = primary;
}

class AppTheme {
  AppTheme._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? AppColors.darkBackground : AppColors.surface;

  static Color card(BuildContext context) =>
      isDark(context) ? AppColors.darkCard : AppColors.cardBg;

  static Color border(BuildContext context) =>
      isDark(context) ? AppColors.darkBorder : AppColors.border;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? AppColors.darkTextPrimary : AppColors.textPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? AppColors.darkTextSecondary : AppColors.textSecondary;

  static Color iconBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF283244) : AppColors.iconPrimaryBg;
}
