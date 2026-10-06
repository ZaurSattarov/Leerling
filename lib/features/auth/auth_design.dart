import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class AuthDesign {
  AuthDesign._();

  static const Color focusBorder = Color(0xFFCBD5E1);
  static const Color strongFocusBorder = Color(0xFF94A3B8);
  static const Color error = Color(0xFFDC2626);
  static const Color errorText = Color(0xFF991B1B);
  static const Color placeholder = Color(0xFF64748B);
  static const Color icon = Color(0xFF64748B);
  static const Color border = Color(0xFFE5E7EB);
  static const Color pressed = Color(0xFFF1F1F1);

  static final RegExp emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp dutchPhonePattern = RegExp(r'^(?:\+31|0031|31|0)6\d{8}$');

  static InputDecoration inputDecoration({
    required String hint,
    IconData? iconData,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder borderFor(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: placeholder),
      prefixIcon: iconData == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(iconData, color: icon, size: 20),
            ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 52,
        minHeight: 52,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 52,
        minHeight: 52,
      ),
      filled: true,
      fillColor: Colors.white,
      border: borderFor(border),
      enabledBorder: borderFor(border),
      focusedBorder: borderFor(focusBorder, width: 1.5),
      errorBorder: borderFor(error.withValues(alpha: 0.6)),
      focusedErrorBorder: borderFor(error, width: 1.5),
      errorStyle: GoogleFonts.inter(
        color: errorText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.black.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Colors.white.withValues(alpha: 0.08);
        }
        return null;
      }),
    );
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vul je e-mailadres in';
    if (!emailPattern.hasMatch(email)) return 'Ongeldig e-mailadres';
    return null;
  }

  static String? validateDutchPhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Vul je telefoonnummer in';
    final compact = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!dutchPhonePattern.hasMatch(compact)) {
      return 'Vul een geldig NL telefoonnummer in';
    }
    return null;
  }
}
