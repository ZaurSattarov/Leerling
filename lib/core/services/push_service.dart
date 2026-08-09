// Push notificaties (Fase 5) — Leerling-app.
//
// Gebruikt UITSLUITEND de al bestaande, live centrale backend (dezelfde
// als de Instructeur-app, zelfde Supabase-project):
//   - register_push_token / deactivate_push_token RPC's
//   - push-dispatch Edge Function (server-side, leest voorkeuren/tokens)
//   - leerling_notificatie_router.dart voor waar een tik naartoe navigeert,
//     die op zijn beurt hergebruikt wat lib/models/notificatie.dart al aan
//     route-validatie (_veiligeRoute/routeVoorType) doet — geen tweede
//     routinglaag.
//
// Bewust een gewone (statische) service, geen Riverpod-provider: zo kan
// zowel app.dart als StudentService.uitloggen() (statisch) 'm aanroepen.
// Voor het moment dat een Riverpod-provider ververst moet worden
// (foreground refresh) wordt de rootNavigatorKey gebruikt om bij de
// ProviderContainer te komen.
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../features/notificaties/notificaties_provider.dart';
import '../../models/notificatie.dart';
import 'leerling_notificatie_router.dart';
import 'student_service.dart';

const _devicePrefKey = 'klantio_push_device_id_v1';

abstract class PushService {
  static bool _listenersAttached = false;
  static String? _deviceId;

  /// Zelfde aanpak als de Instructeur-app: lokaal willekeurig ID, geen
  /// hardware-identifier.
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

  static Future<void> ensureInitialized() async {
    if (_listenersAttached) return;
    _listenersAttached = true;
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
  }

  /// Aanroepen na (her)login. Idempotent.
  static Future<void> requestPermissionAndRegister() async {
    if (StudentService.currentUser == null) return;
    await ensureInitialized();
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushService] pushpermissie geweigerd door gebruiker');
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('[PushService] permissie/registratie mislukt: $e');
    }
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
      debugPrint('[PushService] token geregistreerd');
    } catch (e) {
      debugPrint('[PushService] register_push_token mislukt: $e');
    }
  }

  /// Aanroepen bij logout, VOORDAT client.auth.signOut() de sessie sluit.
  static Future<void> deactivateForLogout() async {
    try {
      final deviceId = await _deviceIdValue();
      await StudentService.client
          .rpc('deactivate_push_token', params: {'p_device_id': deviceId});
    } catch (e) {
      debugPrint('[PushService] deactivate_push_token mislukt: $e');
    }
  }

  /// Foreground: de bestaande Realtime-subscription in
  /// notificaties_provider.dart ververst de lijst meestal al vanzelf; dit
  /// is een extra, goedkope zekerheid. Geen eigen banner (zelfde
  /// Fase H-besluit als Instructeur).
  static void _onForegroundMessage(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    container.invalidate(notificatiesProvider);
    container.invalidate(ongelezenNotificatiesProvider);
  }

  static Future<void> handleInitialMessageIfAny() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) await _handleTap(message.data);
  }

  /// Payload geeft NOOIT autorisatie: de échte rij wordt via de bestaande
  /// RLS-beveiligde query opgehaald (student_notificaties_select-policy
  /// beperkt dit al tot leerling_id's van de ingelogde gebruiker).
  static Future<void> _handleTap(Map<String, dynamic> data) async {
    final notificationId = data['notification_id'] as String?;
    if (notificationId == null || notificationId.isEmpty) return;
    if (StudentService.currentUser == null) return;
    try {
      final rows = await StudentService.client
          .from('leerling_notificaties')
          .select()
          .eq('id', notificationId)
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) return;
      final notificatie =
          Notificatie.fromJson(Map<String, dynamic>.from(list.first as Map));
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await openLeerlingNotificatie(context, notificatie);
    } catch (e) {
      debugPrint('[PushService] tap-afhandeling mislukt: $e');
    }
  }
}
