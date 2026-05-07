import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/factuur_status.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  factory StatusPill.les(LesStatus status) {
    return switch (status) {
      LesStatus.gepland => const StatusPill(
          label: 'Gepland',
          backgroundColor: AppColors.infoSolid,
          textColor: AppColors.white,
        ),
      LesStatus.afgerond => const StatusPill(
          label: 'Afgerond',
          backgroundColor: AppColors.successSolid,
          textColor: AppColors.white,
        ),
      LesStatus.geannuleerd => const StatusPill(
          label: 'Geannuleerd',
          backgroundColor: AppColors.dark3,
          textColor: AppColors.white,
        ),
      LesStatus.verzet => const StatusPill(
          label: 'Verzet',
          backgroundColor: AppColors.dark3,
          textColor: AppColors.white,
        ),
      LesStatus.geen_toon => const StatusPill(
          label: 'Geen toon',
          backgroundColor: AppColors.dark3,
          textColor: AppColors.white,
        ),
    };
  }

  factory StatusPill.factuur(FactuurStatus status) {
    final ui = status.ui;
    return StatusPill(
      label: ui.label,
      backgroundColor: ui.backgroundColor,
      textColor: ui.textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
