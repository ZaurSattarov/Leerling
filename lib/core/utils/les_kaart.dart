// Pure regels voor de kaartcard in de lesdetails. Zelfde regels als de
// Instructeur-app (`lib/core/utils/les_kaart.dart` daar).

class LesKaartPunt {
  final double lat;
  final double lng;

  const LesKaartPunt({required this.lat, required this.lng});
}

String normaliseerLesAdres(String? adres) =>
    (adres ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// De app werkt in Nederland: een punt daarbuiten is een foute zoekuitkomst.
/// Sluit ook 0,0 en onbruikbare getallen uit.
bool lesCoordinaatGeldig(double? lat, double? lng) {
  if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) {
    return false;
  }
  return lat >= 50.5 && lat <= 53.8 && lng >= 3.0 && lng <= 7.5;
}

/// Ligt de gevonden plek echt bij dit adres? Zonder plaats of postcode in het
/// adres kan de telefoon een straat in een andere stad kiezen; dan geen pin.
bool lesAdresBevatPlek({
  required String adres,
  required String? plaats,
  required String? postcode,
}) {
  final tekst = adres.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  bool bevat(String? deel) {
    final schoon = (deel ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return schoon.isNotEmpty && tekst.contains(schoon);
  }

  return bevat(plaats) || bevat(postcode);
}

/// Bewaarde coördinaten gelden alleen voor het adres waarvoor ze zijn bepaald.
LesKaartPunt? bewaardLesKaartPunt({
  required String? adres,
  required double? lat,
  required double? lng,
  required String? coordAdres,
}) {
  final huidig = normaliseerLesAdres(adres);
  if (huidig.isEmpty || huidig != normaliseerLesAdres(coordAdres)) return null;
  if (!lesCoordinaatGeldig(lat, lng)) return null;
  return LesKaartPunt(lat: lat!, lng: lng!);
}
