import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand / actions
  static const Color primary = Color(0xFFE63946);
  static const Color primaryLight = Color(0xFF2A1620);
  static const Color primaryDark = Color(0xFFB91C1C);
  static const Color accent = Color(0xFFE63946);

  // Dark theme backgrounds
  static const Color dark = Color(0xFF0B1220);
  static const Color dark2 = Color(0xFF111827);
  static const Color dark3 = Color(0xFF1A2233);

  // Surfaces
  static const Color surface = Color(0xFF0B1220);
  static const Color pageBg = Color(0xFF0B1220);
  static const Color cardBg = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFF263244);
  static const Color borderLight = Color(0xFF334155);
  static const Color shadow = Color(0x66000000);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFFD1D5DB);

  // Icon colors
  static const Color iconPrimary = primary;
  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconGreen = Color(0xFF22C55E);
  static const Color iconOrange = Color(0xFFB45309);
  static const Color iconRed = primary;
  static const Color iconDark = dark3;
  static const Color iconTeal = Color(0xFF0D9488);
  static const Color iconPurple = Color(0xFF7C3AED);

  // Status: success
  static const Color successSolid = Color(0xFF22C55E);
  static const Color successBg = successSolid;
  static const Color successText = white;
  static const Color successBorder = successSolid;

  // Status: danger
  static const Color dangerSolid = primary;
  static const Color dangerBg = dangerSolid;
  static const Color dangerText = primary;
  static const Color dangerBorder = dangerSolid;

  // Status: warning
  static const Color warningSolid = Color(0xFFB45309);
  static const Color warningBg = warningSolid;
  static const Color warningText = white;
  static const Color warningBorder = warningSolid;

  // Status: info
  static const Color infoSolid = Color(0xFF2563EB);
  static const Color infoBg = infoSolid;
  static const Color infoText = white;
  static const Color infoBorder = infoSolid;

  // Status: neutral
  static const Color neutralBg = Color(0xFF1F2937);
  static const Color neutralText = white;

  // WhatsApp
  static const Color whatsapp = Color(0xFF22C55E);
}
