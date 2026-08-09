// Veilige notificatie-navigatie voor de Leerling-app (Fase 5).
//
// Hergebruikt bewust de al bestaande route-validatie in
// lib/models/notificatie.dart (Notificatie.fromJson → routeVoorType() /
// _veiligeRoute()): elke Notificatie die uit de database komt heeft al een
// gevalideerde `targetRoute` die uitsluitend op een van de echte,
// toegestane paden van deze app kan wijzen (/home, /planning, /planning/:id,
// /les-logboek, /lesvoorbereiding, /examenadvies, /voortgang,
// /voortgang/lespakket, /facturen, /facturen/:id, /profiel, /notificaties,
// /beschikbaarheid). Er wordt hier dus GEEN nieuwe routelijst verzonnen —
// alleen de navigatie zelf uitgevoerd, met een veilige fallback.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../models/notificatie.dart';

/// Opent de bestemming van [notificatie]. Gebruikt `push` voor routes met
/// een entity-id (detail-schermen, terug-navigatie zinvol) en `go` voor
/// top-level/lijst-routes — zelfde onderscheid als de Instructeur-router.
Future<void> openLeerlingNotificatie(
  BuildContext context,
  Notificatie notificatie,
) async {
  final route = notificatie.targetRoute;
  final segments = Uri.tryParse(route)?.pathSegments ?? const [];
  final isDetailRoute = segments.length >= 2; // bv. planning/<id>, facturen/<id>

  try {
    if (isDetailRoute) {
      context.push(route);
    } else {
      context.go(route);
    }
  } catch (e) {
    debugPrint('[LeerlingNotificatieRouter] navigatie naar "$route" mislukt: $e');
    try {
      context.go('/notificaties');
    } catch (_) {
      // Zelfs de fallback lukte niet (bv. context al unmounted) -- niets
      // meer aan te doen, geen crash veroorzaken.
    }
  }
}
