import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/support_thread.dart';

/// Gedeelde helpers voor de supportchat-schermen -- 1-op-1 stijl-poort van
/// de Instructeur-app (support_ui.dart). Kaartstijl zelf komt uit de
/// bestaande [AppCard]/[app_card.dart] (geen tweede, parallelle
/// kaartcomponent), dit bestand bevat alleen wat daar nog niet bestaat:
/// statuschip, primaire knop en datumformattering voor supportthreads.
class SupportUi {
  SupportUi._();

  static const iconBox = 36.0;
  static const iconBg = Color(0xFFF0F2F5);
  static const accent = Color(0xFF5645D4);

  static String formatWhen(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final time = DateFormat('HH:mm', 'nl').format(local);
    if (day == today) return 'Vandaag $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Gisteren $time';
    }
    return DateFormat("d MMM yyyy 'om' HH:mm", 'nl').format(local);
  }
}

class SupportStatusChip extends StatelessWidget {
  final SupportThreadStatus status;
  const SupportStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      SupportThreadStatus.waitingForSupport => (
          const Color(0xFFF0F2F5),
          AppColors.textSecondary,
        ),
      SupportThreadStatus.waitingForUser => (
          AppColors.infoSolid.withValues(alpha: 0.12),
          AppColors.infoSolid,
        ),
      SupportThreadStatus.closed => (
          const Color(0xFFF0F2F5),
          AppColors.textHint,
        ),
      SupportThreadStatus.open => (
          const Color(0xFFF0F2F5),
          AppColors.textSecondary,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class SupportPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const SupportPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.neutralBg,
          disabledForegroundColor: AppColors.textHint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
