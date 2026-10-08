import 'package:flutter/material.dart';

/// Kleurtokens -- 1-op-1 het Klantio-design-systeem van de Instructeur-app
/// (rijschool-planner-flutter/lib/core/constants/app_colors.dart). Alleen
/// [splashBackground] en de extra icoon-aliassen zijn Leerling-eigen.
class AppColors {
  AppColors._();

  /// Wordt door de root van de app gezet (zie app.dart) zodat alle
  /// thema-afhankelijke tokens hieronder de actieve helderheid volgen.
  static bool isDarkMode = false;

  // Brand primary accent
  static const Color primary = Color(0xFFD72F62);
  static Color get primaryLight => isDarkMode ? const Color(0xFF3A1B28) : const Color(0xFFFFF0F4);
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
  static Color get surface => isDarkMode ? darkSurface : const Color(0xFFFFFFFF);
  static Color get pageBg => isDarkMode ? darkBackground : const Color(0xFFF5F5F5);
  static Color get cardBg => isDarkMode ? darkCard : const Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  /// Wit vlak (kaart/pil/knop) in licht thema, kaartkleur in donker thema.
  /// Gebruik [white] alleen voor tekst/iconen op gekleurde vlakken.
  static Color get panel => isDarkMode ? darkCard : white;
  static Color get border => isDarkMode ? darkBorder : const Color(0xFFE5E7EB);
  static Color get borderLight => isDarkMode ? const Color(0xFF263042) : const Color(0xFFF1F1F1);
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
  static Color get textPrimary => isDarkMode ? darkTextPrimary : const Color(0xFF111111);
  static Color get textSecondary => isDarkMode ? darkTextSecondary : const Color(0xFF8A8A8E);
  static Color get textHint => isDarkMode ? darkTextHint : const Color(0xFF9CA3AF);
  static Color get textMuted => isDarkMode ? darkTextMuted : const Color(0xFFD1D5DB);

  // Thema-icoon accent — vervangt rode primary voor icon-only gebruik (#1C2938)
  static const Color iconAccent = Color(0xFF1C2938);

  // Icon colors
  static Color get iconPrimary => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconBlue => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconGreen => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconOrange => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconRed => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconDark => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconTeal => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconPurple => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconAmber => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  static Color get iconSlate => isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);

  // Soft icon surfaces for the global SaaS visual language (Admin dashboard title/table bar: #F1F1F1)
  static Color get iconPrimaryBg => isDarkMode ? const Color(0xFF283244) : const Color(0xFFF1F1F1);
  static Color get iconBlueBg => isDarkMode ? const Color(0xFF283244) : const Color(0xFFF1F1F1);
  static Color get iconGreenBg => isDarkMode ? const Color(0xFF283244) : const Color(0xFFF1F1F1);
  static Color get iconOrangeBg => isDarkMode ? const Color(0xFF283244) : const Color(0xFFF1F1F1);
  static Color get iconRedBg => isDarkMode ? const Color(0xFF283244) : const Color(0xFFF1F1F1);
  static Color get iconNeutralBg => isDarkMode ? const Color(0xFF283244) : const Color(0xFFF1F1F1);

  // Status: success
  static const Color success = Color(0xFF16A34A);
  static Color get successBg => isDarkMode ? const Color(0xFF12332A) : const Color(0xFFECFDF5);
  static Color get successText => isDarkMode ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
  static Color get successBorder => isDarkMode ? const Color(0xFF1F4D3E) : const Color(0xFFD1FAE5);

  static const Color successSolid =
      Color(0xFF16A34A); // alias for badge semantic clarity

  // Status: danger
  static const Color dangerSolid =
      Color(0xFFDC2626); // solid red for danger badges/chips
  static Color get dangerBg => isDarkMode ? const Color(0xFF3A1D22) : const Color(0xFFFEF2F2);
  static Color get dangerText => isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
  static Color get dangerBorder => isDarkMode ? const Color(0xFF5C2A31) : const Color(0xFFFECACA);
  static Color get dangerBorderSubtle => isDarkMode ? const Color(0xFF4A2329) : const Color(0xFFFEE2E2);

  // Status: warning
  static Color get warningBg => isDarkMode ? const Color(0xFF3A2E14) : const Color(0xFFFFF9EC);
  static Color get warningText => isDarkMode ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
  static Color get warningBorder => isDarkMode ? const Color(0xFF54421A) : const Color(0xFFFEF3C7);
  static const Color warningSolid = Color(0xFFF59E0B);

  // Status: info
  static Color get infoBg => isDarkMode ? const Color(0xFF16294A) : const Color(0xFFEFF6FF);
  static Color get infoText => isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
  static Color get infoBorder => isDarkMode ? const Color(0xFF1E3A66) : const Color(0xFFDEEBFF);
  static const Color infoSolid = Color(0xFF3B82F6);

  // Status: neutral (Single unified grey title/header bar: #F1F1F1)
  static Color get neutralBg => isDarkMode ? const Color(0xFF283244) : const Color(0xFFF1F1F1);
  static Color get neutralText => isDarkMode ? darkTextSecondary : const Color(0xFF6B7280);

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
