import 'package:flutter/widgets.dart';

/// Micro-interactie uit de Instructeur-app: een tikbaar element veert kort in
/// (schaal [pressedScale]) zolang de vinger erop staat -- dezelfde respons
/// als de navbar-tabs en de profieltegels daar. Geen Material-rimpel.
class KlantioPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const KlantioPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.98,
  });

  @override
  State<KlantioPressable> createState() => _KlantioPressableState();
}

class _KlantioPressableState extends State<KlantioPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
