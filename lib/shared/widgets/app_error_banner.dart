import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/cool_icons.dart';

/// Herbruikbare SaaS-grade foutmelding banner.
/// Ontworpen met subtiele tinten, strakke borders en professionele typografie.
class AppErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;

  const AppErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // SaaS-grade professionele kleuren
    final bgColor = isDark ? const Color(0xFF1E2735) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final iconBgColor = isDark ? const Color(0xFF334155) : const Color(0xFFF0F2F5);
    final iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final closeHoverColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF111111).withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(
              CoolIcons.circleWarning,
              color: iconColor,
              size: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(6),
                splashColor: Colors.transparent,
                hoverColor: closeHoverColor,
                highlightColor: closeHoverColor,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    CoolIcons.closeCircle,
                    size: 16,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
