// Canonical notificatie-navigatie voor de Leerling-app.
//
// Gebruikt door NotificatiesScreen (in-app tap) en PushService (push tap).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/notificatie.dart';

Future<bool> openLeerlingNotificatie(
  Notificatie notificatie, {
  BuildContext? context,
}) async {
  final route = notificatie.targetRoute;
  final router = globalLeerlingGoRouter;

  try {
    if (router != null) {
      router.go(route);
      final after =
          router.routerDelegate.currentConfiguration.uri.toString();
      return after.contains(Uri.parse(route).path);
    }
    if (context != null && context.mounted) {
      context.go(route);
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('[PushService] navigatie mislukt: $e');
    return false;
  }
}
