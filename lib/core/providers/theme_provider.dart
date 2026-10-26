import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeStorageKey = 'klantio-theme';

final themeRepaintBoundaryKeyProvider = Provider<GlobalKey>((ref) {
  return GlobalKey();
});

class ThemeRevealState {
  final ui.Image? snapshot;
  final Offset origin;
  final bool isDark;
  final int sequence;

  ThemeRevealState({
    this.snapshot,
    required this.origin,
    required this.isDark,
    required this.sequence,
  });
}

final themeRevealStateProvider =
    StateProvider<ThemeRevealState?>((ref) => null);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadFromPrefs();
  }

  /// Zodra de gebruiker zelf een keuze maakt mag het (trage) laden van de
  /// opgeslagen voorkeur die keuze niet meer overschrijven.
  bool _gebruikerHeeftGekozen = false;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_gebruikerHeeftGekozen) return;
      final saved = prefs.getString(_kThemeStorageKey);
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      }
    } catch (_) {
      // Gebruik default light bij IO fout
    }
  }

  Future<void> toggle({
    Offset? origin,
    BuildContext? context,
    GlobalKey? boundaryKey,
    WidgetRef? ref,
  }) async {
    final nextIsDark = state != ThemeMode.dark;
    final nextMode = nextIsDark ? ThemeMode.dark : ThemeMode.light;
    _gebruikerHeeftGekozen = true;

    ui.Image? snapshot;
    if (boundaryKey?.currentContext != null && context != null) {
      try {
        final boundary = boundaryKey!.currentContext!.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
          // Een snapshot die blijft hangen mag het wisselen nooit blokkeren.
          snapshot = await boundary
              .toImage(pixelRatio: pixelRatio)
              .timeout(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('Theme snapshot error: $e');
      }
    }

    if (origin != null && ref != null) {
      ref.read(themeRevealStateProvider.notifier).state = ThemeRevealState(
        snapshot: snapshot,
        origin: origin,
        isDark: nextIsDark,
        sequence: DateTime.now().millisecondsSinceEpoch,
      );
    }

    state = nextMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeStorageKey, nextIsDark ? 'dark' : 'light');
    } catch (e) {
      // Thema is al gewisseld; alleen het bewaren mislukte.
      debugPrint('Theme opslaan mislukt: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _gebruikerHeeftGekozen = true;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system';
      await prefs.setString(_kThemeStorageKey, str);
    } catch (_) {}
  }
}

final themeToggleOriginProvider = StateProvider<Offset?>((ref) => null);

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
