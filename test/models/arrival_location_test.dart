import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/models/arrival_location.dart';

void main() {
  group('ArrivalLocation.fromRow', () {
    test('parseert een geldige rij correct', () {
      final location = ArrivalLocation.fromRow({
        'latitude': 52.1,
        'longitude': 5.1,
        'accuracy_meters': 8.0,
        'speed_kmh': 32.4,
        'heading_degrees': 180.0,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
      expect(location, isNotNull);
      expect(location!.latitude, 52.1);
      expect(location.longitude, 5.1);
      expect(location.speedKmh, 32.4);
    });

    test('null rij -> null (geen locatie te tonen)', () {
      expect(ArrivalLocation.fromRow(null), isNull);
    });

    test('latitude buiten bereik -> null, veilig genegeerd', () {
      final location = ArrivalLocation.fromRow({
        'latitude': 91.0,
        'longitude': 5.1,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
      expect(location, isNull);
    });

    test('longitude buiten bereik -> null, veilig genegeerd', () {
      final location = ArrivalLocation.fromRow({
        'latitude': 52.1,
        'longitude': -181.0,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
      expect(location, isNull);
    });

    test('ontbrekende/malformed velden -> null, geen crash', () {
      final location = ArrivalLocation.fromRow({
        'latitude': 'niet-een-getal',
        'longitude': 5.1,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
      expect(location, isNull);
    });

    test('ontbrekende recorded_at -> null', () {
      final location = ArrivalLocation.fromRow({
        'latitude': 52.1,
        'longitude': 5.1,
      });
      expect(location, isNull);
    });
  });

  group('isStale', () {
    test('verse locatie (net binnen) is niet stale', () {
      final location = ArrivalLocation(
        latitude: 52.1,
        longitude: 5.1,
        recordedAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      expect(location.isStale(), false);
    });

    test('locatie ouder dan de drempel (90s) is stale', () {
      final location = ArrivalLocation(
        latitude: 52.1,
        longitude: 5.1,
        recordedAt: DateTime.now().subtract(const Duration(seconds: 120)),
      );
      expect(location.isStale(), true);
    });
  });
}
