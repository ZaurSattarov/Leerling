import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isEmpty;
  final int maxValueLines;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isEmpty = false,
    this.maxValueLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final textStyle = TextStyle(
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
          fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        );

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              IconBadge(icon: icon, color: iconColor, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label(label),
                          const SizedBox(height: 5),
                          _ValueText(
                            value: value,
                            style: textStyle,
                            maxLines: maxValueLines,
                            textAlign: TextAlign.left,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 132, child: _Label(label)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _ValueText(
                                value: value,
                                style: textStyle,
                                maxLines: maxValueLines,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String label;

  const _Label(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        fontSize: 13,
        height: 1.3,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  final String value;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;

  const _ValueText({
    required this.value,
    required this.style,
    required this.maxLines,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      style: style,
    );
  }
}
