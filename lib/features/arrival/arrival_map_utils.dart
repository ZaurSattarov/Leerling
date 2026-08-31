import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pure, widget-vrije hulplogica voor de Live Aankomst-kaart (Feature 2,
/// Fase 3). Bewust gescheiden van `live_aankomst_card.dart`: een
/// `GoogleMap`-platformview is niet betrouwbaar in `flutter_test` te
/// initialiseren (geen echte native binding), dus deze pure functies zijn
/// wél volledig en eerlijk unit-testbaar los van de widget zelf.

const String arrivalMarkerId = 'instructeur';

/// De marker voor de actuele instructeur/lesauto-positie. Puur een
/// datamapping van `state.location` -- geen eigen logica over wanneer wél/
/// niet te tonen (dat blijft in `LiveAankomstCard`, gebaseerd op de
/// bestaande controller-state).
Marker arrivalMapMarkerFor(double latitude, double longitude) {
  return Marker(
    markerId: const MarkerId(arrivalMarkerId),
    position: LatLng(latitude, longitude),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    anchor: const Offset(0.5, 0.5),
  );
}

/// Haversine-afstand in meters tussen twee punten (bol-benadering, radius
/// 6371 km) -- zelfde formule als server-side `fn_arrival_publish_location`
/// (Instructeur-repo), hier uitsluitend voor UI-camera-beslissingen, geen
/// privacylogica.
double arrivalMapDistanceMeters(LatLng a, LatLng b) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _radians(b.latitude - a.latitude);
  final dLon = _radians(b.longitude - a.longitude);
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  return earthRadiusMeters * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
}

double _radians(double degrees) => degrees * (math.pi / 180);

/// Rustige camera-UX (§ "voorkom agressieve/onnodige camera-animaties"):
/// alleen opnieuw centreren als het nieuwe punt minstens [thresholdMeters]
/// van het vorige cameramiddelpunt afligt. Bij de eerste positie (geen
/// vorige) altijd centreren.
bool arrivalMapShouldRecenter({
  required LatLng? previous,
  required LatLng next,
  double thresholdMeters = 25,
}) {
  if (previous == null) return true;
  return arrivalMapDistanceMeters(previous, next) >= thresholdMeters;
}
