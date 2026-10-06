import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';

class SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback? onTap;

  const SettingsActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.loadingPrimary;
          }
          return Colors.transparent;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                child: Icon(icon, color: AppColors.iconPrimary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  CoolIcons.chevronRight,
                  color: AppColors.iconPrimary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
