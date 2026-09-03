import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/models/arrival_settings_info.dart';

void main() {
  group('ArrivalSettingsInfo.fromRpcResult', () {
    test('eligible=true + geldig minutenveld -> eligible met minuten', () {
      final info = ArrivalSettingsInfo.fromRpcResult(
        {'eligible': true, 'visible_from_minutes': 15},
      );
      expect(info.eligible, true);
      expect(info.visibleFromMinutes, 15);
    });

    for (final minuten in [10, 15, 20]) {
      test('$minuten minuten wordt correct als int overgenomen', () {
        final info = ArrivalSettingsInfo.fromRpcResult(
          {'eligible': true, 'visible_from_minutes': minuten},
        );
        expect(info.visibleFromMinutes, minuten);
      });
    }

    test('eligible=false -> nietBeschikbaar, ongeacht minutenveld', () {
      final info = ArrivalSettingsInfo.fromRpcResult(
        {'eligible': false, 'visible_from_minutes': 15},
      );
      expect(info.eligible, false);
      expect(info.visibleFromMinutes, isNull);
    });

    test('eligible=true maar minutenveld ontbreekt -> fail-safe '
        'nietBeschikbaar (nooit eligible zonder geldig venster)', () {
      final info = ArrivalSettingsInfo.fromRpcResult({'eligible': true});
      expect(info.eligible, false);
      expect(info.visibleFromMinutes, isNull);
    });

    test('null respons -> nietBeschikbaar, geen crash', () {
      final info = ArrivalSettingsInfo.fromRpcResult(null);
      expect(info.eligible, false);
    });

    test('onverwacht type (bv. List) -> nietBeschikbaar, geen crash', () {
      final info = ArrivalSettingsInfo.fromRpcResult([1, 2, 3]);
      expect(info.eligible, false);
    });
  });
}
