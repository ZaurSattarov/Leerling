import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/factuur_status.dart';
import '../../models/les.dart';
import '../../models/examen.dart';
import '../../models/factuur.dart';
import 'status_badge.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool glow;

  const StatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.glow = false,
  });

  /// Zelfde solide statuskleuren als de Instructeur-app (StatusPill.les).
  factory StatusPill.les(LesStatus status, {bool glow = false}) {
    return switch (status) {
      LesStatus.gepland => StatusPill(
          label: 'Gepland',
          backgroundColor: AppColors.infoSolid,
          textColor: Colors.white,
          glow: glow,
        ),
      LesStatus.afgerond => StatusPill(
          label: 'Afgerond',
          backgroundColor: Color(0xFF4F46E5),
          textColor: Colors.white,
          glow: glow,
        ),
      LesStatus.geannuleerd => StatusPill(
          label: 'Geannuleerd',
          backgroundColor: AppColors.dangerSolid,
          textColor: Colors.white,
          glow: glow,
        ),
      LesStatus.verzet => StatusPill(
          label: 'Verzet',
          backgroundColor: AppColors.infoSolid,
          textColor: Colors.white,
          glow: glow,
        ),
      LesStatus.geen_toon => StatusPill(
          label: 'Niet verschenen',
          backgroundColor: Color(0xFF991B1B),
          textColor: Colors.white,
          glow: glow,
        ),
    };
  }

  /// Zelfde examenstatus-kleuren als de Instructeur-app (StatusPill.examen):
  /// gepland neutraal grijs, geslaagd groen, gezakt rood.
  factory StatusPill.examen(ExamenStatus status, {bool glow = false}) {
    return switch (status) {
      ExamenStatus.gepland => StatusPill(
          label: 'Gepland',
          backgroundColor: AppColors.neutralBg,
          textColor: AppColors.neutralText,
          glow: glow,
        ),
      ExamenStatus.geslaagd => StatusPill(
          label: 'Geslaagd',
          backgroundColor: AppColors.success,
          textColor: Colors.white,
          glow: glow,
        ),
      ExamenStatus.gezakt => StatusPill(
          label: 'Gezakt',
          backgroundColor: Color(0xFFE11D48),
          textColor: Colors.white,
          glow: glow,
        ),
    };
  }

  factory StatusPill.factuur(FactuurStatus status, {bool glow = false}) {
    final ui = status.ui;
    return StatusPill(
      label: ui.label,
      backgroundColor: ui.backgroundColor,
      textColor: ui.textColor,
      borderColor: ui.borderColor,
      glow: glow,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solide, uppercase badge -- zelfde weergave als StatusBadge in de
    // Instructeur-app (kleurvlak + lichte gekleurde gloed).
    return StatusBadge(
      label: label,
      backgroundColor: backgroundColor,
      textColor: textColor,
      glow: glow,
    );
  }
}
