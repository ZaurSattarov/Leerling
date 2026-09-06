// Guardtest (2026-09-05): bewijs dat de tijdelijke DEBUG-only UI-testmodus
// die eerder gebruikt is om de ArrivalLiveMap-render te bewijzen (Amersfoort-
// centrum-mock), volledig verwijderd is uit de productiecode.
//
// De echte productieflow werkt vanaf 2026-09-05 zonder mock: server-side
// migratie 20260905011800_live_aankomst_directe_zichtbaarheid.sql maakt
// dat sessies direct 'visible' zijn. Daardoor is de client-side override
// niet meer nodig en mag/hoort die er ook niet meer te zijn.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Leerling: geen debug-override voor Live Aankomst', () {
    test('geen enkel lib/-bestand refereert nog aan de verwijderde '
        'ARRIVAL_UI_TEST/ArrivalUiTestMode/resolveArrivalMount-symbolen',
        () {
      final overtreders = <String>[];
      final libDir = Directory('lib');
      expect(libDir.existsSync(), true, reason: 'lib/ moet bestaan');

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;
        final tekst = entity.readAsStringSync();
        for (final verboden in const [
          'ARRIVAL_UI_TEST',
          'ArrivalUiTestMode',
          'arrival_ui_test_mode',
          'resolveArrivalMount',
          'ArrivalMountDecision',
        ]) {
          if (tekst.contains(verboden)) {
            overtreders.add('${entity.path} bevat $verboden');
          }
        }
      }

      expect(overtreders, isEmpty,
          reason:
              'Debug-override sporen mogen niet in productiecode staan: '
              '${overtreders.join('\n')}');
    });

    test('geen enkel bestand in test/ definieert nog een debug-override, '
        'de tijdelijke testfiles zijn verwijderd', () {
      // Deze twee bestanden bestonden tijdelijk om de override te bewijzen
      // en zijn na oplevering verwijderd -- ze mogen nooit meer terugkomen.
      expect(
          File('test/features/arrival/arrival_ui_test_mode_test.dart')
              .existsSync(),
          false,
          reason:
              'Tijdelijke override-unit-test hoort niet meer te bestaan');
      expect(
          File('test/les_detail_arrival_ui_test_mode_test.dart').existsSync(),
          false,
          reason:
              'Tijdelijke override-widget-test hoort niet meer te bestaan');
    });

    test('les_detail_screen.dart hanteert nog steeds de expliciete '
        'productieconditie voor ArrivalLiveMap (sessie actief + zichtbaar '
        '+ location + niet stale)', () {
      final tekst =
          File('lib/features/planning/les_detail_screen.dart').readAsStringSync();
      // Geen mount-decision-abstractie meer, gewoon de directe boolean.
      expect(tekst.contains('final toonLiveAankomst'), true,
          reason:
              'Productiecode moet de directe toonLiveAankomst-boolean gebruiken');
      expect(tekst.contains('session.isActive()'), true);
      expect(tekst.contains('session.isVisible'), true);
      expect(tekst.contains('location != null'), true);
      expect(tekst.contains('!stale'), true);
      // Geen debug-tak.
      expect(tekst.toLowerCase().contains('debug'), false,
          reason:
              'les_detail_screen.dart mag geen debug-tak meer bevatten');
    });
  });
}
