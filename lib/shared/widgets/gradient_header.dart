import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Gedeelde gradient header voor alle detail-schermen (met terugpijl).
///
/// Gebruik binnen [CustomScrollView]:
///   SliverToBoxAdapter(child: DetailGradientHeader(...))
///
/// Gebruik in een [Column]:
///   DetailGradientHeader(...)
class DetailGradientHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  /// Extra content onder de titel-rij (bijv. datum + tijd in LesDetail).
  final Widget? extra;

  const DetailGradientHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141C2B), Color(0xFF1A2D42)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: onBack ??
                        () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (extra != null) extra!,
            ],
          ),
        ),
      ),
    );
  }
}
