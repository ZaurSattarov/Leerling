import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand primary accent (aligned with Instrecteur)
  static const Color primary = Color(0xFFD63060);
  static const Color primaryLight = Color(0xFFFFF0F4);
  static const Color primaryDark = Color(0xFFC02856);
  static const Color accent = Color(0xFF1A2332);

  // Dark theme backgrounds (aligned with Instrecteur navy gradient)
  static const Color dark = Color(0xFF0F1629);
  static const Color dark2 = Color(0xFF1A2332);
  static const Color dark3 = Color(0xFF2F3A4C);

  // Exacte splashscreen-achtergrond van de Leerlingen-app (afwijkend van de
  // Instructeur-splash, die AppColors.primary als achtergrond gebruikt).
  static const Color splashBackground = Color(0xFF131528);

  // Light theme backgrounds (aligned with Instrecteur)
  static const Color surface = Color(0xFFF4F5F7);
  static const Color pageBg = Color(0xFFF4F5F7);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E7EC);
  static const Color borderLight = Color(0xFFEEF0F3);
  static const Color shadow = Color(0x120F172A);

  // Text (aligned with Instrecteur)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF5F6673);
  static const Color textHint = Color(0xFF9AA1AD);
  static const Color textMuted = Color(0xFFD1D5DB);

  // Icon colors (monochrome — aligned with Instrecteur)
  static const Color iconPrimary = Color(0xFF0F172A);
  static const Color iconBlue = Color(0xFF0F172A);
  static const Color iconGreen = Color(0xFF0F172A);
  static const Color iconOrange = Color(0xFF0F172A);
  static const Color iconRed = Color(0xFF0F172A);
  static const Color iconDark = Color(0xFF0F172A);
  static const Color iconTeal = Color(0xFF0F172A);
  static const Color iconPurple = Color(0xFF0F172A);
  static const Color iconAmber = Color(0xFF0F172A);
  static const Color iconSlate = Color(0xFF0F172A);

  // Soft icon surfaces for the global SaaS visual language
  static const Color iconPrimaryBg = Color(0xFFF4F5F7);
  static const Color iconBlueBg = Color(0xFFF4F5F7);
  static const Color iconGreenBg = Color(0xFFF4F5F7);
  static const Color iconOrangeBg = Color(0xFFF4F5F7);
  static const Color iconRedBg = Color(0xFFF4F5F7);
  static const Color iconNeutralBg = Color(0xFFF4F5F7);

  // Status: success
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successText = Color(0xFF065F46);
  static const Color successBorder = Color(0xFFD1FAE5);
  static const Color successSolid = Color(0xFF16A34A);

  // Status: danger
  static const Color dangerBg = Color(0xFFF3F4F6);
  static const Color dangerText = Color(0xFFB91C1C);
  static const Color dangerBorder = Color(0xFFCBD5E1);
  static const Color dangerSolid = Color(0xFFDC2626);

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

  // Status: neutral
  static const Color neutralBg = Color(0xFFF3F4F6);
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
