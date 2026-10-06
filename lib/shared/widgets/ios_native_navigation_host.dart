import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/native_navigation_bridge.dart';
import 'main_scaffold.dart' show NavBarItem;

/// Beslist per frame of de native iOS 26+ Liquid Glass-navbar getoond wordt,
/// of dat de bestaande Flutter-navbar ([fallback]) gewoon blijft draaien.
///
/// - Android en iOS < 26: [fallback] wordt altijd getoond ([available] kan
///   op dat platform nooit `true` worden, zie [NativeNavigationController]).
/// - iOS 26+: pas ná een bevestigd `nativeReady(available: true)`-signaal
///   van de native laag wordt [fallback] vervangen door een lege spacer ter
///   hoogte van de echte native balk (die zelf als losse overlay bovenop de
///   Flutter-view getekend wordt door NativeLiquidGlassTabBarFactory).
///
/// Deze widget bevat zelf geen navigatie- of businesslogica: [onItemTap]
/// (dezelfde closure als de Flutter-pil gebruikt) wordt zowel aan de
/// fallback als aan een binnenkomende native tik doorgegeven, zodat beide
/// exact hetzelfde pad volgen (incl. de agenda-datumreset-uitzondering in
/// MainScaffold).
class IosNativeNavigationHost extends ConsumerStatefulWidget {
  final int activeIndex;
  final List<NavBarItem> items;
  final void Function(int index) onItemTap;
  final Widget fallback;
  final bool barVisible;

  const IosNativeNavigationHost({
    super.key,
    required this.activeIndex,
    required this.items,
    required this.onItemTap,
    required this.fallback,
    required this.barVisible,
  });

  @override
  ConsumerState<IosNativeNavigationHost> createState() =>
      _IosNativeNavigationHostState();
}

class _IosNativeNavigationHostState
    extends ConsumerState<IosNativeNavigationHost> {
  bool _didRequestConfigure = false;
  bool _didSyncAfterReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureConfigured();
    ref
        .read(nativeNavigationProvider.notifier)
        .setDarkMode(Theme.of(context).brightness == Brightness.dark);
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(nativeNavigationProvider.notifier)
          .setSelectedIndex(widget.activeIndex);
    });
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
    controller.setBarVisible(widget.barVisible, force: true);
    controller.configure(
      items: widget.items
          .map((item) => NativeNavItemConfig(
                label: item.label,
                sfSymbol: item.sfSymbol,
                route: item.route,
              ))
          .toList(),
      initialIndex: widget.activeIndex,
      primaryColor: const Color(0xFFD63060),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(nativeNavigationProvider);
    if (navState.available && !_didSyncAfterReady) {
      _didSyncAfterReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(nativeNavigationProvider.notifier)
            .setSelectedIndex(widget.activeIndex);
      });
    }
    ref
        .read(nativeNavigationProvider.notifier)
        .setNativeTabSelectedHandler(widget.onItemTap);

    if (navState.available) {
      if (!widget.barVisible) return const SizedBox.shrink();
      return SizedBox(height: navState.height);
    }
    return widget.fallback;
  }
}
