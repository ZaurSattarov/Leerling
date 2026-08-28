// Push notificaties — Leerling-app.
//
// Orchestration rond canonical openLeerlingNotificatie(notificatie).
import 'dart:async';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../features/notificaties/notificaties_provider.dart';
import '../../models/notificatie.dart';
import 'leerling_notificatie_router.dart';
import 'student_service.dart';

const _devicePrefKey = 'klantio_push_device_id_v1';
const apnsTokenMaxRetries = 5;
const apnsTokenRetryDelay = Duration(seconds: 1);
const pushTapMaxFrameRetries = 60;

abstract class PushService {
  static bool _listenersAttached = false;
  static String? _deviceId;
  static bool _bootstrapComplete = false;
  static Map<String, dynamic>? _pendingTapData;
  static String? _pendingTapSource;
  static int _pendingFrameRetries = 0;
  static bool _flushInProgress = false;
  static bool _initialMessageHandled = false;

  static Future<String> _deviceIdValue() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_devicePrefKey);
    if (id == null || id.isEmpty) {
      final rnd = Random.secure();
      id = List<int>.generate(16, (_) => rnd.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      await prefs.setString(_devicePrefKey, id);
    }
    _deviceId = id;
    return id;
  }

  /// Vóór runApp aanroepen zodat iOS-taps de listener niet missen.
  static Future<void> ensureInitialized() async {
    if (_listenersAttached) return;
    _listenersAttached = true;
    try {
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => unawaited(
          handleNotificationTap(message, source: 'background'),
        ),
      );
      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
    } catch (e) {
      debugPrint('[PushService] init fout: $e');
      _listenersAttached = false;
      rethrow;
    }
  }

  static Future<void> requestPermissionAndRegister() async {
    if (StudentService.currentUser == null) return;
    await ensureInitialized();
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await waitForApnsToken();
        if (apnsToken == null) return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) await _registerToken(token);
    } catch (e) {
      debugPrint('[PushService] permissie/registratie mislukt: $e');
    }
  }

  @visibleForTesting
  static Future<String?> waitForApnsToken({
    Future<String?> Function()? fetchApnsToken,
    int maxRetries = apnsTokenMaxRetries,
    Duration retryDelay = apnsTokenRetryDelay,
  }) async {
    final fetch = fetchApnsToken ?? FirebaseMessaging.instance.getAPNSToken;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      final apnsToken = await fetch();
      if (apnsToken != null && apnsToken.isNotEmpty) return apnsToken;
      if (attempt < maxRetries) await Future.delayed(retryDelay);
    }
    return null;
  }

  static Future<void> _registerToken(String token) async {
    if (StudentService.currentUser == null) return;
    try {
      final deviceId = await _deviceIdValue();
      await StudentService.client.rpc('register_push_token', params: {
        'p_app_type': 'leerling',
        'p_platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'p_token': token,
        'p_device_id': deviceId,
      });
    } catch (e) {
      debugPrint('[PushService] register_push_token error: $e');
    }
  }

  static Future<void> deactivateForLogout() async {
    _clearPendingTap();
    try {
      final deviceId = await _deviceIdValue();
      await StudentService.client
          .rpc('deactivate_push_token', params: {'p_device_id': deviceId});
    } catch (e) {
      debugPrint('[PushService] deactivate_push_token mislukt: $e');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    container.invalidate(notificatiesProvider);
    container.invalidate(ongelezenNotificatiesProvider);
  }

  static Future<void> handleInitialMessageIfAny() async {
    if (_initialMessageHandled) return;
    _initialMessageHandled = true;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      await handleNotificationTap(message, source: 'terminated');
    }
  }

  static void onAppResumed() {
    unawaited(flushPendingNavigation());
    schedulePendingFlush();
  }

  static void markRouterReady() {
    _bootstrapComplete = true;
    unawaited(flushPendingNavigation());
    schedulePendingFlush();
  }

  static bool get hasPendingNavigation => _pendingTapData != null;

  static Future<bool> flushPendingNavigation() async {
    if (_pendingTapData == null) return false;
    if (!_canNavigateNow(source: _pendingTapSource ?? 'pending')) {
      schedulePendingFlush();
      return false;
    }
    if (_flushInProgress) return false;
    _flushInProgress = true;
    try {
      final data = _pendingTapData!;
      final source = _pendingTapSource ?? 'pending';
      _pendingTapData = null;
      _pendingTapSource = null;
      _pendingFrameRetries = 0;
      return await _openNotificationFromPushData(data, source: source);
    } finally {
      _flushInProgress = false;
    }
  }

  static void schedulePendingFlush() {
    if (_pendingTapData == null) return;
    if (_pendingFrameRetries >= pushTapMaxFrameRetries) {
      _pendingFrameRetries = 0;
      return;
    }
    _pendingFrameRetries++;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      unawaited(flushPendingNavigation());
    });
  }

  static Future<void> handleNotificationTap(
    RemoteMessage message, {
    required String source,
  }) async {
    final data = Map<String, dynamic>.from(message.data);
    if (data.isEmpty) return;

    if (!_canNavigateNow(source: source)) {
      _pendingTapData = Map<String, dynamic>.from(data);
      _pendingTapSource = source;
      schedulePendingFlush();
      return;
    }

    final ok = await _openNotificationFromPushData(data, source: source);
    if (!ok) {
      _pendingTapData = Map<String, dynamic>.from(data);
      _pendingTapSource = source;
      schedulePendingFlush();
    }
  }

  @visibleForTesting
  static bool canNavigateForTap({
    required bool bootstrapComplete,
    required bool hasUser,
    required bool hasRouter,
    required bool appPastSplash,
  }) {
    if (!hasUser || !hasRouter) return false;
    return bootstrapComplete || appPastSplash;
  }

  static bool _canNavigateNow({required String source}) {
    return canNavigateForTap(
      bootstrapComplete: _bootstrapComplete,
      hasUser: StudentService.currentUser != null,
      hasRouter: globalLeerlingGoRouter != null,
      appPastSplash: _isAppPastSplash(),
    );
  }

  static bool _isAppPastSplash() {
    final loc = _currentLocationPath();
    if (loc == null) return false;
    return loc != '/splash' &&
        loc != '/login' &&
        !loc.startsWith('/registreer') &&
        loc != '/verificatie';
  }

  static String? _currentLocationPath() {
    final router = globalLeerlingGoRouter;
    if (router == null) return null;
    try {
      return router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return null;
    }
  }

  static void _clearPendingTap() {
    _pendingTapData = null;
    _pendingTapSource = null;
    _pendingFrameRetries = 0;
  }

  static Future<bool> _openNotificationFromPushData(
    Map<String, dynamic> data, {
    required String source,
  }) async {
    final appType = data['app_type'] as String?;
    if (appType != null && appType != 'leerling') return false;

    final notificationId = data['notification_id'] as String?;
    Notificatie? notificatie;

    if (notificationId != null && notificationId.isNotEmpty) {
      try {
        final rows = await StudentService.client
            .from('leerling_notificaties')
            .select()
            .eq('id', notificationId)
            .limit(1);
        final list = rows as List;
        if (list.isNotEmpty) {
          notificatie = Notificatie.fromJson(
            Map<String, dynamic>.from(list.first as Map),
          );
        }
      } catch (e) {
        debugPrint('[PushService] notificatie ophalen mislukt: $e');
      }
    }

    notificatie ??= () {
      final route = data['target_route'] as String?;
      if (route == null || route.isEmpty) return null;
      return Notificatie.fromPushData(data);
    }();

    if (notificatie == null) return false;
    return openLeerlingNotificatie(notificatie);
  }
}
