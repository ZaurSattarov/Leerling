import 'package:flutter/material.dart';

import '../../models/factuur.dart';
import '../constants/app_colors.dart';

class FactuurStatusUi {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData icon;

  const FactuurStatusUi({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    this.borderColor,
  });
}

extension FactuurStatusUiMapper on FactuurStatus {
  FactuurStatusUi get ui {
    return switch (this) {
      FactuurStatus.concept ||
      FactuurStatus.verstuurd ||
      FactuurStatus.open =>
        const FactuurStatusUi(
          label: 'Openstaand',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.warningSolid,
          borderColor: Color(0xFFE2E2E7),
          icon: Icons.schedule_rounded,
        ),
      FactuurStatus.betaald => const FactuurStatusUi(
          label: 'Betaald',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.successSolid,
          borderColor: Color(0xFFE2E2E7),
          icon: Icons.check_circle_rounded,
        ),
      FactuurStatus.verlopen || FactuurStatus.teLaat => const FactuurStatusUi(
          label: 'Te laat',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.dangerSolid,
          borderColor: Color(0xFFE2E2E7),
          icon: Icons.warning_amber_rounded,
        ),
      FactuurStatus.geannuleerd => const FactuurStatusUi(
          label: 'Geannuleerd',
          backgroundColor: Color(0xFFF0F2F5),
          textColor: AppColors.textSecondary,
          borderColor: Color(0xFFE2E2E7),
          icon: Icons.cancel_outlined,
        ),
    };
  }
}
