import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const List<_NavItem> _items = [
    _NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        route: '/home'),
    _NavItem(
        label: 'Planning',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        route: '/planning'),
    _NavItem(
        label: 'Voortgang',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        route: '/voortgang'),
    _NavItem(
        label: 'Facturen',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        route: '/facturen'),
    _NavItem(
        label: 'Profiel',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        route: '/profiel'),
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
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.dark,
          border: Border(top: BorderSide(color: AppColors.dark2, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 68,
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final isActive = i == activeIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(item.route),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isActive)
                          Container(
                            width: 40,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.activeIcon,
                                size: 20, color: Colors.white),
                          )
                        else
                          Icon(item.icon,
                              size: 22,
                              color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem(
      {required this.label,
      required this.icon,
      required this.activeIcon,
      required this.route});
}
