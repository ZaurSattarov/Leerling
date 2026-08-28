import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final bool available;
  final double height;

  const NativeNavigationState({this.available = false, this.height = 0});

  NativeNavigationState copyWith({bool? available, double? height}) =>
      NativeNavigationState(
        available: available ?? this.available,
        height: height ?? this.height,
      );
}

/// Bridge naar de native iOS 26+ Liquid Glass-navbar (Leerling-app).
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

  Future<void> setSelectedIndex(int index) async {
    if (!Platform.isIOS || !state.available) return;
    try {
      await _channel.invokeMethod('setSelectedIndex', {'index': index});
    } on PlatformException catch (e) {
      debugPrint('NativeNavigationBridge.setSelectedIndex faalde: $e');
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'nativeReady':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          state = NativeNavigationState(
            available: args['available'] as bool? ?? false,
            height: (args['height'] as num?)?.toDouble() ?? 0,
          );
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
