// Toast notificatie systeem -- 1-op-1 uit de Instructeur-app
// (rijschool-planner-flutter/lib/shared/widgets/toast.dart).
// Gebruik: AppToast.succes(context, 'Opgeslagen!')
// Types: succes, fout, info, waarschuwing

import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/cool_icons.dart';

enum ToastType { succes, fout, info, waarschuwing }

class AppToast {
  static void succes(BuildContext context, String bericht) {
    _toon(context, bericht, ToastType.succes);
  }

  static void fout(BuildContext context, String bericht) {
    _toon(context, bericht, ToastType.fout);
  }

  static void info(BuildContext context, String bericht) {
    _toon(context, bericht, ToastType.info);
  }

  static void waarschuwing(BuildContext context, String bericht) {
    _toon(context, bericht, ToastType.waarschuwing);
  }

  static void _toon(BuildContext context, String bericht, ToastType type) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        bericht: bericht,
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  final String bericht;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.bericht,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  Timer? _sluitTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _sluitTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _sluitTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  (Color bg, Color border, Color text, Color iconColor, IconData icon)
      get _stijl => switch (widget.type) {
            ToastType.succes => (
                const Color(0xFFF8FAFC),
                const Color(0xFFE5E7EB),
                const Color(0xFF111111),
                const Color(0xFF16A34A),
                CoolIcons.circleCheck,
              ),
            ToastType.fout => (
                const Color(0xFFF8FAFC),
                const Color(0xFFE5E7EB),
                const Color(0xFF111111),
                const Color(0xFFDC2626),
                CoolIcons.circleWarning,
              ),
            ToastType.info => (
                const Color(0xFFF8FAFC),
                const Color(0xFFE5E7EB),
                const Color(0xFF111111),
                const Color(0xFF2563EB),
                CoolIcons.info,
              ),
            ToastType.waarschuwing => (
                const Color(0xFFF8FAFC),
                const Color(0xFFE5E7EB),
                const Color(0xFF111111),
                const Color(0xFFF59E0B),
                CoolIcons.triangleWarning,
              ),
          };

  @override
  Widget build(BuildContext context) {
    final (bg, border, text, iconColor, icon) = _stijl;

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icoonachtergrond is altijd neutraal grijs — ernst wordt
                  // uitsluitend via de icoonkleur zelf aangegeven, nooit via
                  // een pastel-getinte achtergrond (designsysteemregel).
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(icon, size: 17, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.bericht,
                      style: TextStyle(
                        color: text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
