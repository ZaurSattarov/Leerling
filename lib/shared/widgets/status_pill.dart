import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
          backgroundColor: AppColors.infoBg,
          textColor: AppColors.infoText,
        ),
      LesStatus.afgerond => const StatusPill(
          label: 'Afgerond',
          backgroundColor: AppColors.successBg,
          textColor: AppColors.successText,
        ),
      LesStatus.geannuleerd => const StatusPill(
          label: 'Geannuleerd',
          backgroundColor: AppColors.neutralBg,
          textColor: AppColors.neutralText,
        ),
      LesStatus.geen_toon => const StatusPill(
          label: 'Geen toon',
          backgroundColor: AppColors.dangerBg,
          textColor: AppColors.dangerText,
        ),
    };
  }

  factory StatusPill.factuur(FactuurStatus status) {
    return switch (status) {
      FactuurStatus.concept => const StatusPill(
          label: 'Concept',
          backgroundColor: Color(0xFFFFE4EA),
          textColor: AppColors.primary,
        ),
      FactuurStatus.verstuurd => const StatusPill(
          label: 'Verstuurd',
          backgroundColor: AppColors.infoBg,
          textColor: AppColors.infoText,
        ),
      FactuurStatus.betaald => const StatusPill(
          label: 'Betaald',
          backgroundColor: AppColors.successBg,
          textColor: AppColors.successText,
        ),
      FactuurStatus.verlopen => const StatusPill(
          label: 'Verlopen',
          backgroundColor: AppColors.dangerBg,
          textColor: AppColors.dangerText,
        ),
    };
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
