import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/les.dart';

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

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: spec.background,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: spec.background.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              spec.label,
              textAlign: TextAlign.center,
              strutStyle: const StrutStyle(
                fontSize: 11,
                height: 1,
                forceStrutHeight: true,
              ),
              style: const TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
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
          background: AppColors.successSolid,
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
