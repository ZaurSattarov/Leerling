// Plek van het ophaaladres. De telefoon zoekt het adres zelf op; er is geen
// Google Geocoding API, Routes API of Edge Function bij betrokken. De leerling
// leest alleen en bewaart niets.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../utils/les_kaart.dart';

typedef AdresTreffer = ({
  double lat,
  double lng,
  String? plaats,
  String? postcode,
});

typedef AdresZoeker = Future<List<AdresTreffer>> Function(String adres);

typedef LesKaartVraag = ({
  String adres,
  double? lat,
  double? lng,
  String? coordAdres,
});

final lesKaartServiceProvider = Provider<LesKaartService>(
  (ref) => LesKaartService(),
);

final lesKaartPuntProvider =
    FutureProvider.autoDispose.family<LesKaartPunt?, LesKaartVraag>(
  (ref, vraag) => ref.watch(lesKaartServiceProvider).bepaal(vraag),
);

class LesKaartService {
  LesKaartService({AdresZoeker? zoek}) : _zoek = zoek ?? _zoekOpTelefoon;

  final AdresZoeker _zoek;
  static const _tijdslimiet = Duration(seconds: 6);

  // De zoekdienst van de telefoon heeft een limiet: per adres één keer zoeken.
  final Map<String, LesKaartPunt> _gezocht = {};

  static Future<List<AdresTreffer>> _zoekOpTelefoon(String adres) async {
    await geo.setLocaleIdentifier('nl_NL');
    final treffers = await geo.locationFromAddress('$adres, Nederland');
    return [
      // Eén treffer: Apple vraagt om zo min mogelijk zoekopdrachten.
      for (final t in treffers.take(1))
        await _metPlaats(t.latitude, t.longitude),
    ];
  }

  static Future<AdresTreffer> _metPlaats(double lat, double lng) async {
    final plekken = await geo.placemarkFromCoordinates(lat, lng);
    final plek = plekken.isEmpty ? null : plekken.first;
    return (
      lat: lat,
      lng: lng,
      plaats: plek?.locality,
      postcode: plek?.postalCode,
    );
  }

  Future<LesKaartPunt?> bepaal(LesKaartVraag vraag) async {
    final bewaard = bewaardLesKaartPunt(
      adres: vraag.adres,
      lat: vraag.lat,
      lng: vraag.lng,
      coordAdres: vraag.coordAdres,
    );
    if (bewaard != null) return bewaard;

    final sleutel = normaliseerLesAdres(vraag.adres);
    if (sleutel.isEmpty) return null;
    final bekend = _gezocht[sleutel];
    if (bekend != null) return bekend;

    try {
      final treffers = await _zoek(vraag.adres).timeout(_tijdslimiet);
      for (final t in treffers) {
        if (lesCoordinaatGeldig(t.lat, t.lng) &&
            lesAdresBevatPlek(
              adres: vraag.adres,
              plaats: t.plaats,
              postcode: t.postcode,
            )) {
          return _gezocht[sleutel] = LesKaartPunt(lat: t.lat, lng: t.lng);
        }
      }
    } catch (_) {
      // Geen treffer of geen verbinding: de les toont dan de gewone card.
    }
    return null;
  }
}
