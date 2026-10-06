import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import '../../core/providers/theme_provider.dart';

/// 1-op-1 vector replicatie van de Isomorphic Furyroad header iconen
/// uit het Klantio Admin Dashboard.
class IsomorphicBellIcon extends StatelessWidget {
  final bool hasUnread;
  final double size;
  final Color? domeColor;
  final Color? secondaryColor;
  final Color badgeColor;

  const IsomorphicBellIcon({
    super.key,
    this.hasUnread = true,
    this.size = 24,
    this.domeColor,
    this.secondaryColor,
    this.badgeColor = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    final domeHex = _colorToHex(domeColor ?? const Color(0xFF262626));
    final secHex = _colorToHex(secondaryColor ?? const Color(0xFF9CA3AF));
    final badgeHex = _colorToHex(badgeColor);

    final svgString = '''
<svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6.5 10C5.5 12.2 5.5 14.8 6.5 17" stroke="$secHex" stroke-width="2" stroke-linecap="round" />
  <path d="M13.5 25.5C13.5 26.9 14.6 28 16 28C17.4 28 18.5 26.9 18.5 25.5H13.5Z" fill="$secHex" />
  <path d="M16 6.5C12.4 6.5 10 9.2 10 13.5V18.5L7.8 22.2C7.3 23 7.8 24 8.8 24H23.2C24.2 24 24.7 23 24.2 22.2L22 18.5V13.5C22 9.2 19.6 6.5 16 6.5Z" fill="$domeHex" />
  <path d="M14.5 6.5C14.5 5.7 15.2 5 16 5C16.8 5 17.5 5.7 17.5 6.5" stroke="$domeHex" stroke-width="1.8" stroke-linecap="round" />
  ${hasUnread ? '<circle cx="22.5" cy="9.5" r="4" fill="$badgeHex" />' : ''}
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }
}

String _colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

/// 1-op-1 Isomorphic Duotone Notification Icons
/// Matching the exact vectors from Klantio Admin Dashboard.
enum IsomorphicNotificationType {
  factuur,
  agenda,
  leerling,
  examen,
  geannuleerd,
  algemeen,
}

class IsomorphicDuotoneNotificationIcon extends StatelessWidget {
  final IsomorphicNotificationType type;
  final double size;

  const IsomorphicDuotoneNotificationIcon({
    super.key,
    required this.type,
    this.size = 20,
  });

  factory IsomorphicDuotoneNotificationIcon.fromNotification({
    required String type,
    required String title,
    required String detail,
    double size = 20,
  }) {
    final lower = '$type $title $detail'.toLowerCase();

    if (lower.contains('annul') || lower.contains('geannuleerd')) {
      return IsomorphicDuotoneNotificationIcon(
        type: IsomorphicNotificationType.geannuleerd,
        size: size,
      );
    }
    if (lower.contains('factuur') ||
        lower.contains('betaald') ||
        lower.contains('betaling')) {
      return IsomorphicDuotoneNotificationIcon(
        type: IsomorphicNotificationType.factuur,
        size: size,
      );
    }
    if (lower.contains('les') ||
        lower.contains('agenda') ||
        lower.contains('planning') ||
        lower.contains('verzet') ||
        lower.contains('gewijzigd')) {
      return IsomorphicDuotoneNotificationIcon(
        type: IsomorphicNotificationType.agenda,
        size: size,
      );
    }
    if (lower.contains('leerling')) {
      return IsomorphicDuotoneNotificationIcon(
        type: IsomorphicNotificationType.leerling,
        size: size,
      );
    }
    if (lower.contains('examen') || lower.contains('theorie')) {
      return IsomorphicDuotoneNotificationIcon(
        type: IsomorphicNotificationType.examen,
        size: size,
      );
    }

    return IsomorphicDuotoneNotificationIcon(
      type: IsomorphicNotificationType.algemeen,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String svgString;

    switch (type) {
      case IsomorphicNotificationType.factuur:
        // 1. Facturen & Betalingen -> Shopping Bag / Order
        svgString = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 8H18L19.5 20H4.5L6 8Z" fill="#374151" />
  <path d="M9 10V6C9 4.34315 10.3431 3 12 3C13.6569 3 15 4.34315 15 6V10" stroke="#9CA3AF" stroke-width="2" stroke-linecap="round" />
  <circle cx="12" cy="14" r="1.5" fill="#9CA3AF" />
</svg>
''';
        break;

      case IsomorphicNotificationType.agenda:
        // 2. Agenda & Lessen -> Project Files / Blocks
        svgString = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="4" width="7" height="6" rx="1.5" fill="#374151" />
  <rect x="13" y="4" width="7" height="6" rx="1.5" fill="#9CA3AF" />
  <rect x="4" y="14" width="7" height="6" rx="1.5" fill="#9CA3AF" />
  <rect x="13" y="14" width="7" height="6" rx="1.5" fill="#374151" />
  <path d="M12 7H13M7 10V14" stroke="#9CA3AF" stroke-width="1.5" stroke-linecap="round" />
</svg>
''';
        break;

      case IsomorphicNotificationType.leerling:
        // 3. Leerlingen -> Creative Brush
        svgString = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18 4L20 6L14 12L12 10L18 4Z" fill="#374151" />
  <path d="M12 10L8 14C6.5 15.5 5 18 4 20C6 19 8.5 17.5 10 16L14 12" stroke="#9CA3AF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
  <circle cx="17.5" cy="6.5" r="1.5" fill="#9CA3AF" />
</svg>
''';
        break;

      case IsomorphicNotificationType.examen:
        // 4. Examens -> Cloud & Target Nodes
        svgString = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6.5 12C4.567 12 3 13.567 3 15.5C3 17.433 4.567 19 6.5 19H17.5C19.433 19 21 17.433 21 15.5C21 13.7 19.64 12.22 17.9 12.03C17.45 9.17 14.98 7 12 7C9.58 7 7.48 8.46 6.64 10.59C6.59 10.59 6.55 10.59 6.5 12Z" fill="#374151" />
  <path d="M12 12V16M10 14L12 16L14 14" stroke="#9CA3AF" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
</svg>
''';
        break;

      case IsomorphicNotificationType.geannuleerd:
        // 5. Geannuleerd / Alert
        svgString = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="3" width="18" height="18" rx="5" fill="#FEE2E2" />
  <path d="M9 9L15 15M15 9L9 15" stroke="#DC2626" stroke-width="2" stroke-linecap="round" />
</svg>
''';
        break;

      case IsomorphicNotificationType.algemeen:
        // 6. Default / Systeem / Algemeen -> 3D Isometric Box
        svgString = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 3L20 7.5V16.5L12 21L4 16.5V7.5L12 3Z" fill="#374151" />
  <path d="M12 3V12M12 12L20 7.5M12 12L4 7.5M12 12V21" stroke="#9CA3AF" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
</svg>
''';
        break;
    }

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }
}

/// 1-op-1 3D Dock Notification Icon uit het Klantio Admin Dashboard
class IsomorphicDockNotificationIcon extends StatelessWidget {
  final String type;
  final String title;
  final String detail;
  final double size;

  const IsomorphicDockNotificationIcon({
    super.key,
    required this.type,
    required this.title,
    required this.detail,
    this.size = 28,
  });

  String get assetPath {
    final lower = '$type $title $detail'.toLowerCase();
    if (lower.contains('annul') || lower.contains('geannuleerd')) {
      return 'assets/images/dock/evaluaties-dock.png';
    }
    if (lower.contains('factuur') ||
        lower.contains('betaald') ||
        lower.contains('betaling') ||
        lower.contains('betaal')) {
      return 'assets/images/dock/facturen-dock.png';
    }
    if (lower.contains('les') ||
        lower.contains('agenda') ||
        lower.contains('planning') ||
        lower.contains('verzet') ||
        lower.contains('gewijzigd')) {
      return 'assets/images/dock/lessen-dock.png';
    }
    if (lower.contains('leerling')) {
      return 'assets/images/dock/leerlingen-dock.png';
    }
    if (lower.contains('examen') || lower.contains('theorie')) {
      return 'assets/images/dock/examens-dock.png';
    }
    if (lower.contains('document')) {
      return 'assets/images/dock/documenten-dock.png';
    }
    if (lower.contains('voertuig') || lower.contains('auto')) {
      return 'assets/images/dock/voertuigen-dock.png';
    }
    if (lower.contains('pakket')) {
      return 'assets/images/dock/lespakketten-dock.png';
    }
    if (lower.contains('rit')) {
      return 'assets/images/dock/rittenregistratie-dock.png';
    }
    if (lower.contains('bon')) {
      return 'assets/images/dock/bonnen-dock.png';
    }
    if (lower.contains('rapport')) {
      return 'assets/images/dock/rapportages-dock.png';
    }
    return 'assets/images/dock/home-dock.png';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          IsomorphicDuotoneNotificationIcon.fromNotification(
        type: type,
        title: title,
        detail: detail,
        size: size * 0.75,
      ),
    );
  }
}

/// 1-op-1 Isomorphic 4-kant (squircle) Bell knop voor app headers
/// Inclusief micro-interaction rotatie- en schaal-animatie (zoals in Admin Dashboard).
class IsomorphicHeaderBellButton extends StatefulWidget {
  final VoidCallback onTap;
  final int unreadCount;
  final double size;

  const IsomorphicHeaderBellButton({
    super.key,
    required this.onTap,
    this.unreadCount = 0,
    this.size = 40,
  });

  @override
  State<IsomorphicHeaderBellButton> createState() =>
      _IsomorphicHeaderBellButtonState();
}

class _IsomorphicHeaderBellButtonState extends State<IsomorphicHeaderBellButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: IsomorphicBellIcon(
                    hasUnread: widget.unreadCount > 0,
                    size: 22,
                    domeColor: const Color(0xFFF8FAFC),
                    secondaryColor: const Color(0xFF94A3B8),
                    badgeColor: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 1-op-1 Isomorphic Sun Icon uit Klantio Admin Dashboard
class IsomorphicSunIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? rayColor;

  const IsomorphicSunIcon({
    super.key,
    this.size = 22,
    this.color,
    this.rayColor,
  });

  @override
  Widget build(BuildContext context) {
    final hexColor = _colorToHex(color ?? const Color(0xFF111827));
    final hexRay = _colorToHex(rayColor ?? const Color(0xFF9CA3AF));

    final svgString = '''
<svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 4V7.5M16 24.5V28M4 16H7.5M24.5 16H28M7.5 7.5L10 10M22 22L24.5 24.5M7.5 24.5L10 22M22 10L24.5 7.5" stroke="$hexRay" stroke-width="2.2" stroke-linecap="round" />
  <circle cx="16" cy="16" r="6.5" fill="$hexColor" />
  <path d="M13.5 13C14.2 12.3 15.1 12 16 12" stroke="$hexRay" stroke-width="1.5" stroke-linecap="round" />
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }
}

/// 1-op-1 Isomorphic Moon Icon uit Klantio Admin Dashboard
class IsomorphicMoonIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? sparkleColor;

