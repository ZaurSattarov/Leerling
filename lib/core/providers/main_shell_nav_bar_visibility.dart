import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/native_navigation_bridge.dart';

/// True zolang een startup-splash-overlay zichtbaar is.
///
/// Leerling-app: de splash is een eigen route (`/splash`) buiten de shell,
/// geen overlay boven de shell zoals in de Instructeur-app. De navbar wordt
/// daar al verborgen omdat [mainShellMountedProvider] dan nog false is --
/// daarom staat dit hier standaard op false.
final klantioStartupSplashBlockingProvider = StateProvider<bool>(
  (ref) => false,
);

/// Aantal actieve bootstrap-/loading-blokkades binnen de main shell
/// (OnboardingGate, SetupOnboardingGate, ...).
final mainShellNavBarBootstrapBlockCountProvider = StateProvider<int>(
  (ref) => 0,
);

/// True zolang de geauthenticeerde app shell ([MainScaffold]) daadwerkelijk
/// gemount is in de widget-tree. Vóór login (login, registratie, verificatie,
/// splash, etc.) staat dit altijd op false, waardoor de bottom navbar NOOIT
/// getoond wordt.
final mainShellMountedProvider = StateProvider<bool>(
  (ref) => false,
);

/// Aantal open bottom sheets die het navmenu moeten bedekken. Zolang dit
/// groter is dan 0, blijft de native iOS-overlay verborgen: die tekent
/// anders bovenop een Flutter-sheet.
final nativeNavSheetCoverCountProvider = StateProvider<int>((ref) => 0);

/// Of de bottom navbar (Flutter-fallback én native iOS-overlay) getoond mag
/// worden. Pas true zodra de shell gemount is, splash klaar is én eventuele
/// bootstrap-loading binnen de shell klaar is.
final mainShellNavBarVisibleProvider = Provider<bool>((ref) {
  final shellMounted = ref.watch(mainShellMountedProvider);
  if (!shellMounted) return false;
  final splashBlocking = ref.watch(klantioStartupSplashBlockingProvider);
  final bootstrapBlocks = ref.watch(mainShellNavBarBootstrapBlockCountProvider);
  return !splashBlocking && bootstrapBlocks == 0;
});

/// Synchroniseert de berekende zichtbaarheid naar de native iOS-overlay.
void syncMainShellNavBarToNative(WidgetRef ref, {String? caller}) {
  final shellMounted = ref.read(mainShellMountedProvider);
  final splashBlocking = ref.read(klantioStartupSplashBlockingProvider);
  final bootstrapBlocks = ref.read(mainShellNavBarBootstrapBlockCountProvider);
  final visible = ref.read(mainShellNavBarVisibleProvider);
  debugPrint(
    '[NAVBAR_PROVIDER] shellMounted=$shellMounted splashBlock=$splashBlocking '
    'bootstrapBlockCount=$bootstrapBlocks visible=$visible '
    'caller=${caller ?? 'syncMainShellNavBarToNative'}',
  );
  ref.read(nativeNavigationProvider.notifier).setBarVisible(visible);
}

/// Verbergt de main-shell bottom navbar zolang dit widget gemount is.
class MainShellNavBarBootstrapBlocker extends StatefulWidget {
  final Widget child;

  const MainShellNavBarBootstrapBlocker({super.key, required this.child});

  @override
  State<MainShellNavBarBootstrapBlocker> createState() =>
      _MainShellNavBarBootstrapBlockerState();
}

class _MainShellNavBarBootstrapBlockerState
    extends State<MainShellNavBarBootstrapBlocker> {
  ProviderContainer? _container;
  var _registered = false;
  var _released = false;

  @override
  void initState() {
    super.initState();
    // Provider mutatie niet tijdens build/didChangeDependencies -- anders
    // blijft bootstrapBlockCount hangen terwijl OnboardingGate al Dashboard
    // toont (Riverpod: "modify provider while building").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _registered) return;
      _registered = true;
      _container = ProviderScope.containerOf(context);
      _container!
          .read(mainShellNavBarBootstrapBlockCountProvider.notifier)
          .update((count) => count + 1);
      debugPrint(
        '[BOOTSTRAP] acquire count='
        '${_container!.read(mainShellNavBarBootstrapBlockCountProvider)}',
      );
    });
  }

  @override
  void dispose() {
    if (_registered && !_released) {
      _released = true;
      final container = _container;
      if (container != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          container
              .read(mainShellNavBarBootstrapBlockCountProvider.notifier)
              .update((count) => count > 0 ? count - 1 : 0);
          debugPrint(
            '[BOOTSTRAP] release count='
            '${container.read(mainShellNavBarBootstrapBlockCountProvider)}',
          );
        });
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
