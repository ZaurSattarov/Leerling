import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NeutralChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const NeutralChip({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.neutralBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class InlineCtaLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const InlineCtaLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AccentProgressBar extends StatelessWidget {
  final double value;
  final double minHeight;

  const AccentProgressBar({
    super.key,
    required this.value,
    this.minHeight = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: minHeight,
        backgroundColor: AppColors.borderLight,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}
