import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Eén navigatie-item zoals Flutter het naar de native Liquid Glass-navbar
/// stuurt. `route` wordt niet door native gebruikt om te navigeren -- het is
/// puur metadata; go_router blijft de enige bron van waarheid voor routing.
@immutable
class NativeNavItemConfig {
  final String label;
  final String sfSymbol;
  final String route;

  const NativeNavItemConfig({
    required this.label,
    required this.sfSymbol,
    required this.route,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'sfSymbol': sfSymbol,
        'route': route,
      };
}

@immutable
class NativeNavigationState {
  /// True zodra de native laag heeft bevestigd dat iOS 26+ Liquid Glass
  /// beschikbaar is EN succesvol geïnitialiseerd is. Pas dan mag de
  /// Flutter-navbar verborgen worden.
  final bool available;

  /// Hoogte (in logische pixels) die Flutter moet reserveren onderaan het
  /// scherm zodat content nooit achter de native balk verdwijnt.
  final double height;

  const NativeNavigationState({this.available = false, this.height = 0});

  NativeNavigationState copyWith({bool? available, double? height}) =>
      NativeNavigationState(
        available: available ?? this.available,
        height: height ?? this.height,
      );
}

/// Bridge naar de native iOS 26+ Liquid Glass-navbar
/// (ios/Runner/NativeNavigation/NativeNavigationBridge.swift).
class NativeNavigationController extends StateNotifier<NativeNavigationState> {
  NativeNavigationController() : super(const NativeNavigationState()) {
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  static const MethodChannel _channel =
      MethodChannel('com.klantio.leerling/native_navigation');

  void Function(int index)? _onNativeTabSelected;
  bool _configureRequested = false;

  /// Standaard verborgen tot Flutter expliciet `setBarVisible(true)` stuurt.
  bool _barVisible = false;

  /// Splash, login en de andere schermen vóór de shell. Zolang dit aan staat
  /// negeert de balk elk verzoek om zichtbaar te worden (ook `nativeReady`,
  /// dat anders de laatste zichtbaarheid opnieuw toepast).
  bool _verborgenTotIngelogd = true;

  void setVerborgenTotIngelogd(bool verborgen) {
    _verborgenTotIngelogd = verborgen;
    if (verborgen) {
      unawaited(setBarVisible(false, force: true));
    }
  }
  bool? _lastSentVisible;

  String _callerHint() {
    final frames = StackTrace.current.toString().split('\n');
    for (final frame in frames.skip(1).take(6)) {
      final trimmed = frame.trim();
      if (trimmed.contains('native_navigation_bridge.dart')) continue;
      return trimmed;
    }
    return frames.length > 1 ? frames[1].trim() : 'unknown';
  }

  void setNativeTabSelectedHandler(void Function(int index) handler) {
    _onNativeTabSelected = handler;
  }

  Future<void> configure({
    required List<NativeNavItemConfig> items,
    required int initialIndex,
    required Color primaryColor,
  }) async {
    if (!Platform.isIOS || _configureRequested) return;
    _configureRequested = true;
    try {
      await _channel.invokeMethod('configure', {
        'items': items.map((e) => e.toJson()).toList(),
        'initialIndex': initialIndex,
        'primaryColorHex': _colorToHex(primaryColor),
      });
    } on MissingPluginException {
      state = state.copyWith(available: false);
    } on PlatformException catch (e) {
      debugPrint('NativeNavigationBridge.configure faalde: $e');
      state = state.copyWith(available: false);
    }
  }

  bool? _lastSentDarkMode;

  Future<void> setDarkMode(bool isDark) async {
    if (!Platform.isIOS || _lastSentDarkMode == isDark) return;
    _lastSentDarkMode = isDark;
    try {
      await _channel.invokeMethod('setDarkMode', {'isDark': isDark});
    } on PlatformException catch (e) {
      debugPrint('NativeNavigationBridge.setDarkMode faalde: $e');
    }
  }

  Future<void> setSelectedIndex(int index) async {
    if (!Platform.isIOS || !state.available) return;
    try {
      await _channel.invokeMethod('setSelectedIndex', {'index': index});
    } on PlatformException catch (e) {
      debugPrint('NativeNavigationBridge.setSelectedIndex faalde: $e');
    }
  }

  /// Verbergt/toont direct via het native kanaal, ook statisch aanroepbaar
  /// (bv. in pre-auth schermen vóór/zonder Riverpod-ref of tijdens auth-transities).
  static Future<void> setBarVisibleDirect(bool visible) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('setVisible', {'visible': visible});
    } catch (_) {}
  }

  /// Verbergt/toont uitsluitend de native iOS-overlay. Werkt ook vóór
  /// `configure()`: native bewaart de state en past die toe bij attach.
  Future<void> setBarVisible(bool visible, {bool force = false}) async {
    if (visible && _verborgenTotIngelogd) visible = false;
    final previous = _barVisible;
    final nativeReady = state.available;
    final dedupSkip = !force && _lastSentVisible == visible;
    _barVisible = visible;
    var sentToNative = false;
    if (!Platform.isIOS) {
      debugPrint(
        '[NAVBAR_DART] request visible=$visible previous=$previous '
        'nativeReady=$nativeReady sentToNative=false '
        'caller=${_callerHint()} (non-iOS)',
      );
      return;
    }
    if (!dedupSkip) {
      _lastSentVisible = visible;
      try {
        await _channel.invokeMethod('setVisible', {'visible': visible});
        sentToNative = true;
      } on MissingPluginException {
        // Geen native implementatie.
      } on PlatformException catch (e) {
        debugPrint('NativeNavigationBridge.setVisible faalde: $e');
      }
    }
    debugPrint(
      '[NAVBAR_DART] request visible=$visible previous=$previous '
      'nativeReady=$nativeReady sentToNative=$sentToNative '
      'dedupSkip=$dedupSkip caller=${_callerHint()}',
    );
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'nativeReady':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final available = args['available'] as bool? ?? false;
          final height = (args['height'] as num?)?.toDouble() ?? 0;
          debugPrint(
            '[NAVBAR_DART] nativeReady available=$available height=$height '
            'desiredVisible=$_barVisible lastSent=$_lastSentVisible',
          );
          state = NativeNavigationState(
            available: available,
            height: height,
          );
          if (state.available) {
            _lastSentVisible = null;
            unawaited(setBarVisible(_barVisible));
          }
          break;
        case 'heightChanged':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final height = (args['height'] as num?)?.toDouble();
          if (height != null) {
            state = state.copyWith(height: height);
          }
          break;
        case 'tabSelected':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final index = args['index'] as int?;
          if (index != null) {
            _onNativeTabSelected?.call(index);
          }
          break;
      }
    } catch (e) {
      debugPrint('NativeNavigationBridge: fout bij verwerken native call: $e');
    }
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }
}

final nativeNavigationProvider =
    StateNotifierProvider<NativeNavigationController, NativeNavigationState>(
  (ref) => NativeNavigationController(),
);
