import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/main_shell_nav_bar_visibility.dart';
import '../../core/services/native_navigation_bridge.dart';
import 'main_scaffold.dart';

/// Houdt een volledig scherm vrij van de native iOS-tabbalk.
///
/// De Liquid Glass-balk is een overlay op het hele venster. Pagina's die via
/// de root-navigator of een route buiten de shell openen, lopen daardoor tot
/// onder de balk. Binnen [MainShellContentInset] reserveert de shell die
/// ruimte al, dus daar doet deze widget niets.
class NativeNavClearance extends ConsumerWidget {
  final Widget child;

  const NativeNavClearance({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inShell =
        context.dependOnInheritedWidgetOfExactType<MainShellContentInset>() !=
            null;
    if (inShell) return child;

    final barVisible = ref.watch(mainShellNavBarVisibleProvider);
    final nav = ref.watch(nativeNavigationProvider);
    if (!barVisible || !nav.available || nav.height <= 0) return child;

    // Geen extra vlak achter de balk. De pagina loopt door, zodat het glas
    // dezelfde achtergrond toont. Scroll-inhoud telt [NavBarOverlayInset] op
    // en houdt zo dezelfde eindafstand.
    return NavBarOverlayInset(
      bottom: nav.height,
      child: child,
    );
  }
}

/// Zelfde constructor als [MaterialPageRoute], met [NativeNavClearance]
/// om de pagina zodat het laatste item boven de tabbalk blijft.
class KlantioPageRoute<T> extends MaterialPageRoute<T> {
  KlantioPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
  }) : super(
          builder: (context) => NativeNavClearance(child: builder(context)),
        );
}
