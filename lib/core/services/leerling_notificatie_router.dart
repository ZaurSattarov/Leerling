// Canonical notificatie-navigatie voor de Leerling-app.
//
// Gebruikt door NotificatiesScreen (in-app tap) en PushService (push tap).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/notificatie.dart';
import '../../shared/widgets/snackbar.dart';
import 'student_service.dart';

/// Uitleg bij een melding waarvan de les niet meer bestaat.
const String kLesVerwijderdUitleg =
    'Deze les is verwijderd door je instructeur.';

/// Bepaalt of de les van een melding zeker niet (meer) bestaat. Bij een
/// laad- of netwerkfout is het antwoord `false`: alleen als zeker is dat de
/// les ontbreekt tonen we 'Les verwijderd'.
Future<bool> lesVanMeldingVerwijderd(
  Notificatie notificatie, {
  Future<Set<String>> Function(Set<String> ids)? bestaandeLesIds,
}) async {
  final lesId = notificatie.lesId;
  if (lesId == null) return false;
  try {
    final bestaand =
        await (bestaandeLesIds ?? StudentService.bestaandeLesIds)({lesId});
    return !bestaand.contains(lesId);
  } catch (e) {
    debugPrint('[Notificatie] lescontrole mislukt: $e');
    return false;
  }
}

Future<bool> openLeerlingNotificatie(
  Notificatie notificatie, {
  BuildContext? context,
  Future<Set<String>> Function(Set<String> ids)? bestaandeLesIds,
}) async {
  final route = notificatie.targetRoute;
  final router = globalLeerlingGoRouter;
  final pad = Uri.tryParse(route)?.path ?? route;

  try {
    // Verwijderde les: geen foutscherm, maar een korte uitleg.
    if (await lesVanMeldingVerwijderd(notificatie,
        bestaandeLesIds: bestaandeLesIds)) {
      final uitlegContext =
          context ?? router?.routerDelegate.navigatorKey.currentContext;
      if (uitlegContext != null && uitlegContext.mounted) {
        showAppSnackBar(uitlegContext, kLesVerwijderdUitleg);
      }
      if (context == null && router != null) {
        router.go('/notificaties');
      }
      return true;
    }
    if (context != null && context.mounted) {
      context.push(route);
      return true;
    }
    if (router != null) {
      if (pad == '/home' || pad == '/login' || pad == '/onboarding') {
        router.go(route);
      } else {
        router.go('/home');
        Future.microtask(() => router.push(route));
      }
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('[PushService] navigatie mislukt: $e');
    return false;
  }
}
