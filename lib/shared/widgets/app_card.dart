import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/cool_icons.dart';

/// Kaartstijl van het Klantio-design-systeem (Instructeur-app): wit vlak,
/// 12px radius, 1px rand ([AppColors.border]), geen schaduw. Tikbare kaarten
/// krijgen dezelfde micro-interactie als de Instructeur-app: kort indrukken
/// (schaal 0.98) i.p.v. een Material-rimpel.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  static const double radius = 12;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppCard.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: card,
      ),
    );
  }
}

/// Icoon zonder achtergrondvlak -- 1-op-1 zoals `AppIcon` in de
/// Instructeur-app: alleen het (coolicons-)icoon, gecentreerd in een vaste
/// tikzone, in de vaste icoonkleur [AppColors.iconPrimary]. Geen grijs of
/// gekleurd vlak eromheen.
class IconBadge extends StatelessWidget {
  final IconData icon;

  /// Alleen voor echte statuskleuren (bv. rood bij een fout). Het merkroze
  /// en de oude icoon-aliassen vallen terug op [AppColors.iconPrimary].
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.5;
    final iconColor =
        color == AppColors.primary ? AppColors.iconPrimary : color;
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: Icon(icon, color: iconColor, size: iconSize)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            // Sectielabel-stijl van de Instructeur-app (_ProfileDesign.sectionTitle).
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B8089),
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(CoolIcons.arrowRightMd,
                    size: 14, color: AppColors.iconPrimary),
              ],
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              child: Icon(icon, size: 40, color: AppColors.iconPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2.5, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFFEDEDED),
              Color(0xFFF7F7F7),
              Color(0xFFEDEDED),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(height: 40, width: 40, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 14, width: 140),
                    SizedBox(height: 6),
                    SkeletonBox(height: 12, width: 100),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
