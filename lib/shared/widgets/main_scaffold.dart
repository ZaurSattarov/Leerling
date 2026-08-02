import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const List<NavBarItem> _items = [
    NavBarItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: '/home',
    ),
    NavBarItem(
      label: 'Planning',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      route: '/planning',
    ),
    NavBarItem(
      label: 'Voortgang',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      route: '/voortgang',
    ),
    NavBarItem(
      label: 'Facturen',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: '/facturen',
    ),
    NavBarItem(
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

    // Zie toelichting bij `bottomNavigationBar` hieronder.
    final systeemInsetOnder = MediaQuery.paddingOf(context).bottom;
    final navBarOnderMarge = math.max(12.0, systeemInsetOnder * 0.5);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: child,
      // Bewust GEEN SafeArea hier (die past `max(devicePadding.bottom,
      // minimum)` toe -- op een toestel met Dynamic Island/home-indicator
      // wint altijd het volle systeem-inset, ongeacht welke `minimum` je
      // opgeeft, wat een te grote lege ruimte onder de balk geeft. In
      // plaats daarvan gebruiken we hierboven zelf een KLEINERE, aan het
      // toestel geschaalde marge: de helft van het systeem-inset, met een
      // ondergrens van 12px voor toestellen zonder eigen inset (iPhone SE,
      // oudere Android) -- 1-op-1 overgenomen uit de Instructeur-app.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, navBarOnderMarge),
        child: PremiumBottomNavBar(
          activeIndex: activeIndex,
          items: _items,
          onItemTap: (i) => context.go(_items[i].route),
        ),
      ),
    );
  }
}

// ── Premium floating glass nav bar ──────────────────────────────────────────
// 1-op-1 overgenomen uit de Instructeur-app (rijschool-planner-flutter,
// lib/shared/widgets/main_scaffold.dart) -- zelfde geometrie, glasoppervlak,
// animaties en indicatorgedrag. Alleen de items (labels/iconen/routes)
// zijn Leerling-eigen; die waren al identiek in structuur.

const double _kBarHeight = 56;
const double _kIconSize = 22;
const double _kIconLabelGap = 3;
const double _kLabelFontSize = 10;
const double _kIndicatorRadius = 16;
const double _kIndicatorHorizontalPadding = 10;
const double _kIndicatorVerticalPadding = 4;
const double _kIndicatorSafeMargin = 6;

class PremiumBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final List<NavBarItem> items;
  final void Function(int) onItemTap;

  const PremiumBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.items,
    required this.onItemTap,
  });

  /// Eén gedeelde labelgrootte voor ALLE tabs, berekend uit het langste
  /// label -- garandeert dat elk label past en dat alle tabs exact
  /// dezelfde verticale grid gebruiken (geen per-tab FittedBox, die zou de
  /// icoon/label-hoogte per tab ongelijk laten schalen).
  double _berekenLabelFontSize(BuildContext context, double tabBreedte) {
    final maxPilBreedte = math.max(0.0, tabBreedte - _kIndicatorSafeMargin * 2);
    final maxTekstBreedte =
        math.max(0.0, maxPilBreedte - _kIndicatorHorizontalPadding * 2);
    final langsteLabel = items
        .map((i) => i.label)
        .reduce((a, b) => a.length >= b.length ? a : b);

    final painter = TextPainter(
      text: TextSpan(
        text: langsteLabel,
        style: GoogleFonts.inter(
          fontSize: _kLabelFontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    if (painter.width <= maxTekstBreedte || painter.width <= 0) {
      return _kLabelFontSize;
    }
    return _kLabelFontSize * (maxTekstBreedte / painter.width);
  }

  @override
  Widget build(BuildContext context) {
    const radius = _kBarHeight / 2;

    return Container(
      height: _kBarHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Colors.white.withValues(alpha: 0.78),
            child: LayoutBuilder(builder: (context, constraints) {
              final labelFontSize = _berekenLabelFontSize(
                  context, constraints.maxWidth / items.length);
              return Row(
                children: List.generate(items.length, (i) {
                  final isActive = i == activeIndex;
                  final item = items[i];
                  return Expanded(
                    child: _NavBarTab(
                      item: item,
                      isActive: isActive,
                      labelFontSize: labelFontSize,
                      onTap: () => onItemTap(i),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarTab extends StatefulWidget {
  final NavBarItem item;
  final bool isActive;
  final double labelFontSize;
  final VoidCallback onTap;

  const _NavBarTab({
    required this.item,
    required this.isActive,
    required this.labelFontSize,
    required this.onTap,
  });

  @override
  State<_NavBarTab> createState() => _NavBarTabState();
}

class _NavBarTabState extends State<_NavBarTab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final color = isActive ? Colors.white : AppColors.textSecondary;

    return Semantics(
      key: Key('nav_bar_tab_${widget.item.route}'),
      button: true,
      selected: isActive,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              height: _kBarHeight,
              width: double.infinity,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kIndicatorHorizontalPadding,
                    vertical: _kIndicatorVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(_kIndicatorRadius),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? widget.item.activeIcon : widget.item.icon,
                        size: _kIconSize,
                        color: color,
                      ),
                      const SizedBox(height: _kIconLabelGap),
                      Text(
                        widget.item.label,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: widget.labelFontSize,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav item model ────────────────────────────────────────────────────────────

class NavBarItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
