import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:leerling_app/features/arrival/arrival_map_utils.dart';

void main() {
  group('arrivalMapMarkerFor', () {
    test('marker-positie komt exact uit de opgegeven coördinaten', () {
      final marker = arrivalMapMarkerFor(52.123, 5.456);
      expect(marker.position, const LatLng(52.123, 5.456));
      expect(marker.markerId, const MarkerId(arrivalMarkerId));
    });

    test('altijd dezelfde markerId (1 marker, geen geschiedenis)', () {
      final a = arrivalMapMarkerFor(1, 1);
      final b = arrivalMapMarkerFor(2, 2);
      expect(a.markerId, b.markerId);
    });
  });

  group('arrivalMapDistanceMeters', () {
    test('zelfde punt -> 0 meter', () {
      const p = LatLng(52.1, 5.1);
      expect(arrivalMapDistanceMeters(p, p), closeTo(0, 0.001));
    });

    test('bekende afstand (~1 breedtegraad ≈ 111km) klopt ongeveer', () {
      const a = LatLng(52.0, 5.0);
      const b = LatLng(53.0, 5.0);
      final afstand = arrivalMapDistanceMeters(a, b);
      expect(afstand, greaterThan(110000));
      expect(afstand, lessThan(112000));
    });
  });

  group('arrivalMapShouldRecenter', () {
    test('geen vorige positie -> altijd centreren', () {
      expect(
        arrivalMapShouldRecenter(previous: null, next: const LatLng(52.1, 5.1)),
        true,
      );
    });

    test('klein verschil (< drempel) -> niet centreren (rustige camera-UX)',
        () {
      const vorige = LatLng(52.10000, 5.10000);
      const nieuw = LatLng(52.10005, 5.10000); // ~5-6m verschil
      expect(
        arrivalMapShouldRecenter(previous: vorige, next: nieuw, thresholdMeters: 25),
        false,
      );
    });

    test('groot verschil (>= drempel) -> wel centreren', () {
      const vorige = LatLng(52.1000, 5.1000);
      const nieuw = LatLng(52.1010, 5.1000); // ~111m verschil
      expect(
        arrivalMapShouldRecenter(previous: vorige, next: nieuw, thresholdMeters: 25),
        true,
      );
    });
  });
}
