import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/native_navigation_bridge.dart';
import 'main_scaffold.dart' show NavBarItem;

/// Toont op iOS 26+ de native Liquid Glass-navbar; anders [fallback].
class IosNativeNavigationHost extends ConsumerStatefulWidget {
  final int activeIndex;
  final List<NavBarItem> items;
  final void Function(int index) onItemTap;
  final Widget fallback;

  const IosNativeNavigationHost({
    super.key,
    required this.activeIndex,
    required this.items,
    required this.onItemTap,
    required this.fallback,
  });

  @override
  ConsumerState<IosNativeNavigationHost> createState() =>
      _IosNativeNavigationHostState();
}

class _IosNativeNavigationHostState
    extends ConsumerState<IosNativeNavigationHost> {
  bool _didRequestConfigure = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureConfigured();
  }

  @override
  void didUpdateWidget(covariant IosNativeNavigationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      ref
          .read(nativeNavigationProvider.notifier)
          .setSelectedIndex(widget.activeIndex);
    }
  }

  void _ensureConfigured() {
    final controller = ref.read(nativeNavigationProvider.notifier);
    if (_didRequestConfigure) return;
    _didRequestConfigure = true;
    controller.configure(
      items: widget.items
          .map((item) => NativeNavItemConfig(
                label: item.label,
                sfSymbol: item.sfSymbol,
                route: item.route,
              ))
          .toList(),
      initialIndex: widget.activeIndex,
      primaryColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(nativeNavigationProvider);
    ref
        .read(nativeNavigationProvider.notifier)
        .setNativeTabSelectedHandler(widget.onItemTap);

    if (navState.available) {
      return SizedBox(height: navState.height);
    }
    return widget.fallback;
  }
}
