import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: '/home',
    ),
    _NavItem(
      label: 'Planning',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      route: '/planning',
    ),
    _NavItem(
      label: 'Voortgang',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      route: '/voortgang',
    ),
    _NavItem(
      label: 'Facturen',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: '/facturen',
    ),
    _NavItem(
      label: 'Profiel',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: '/profiel',
    ),
  ];

  int _activeIndex(String location) {
    if (location.startsWith('/planning')) return 1;
    if (location.startsWith('/voortgang')) return 2;
    if (location.startsWith('/facturen')) return 3;
    if (location.startsWith('/profiel')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final activeIndex = _activeIndex(location);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: _FloatingNavBar(
            activeIndex: activeIndex,
            items: _items,
            onItemTap: (i) => context.go(_items[i].route),
          ),
        ),
      ),
    );
  }
}

// ── Floating nav bar with bump ────────────────────────────────────────────────

class _FloatingNavBar extends StatefulWidget {
  final int activeIndex;
  final List<_NavItem> items;
  final void Function(int) onItemTap;

  const _FloatingNavBar({
    required this.activeIndex,
    required this.items,
    required this.onItemTap,
  });

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  int _fromIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.activeIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_FloatingNavBar old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex) {
      _fromIndex = old.activeIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final n = widget.items.length;
      final w = constraints.maxWidth;
      final itemW = w / n;

      final fromX = itemW * (_fromIndex + 0.5);
      final toX = itemW * (widget.activeIndex + 0.5);

      return AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final animX = lerpDouble(fromX, toX, _anim.value)!;

          return SizedBox(
            height: 78,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bar shape with bump via CustomPainter
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 64,
                  child: CustomPaint(
                    painter: _BumpBarPainter(
                      bumpCenterX: animX,
                      bumpRadius: 26,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Tappable items row
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 64,
                  child: Row(
                    children: List.generate(n, (i) {
                      final isActive = i == widget.activeIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onItemTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: isActive
                                ? [
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.items[i].label,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ]
                                : [
                                    Icon(
                                      widget.items[i].icon,
                                      size: 22,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Active icon: floats above bar, follows animated bump
                Positioned(
                  left: animX - 22,
                  top: 2,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.items[widget.activeIndex].activeIcon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ── CustomPainter: bar with upward bump ───────────────────────────────────────

class _BumpBarPainter extends CustomPainter {
  final double bumpCenterX;
  final double bumpRadius;
  final Color color;

  _BumpBarPainter({
    required this.bumpCenterX,
    required this.bumpRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    if (w <= 0) return;
    const cr = 30.0;
    final br = bumpRadius;
    final minCx = br + cr + 4;
    final maxCx = (w - br - cr - 4).clamp(minCx, double.infinity);
    final cx = bumpCenterX.clamp(minCx, maxCx);
    const hPad = 16.0;

    final path = Path()
      ..moveTo(0, h - cr)
      ..quadraticBezierTo(0, h, cr, h)
      ..lineTo(w - cr, h)
      ..quadraticBezierTo(w, h, w, h - cr)
      ..lineTo(w, cr)
      ..quadraticBezierTo(w, 0, w - cr, 0)
      ..lineTo(cx + br + hPad, 0)
      ..cubicTo(cx + br, 0, cx + br * 0.5, -(br * 0.85), cx, -(br))
      ..cubicTo(cx - br * 0.5, -(br * 0.85), cx - br, 0, cx - br - hPad, 0)
      ..lineTo(cr, 0)
      ..quadraticBezierTo(0, 0, 0, cr)
      ..close();

    // Soft shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Bar fill
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BumpBarPainter old) => old.bumpCenterX != bumpCenterX;
}

// ── Nav item model ─────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
