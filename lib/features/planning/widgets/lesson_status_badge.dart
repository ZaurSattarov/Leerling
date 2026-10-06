import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/les.dart';
import '../../../shared/widgets/status_badge.dart';

class LessonStatusBadge extends StatelessWidget {
  final LesStatus status;
  final bool isNext;

  const LessonStatusBadge({
    super.key,
    required this.status,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = isNext ? _BadgeSpec.next() : _BadgeSpec.forStatus(status);
    // Zelfde solide, uppercase badge als de Instructeur-app (StatusBadge).
    return StatusBadge(label: spec.label, backgroundColor: spec.background);
  }
}

class _BadgeSpec {
  final String label;
  final Color background;

  const _BadgeSpec({
    required this.label,
    required this.background,
  });

  factory _BadgeSpec.next() {
    return const _BadgeSpec(
      label: 'Volgende',
      background: AppColors.primary,
    );
  }

  factory _BadgeSpec.forStatus(LesStatus status) {
    return switch (status) {
      LesStatus.gepland => const _BadgeSpec(
          label: 'Gepland',
          background: AppColors.infoSolid,
        ),
      LesStatus.afgerond => const _BadgeSpec(
          label: 'Afgerond',
          background: Color(0xFF4F46E5),
        ),
      LesStatus.geannuleerd => const _BadgeSpec(
          label: 'Geannuleerd',
          background: AppColors.dangerSolid,
        ),
      LesStatus.verzet => const _BadgeSpec(
          label: 'Verzet',
          background: AppColors.warningSolid,
        ),
      LesStatus.geen_toon => const _BadgeSpec(
          label: 'Geen toon',
          background: Color(0xFF991B1B),
        ),
    };
  }
}
