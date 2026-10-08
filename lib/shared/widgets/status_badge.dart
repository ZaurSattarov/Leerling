import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/cool_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../models/les.dart';

/// Solide statusbadge -- 1-op-1 uit de Instructeur-app
/// (rijschool-planner-flutter/lib/shared/widgets/status_badge.dart): elke
/// status een vol kleurvlak met witte tekst, nooit pastel.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final IconData? icon;
  final bool uppercase;

  /// Zachte gekleurde gloed onder de badge; uit voor een vlakke badge.
  final bool glow;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    this.borderRadius = 8,
    this.icon,
    this.uppercase = true,
    this.glow = true,
  });

  factory StatusBadge.les(LesStatus status, {String? label}) =>
      switch (status) {
        LesStatus.gepland => StatusBadge.gepland(label: label ?? 'Gepland'),
        LesStatus.afgerond => StatusBadge.afgerond(label: label ?? 'Afgerond'),
        LesStatus.geannuleerd => StatusBadge.geannuleerd(
            label: label ?? 'Geannuleerd',
          ),
        LesStatus.verzet => StatusBadge.gepland(label: label ?? 'Verzet'),
        LesStatus.geen_toon => StatusBadge.noShow(label: label ?? 'No show'),
      };

  /// Gepland - solid SaaS blue + white.
  factory StatusBadge.gepland({String label = 'Gepland'}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.infoSolid,
      );

  /// Bevestigd - solid green + white.
  factory StatusBadge.bevestigd({String label = 'Bevestigd'}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.success,
      );

  /// In uitvoering - solid cyan + white.
  factory StatusBadge.inUitvoering({String label = 'In uitvoering'}) =>
      StatusBadge(
        label: label,
        backgroundColor: const Color(0xFF0891B2),
      );

  /// Actief - alias for in uitvoering.
  factory StatusBadge.actief({String label = 'Actief'}) => StatusBadge(
        label: label,
        backgroundColor: const Color(0xFF0891B2),
      );

  /// Gekoppeld - solid green + white + link icon.
  factory StatusBadge.gekoppeld({String label = 'Gekoppeld'}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.success,
        icon: CoolIcons.link,
      );

  /// Geslaagd - solid green + white + check icon.
  factory StatusBadge.geslaagd({String label = 'Geslaagd'}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.success,
        icon: CoolIcons.circleCheck,
      );

  /// Afgerond - solid indigo + white.
  factory StatusBadge.afgerond({String label = 'Afgerond'}) => StatusBadge(
        label: label,
        backgroundColor: const Color(0xFF4F46E5),
      );

  /// Betaald - solid green + white + check-circle icon.
  factory StatusBadge.betaald({String label = 'Betaald'}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.success,
        icon: CoolIcons.circleCheck,
      );

  /// Geannuleerd - solid danger red + white.
  factory StatusBadge.geannuleerd({String label = 'Geannuleerd'}) =>
      StatusBadge(
        label: label,
        backgroundColor: AppColors.dangerSolid,
      );

  /// Verlopen - solid orange + white.
  factory StatusBadge.verlopen({String label = 'Verlopen'}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.warningSolid,
      );

  /// No show - dark red + white.
  factory StatusBadge.noShow({String label = 'No show'}) => StatusBadge(
        label: label,
        backgroundColor: const Color(0xFF991B1B),
      );

  /// Warning - solid amber + white.
  factory StatusBadge.warning({required String label}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.warningSolid,
      );

  /// Info - solid blue + white.
  factory StatusBadge.info({required String label}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.infoSolid,
      );

  /// Neutral / Secondary - neutral bg + navy text (for inactive states).
  factory StatusBadge.neutral({required String label}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.dark3,
        textColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: fontSize + 2),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                height: 1,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
