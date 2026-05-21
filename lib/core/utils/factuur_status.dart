import 'package:flutter/material.dart';

import '../../models/factuur.dart';
import '../constants/app_colors.dart';

class FactuurStatusUi {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const FactuurStatusUi({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}

extension FactuurStatusUiMapper on FactuurStatus {
  FactuurStatusUi get ui {
    return switch (this) {
      FactuurStatus.concept ||
      FactuurStatus.verstuurd ||
      FactuurStatus.open =>
        const FactuurStatusUi(
          label: 'Nog niet betaald',
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          icon: Icons.schedule_rounded,
        ),
      FactuurStatus.betaald => const FactuurStatusUi(
          label: 'Betaald',
          backgroundColor: AppColors.successSolid,
          textColor: Colors.white,
          icon: Icons.check_circle_rounded,
        ),
      FactuurStatus.verlopen || FactuurStatus.teLaat => const FactuurStatusUi(
          label: 'Te laat',
          backgroundColor: AppColors.dangerSolid,
          textColor: Colors.white,
          icon: Icons.warning_amber_rounded,
        ),
      FactuurStatus.geannuleerd => const FactuurStatusUi(
          label: 'Geannuleerd',
          backgroundColor: AppColors.neutralBg,
          textColor: AppColors.neutralText,
          icon: Icons.cancel_outlined,
        ),
    };
  }
}
