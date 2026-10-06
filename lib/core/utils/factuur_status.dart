import 'package:flutter/material.dart';

import '../../models/factuur.dart';
import '../constants/app_colors.dart';
import '../constants/cool_icons.dart';

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
          backgroundColor: AppColors.warningSolid,
          textColor: Colors.white,
          icon: CoolIcons.clock,
        ),
      FactuurStatus.betaald => const FactuurStatusUi(
          label: 'Betaald',
          backgroundColor: AppColors.success,
          textColor: Colors.white,
          icon: CoolIcons.circleCheck,
        ),
      FactuurStatus.verlopen || FactuurStatus.teLaat => const FactuurStatusUi(
          label: 'Te laat',
          backgroundColor: AppColors.dangerSolid,
          textColor: Colors.white,
          icon: CoolIcons.triangleWarning,
        ),
      FactuurStatus.geannuleerd => const FactuurStatusUi(
          label: 'Geannuleerd',
          backgroundColor: Color(0x1A222936),
          textColor: Color(0xFF222936),
          icon: CoolIcons.closeCircle,
        ),
    };
  }
}
