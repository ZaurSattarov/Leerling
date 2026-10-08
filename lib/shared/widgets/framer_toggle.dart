import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// 1-op-1 Framer Toggle (gebaseerd op https://swift-sphere-965446.framer.app)
/// Met vloeiende spring-animatie, capsule track, 0.5px border thumb met schaduw,
/// en instelbare actieve merkkleur (standaard [AppColors.primary]).
class FramerToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const FramerToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width = 44,
    this.height = 24,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<FramerToggle> createState() => _FramerToggleState();
}

class _FramerToggleState extends State<FramerToggle> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.onChanged == null) return;
    HapticFeedback.lightImpact();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onChanged != null;
    final activeBg = widget.activeColor ?? const Color(0xFF34C759);
    // Framer default off color: rgb(79, 79, 79) = #4F4F4F
    final inactiveBg = widget.inactiveColor ??
        (isDark ? const Color(0xFF3F3F46) : const Color(0xFF4F4F4F));

    const trackPadding = 3.5;
    final thumbSize = widget.height - (trackPadding * 2);
    final pressedThumbWidth = thumbSize * 1.3;

    return Padding(
      padding: widget.padding,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? _handleTap : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.value ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxThumbX = constraints.maxWidth -
                    trackPadding -
                    (_isPressed ? pressedThumbWidth : thumbSize);
                const minThumbX = trackPadding;
                final thumbLeft = widget.value ? maxThumbX : minThumbX;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: thumbLeft,
                      top: trackPadding,
                      width: _isPressed ? pressedThumbWidth : thumbSize,
                      height: thumbSize,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFEDEDED),
                            width: 0.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000), // rgba(0,0,0,0.15)
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                            BoxShadow(
                              color: Color(0x1A000000), // rgba(0,0,0,0.10)
                              blurRadius: 2,
                              offset: Offset(0, -1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Drop-in vervanger voor [SwitchListTile] met 1-op-1 Framer Toggle stijl.
class FramerSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final EdgeInsetsGeometry contentPadding;
  final Color? activeColor;
  final Color? inactiveColor;

  const FramerSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.contentPadding = EdgeInsets.zero,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: contentPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (secondary != null) ...[
              secondary!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    subtitle!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            FramerToggle(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ],
        ),
      ),
    );
  }
}
