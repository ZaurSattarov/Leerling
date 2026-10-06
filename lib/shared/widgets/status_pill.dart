import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/factuur_status.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';
import 'status_badge.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  /// Zelfde solide statuskleuren als de Instructeur-app (StatusPill.les).
  factory StatusPill.les(LesStatus status) {
    return switch (status) {
      LesStatus.gepland => const StatusPill(
          label: 'Gepland',
          backgroundColor: AppColors.infoSolid,
          textColor: Colors.white,
        ),
      LesStatus.afgerond => const StatusPill(
          label: 'Afgerond',
          backgroundColor: Color(0xFF4F46E5),
          textColor: Colors.white,
        ),
      LesStatus.geannuleerd => const StatusPill(
          label: 'Geannuleerd',
          backgroundColor: AppColors.dangerSolid,
          textColor: Colors.white,
        ),
      LesStatus.verzet => const StatusPill(
          label: 'Verzet',
          backgroundColor: AppColors.infoSolid,
          textColor: Colors.white,
        ),
      LesStatus.geen_toon => const StatusPill(
          label: 'No show',
          backgroundColor: Color(0xFF991B1B),
          textColor: Colors.white,
        ),
    };
  }

  factory StatusPill.factuur(FactuurStatus status) {
    final ui = status.ui;
    return StatusPill(
      label: ui.label,
      backgroundColor: ui.backgroundColor,
      textColor: ui.textColor,
      borderColor: ui.borderColor,
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
    );
  }
}