  const IsomorphicMoonIcon({
    super.key,
    this.size = 22,
    this.color,
    this.sparkleColor,
  });

  @override
  Widget build(BuildContext context) {
    final hexColor = _colorToHex(color ?? const Color(0xFF111827));
    final hexSparkle = _colorToHex(sparkleColor ?? const Color(0xFF9CA3AF));

    final svgString = '''
<svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 17.2C20.5 21.6 16.8 25 12.2 25C7.4 25 3.5 21.1 3.5 16.3C3.5 11.9 6.8 8.3 11 7.6C10.5 8.9 10.2 10.3 10.2 11.8C10.2 16.8 14.2 20.8 19.2 20.8C20.2 20.8 21.2 20.6 22.1 20.2C21.8 21.5 21 17.2 21 17.2Z" fill="$hexColor" />
  <path d="M23 4.5L23.9 7.1L26.5 8L23.9 8.9L23 11.5L22.1 8.9L19.5 8L22.1 7.1L23 4.5Z" fill="$hexSparkle" />
  <circle cx="25.5" cy="15.5" r="1.5" fill="$hexSparkle" />
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }
}

/// 1-op-1 Dark Mode Toggle knop uit het Klantio Admin Dashboard:
/// - 40x40 squircle (12px radius, border, lichte schaduw)
/// - Volle 360° spin animatie (500ms, ease curve)
/// - Vloeiende scale & rotate overgang tussen Sun en Moon icoon
/// - Micro-touch feedback (scale: 0.92)
class IsomorphicDarkModeToggle extends ConsumerStatefulWidget {
  final double size;

  const IsomorphicDarkModeToggle({
    super.key,
    this.size = 40,
  });

  @override
  ConsumerState<IsomorphicDarkModeToggle> createState() =>
      _IsomorphicDarkModeToggleState();
}

class _IsomorphicDarkModeToggleState
    extends ConsumerState<IsomorphicDarkModeToggle>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pressController;
  late final Animation<double> _spinAnimation;
  late final Animation<double> _pressScaleAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _spinAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      ),
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pressScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onToggle(BuildContext context) {
    _spinController.forward(from: 0.0);
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero);
    final size = renderBox?.size;
    final center = offset != null && size != null
        ? offset + Offset(size.width / 2, size.height / 2)
        : null;

    final boundaryKey = ref.read(themeRepaintBoundaryKeyProvider);

    ref.read(themeModeProvider.notifier).toggle(
          origin: center,
          context: context,
          boundaryKey: boundaryKey,
          ref: ref,
        );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);

    final isDarkMode = isDark;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        _onToggle(context);
      },
      onTapCancel: () => _pressController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spinController, _pressController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pressScaleAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: Transform.rotate(
                  angle: _spinAnimation.value,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: anim,
                        child: FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                      );
                    },
                    child: isDarkMode
                        ? const IsomorphicMoonIcon(
                            key: ValueKey('moon_icon'),
                            size: 22,
                            color: Color(0xFFF8FAFC),
                            sparkleColor: Color(0xFF94A3B8),
                          )
                        : const IsomorphicSunIcon(
                            key: ValueKey('sun_icon'),
                            size: 22,
                            color: Color(0xFFF8FAFC),
                            rayColor: Color(0xFF94A3B8),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
