import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/factuur_status.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';

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

  factory StatusPill.les(LesStatus status) {
    return switch (status) {
      LesStatus.gepland => const StatusPill(
          label: 'Gepland',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.textPrimary,
          borderColor: Color(0xFFE2E2E7),
        ),
      LesStatus.afgerond => const StatusPill(
          label: 'Afgerond',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.successSolid,
          borderColor: Color(0xFFE2E2E7),
        ),
      LesStatus.geannuleerd => const StatusPill(
          label: 'Geannuleerd',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.textSecondary,
          borderColor: Color(0xFFE2E2E7),
        ),
      LesStatus.verzet => const StatusPill(
          label: 'Verzet',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.textSecondary,
          borderColor: Color(0xFFE2E2E7),
        ),
      LesStatus.geen_toon => const StatusPill(
          label: 'Geen toon',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.dangerSolid,
          borderColor: Color(0xFFE2E2E7),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 0.75)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
