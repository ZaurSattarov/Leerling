import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/koppelcode/koppel_flow.dart';

void main() {
  group('KoppelFlow.normalizeCode -- QR-payload en handmatige invoer geven '
      'exact hetzelfde canonical formaat', () {
    test('trimt spaties, upper-cased 8-tekens hex-achtige code', () {
      expect(KoppelFlow.normalizeCode('  a1b2c3d4  '), 'A1B2C3D4');
    });

    test('accepteert de directe QR-payload zoals de Instructeur-app die '
        'genereert (StudentCouplingShareData.qrPayload => code)', () {
      // Realistisch voorbeeld: 8 hoofdletters/cijfers.
      expect(KoppelFlow.normalizeCode('ABCD1234'), 'ABCD1234');
    });

    test('verwijdert interne whitespace (per ongeluk copy-paste)', () {
      expect(KoppelFlow.normalizeCode('ABC 1234'), 'ABC1234');
    });

    test('weigert lege string', () {
      expect(KoppelFlow.normalizeCode(''), isNull);
      expect(KoppelFlow.normalizeCode('    '), isNull);
    });

    test('weigert QR-code die duidelijk niet een koppelcode is (URL, JSON, '
        'te kort, te lang, ongeldige tekens)', () {
      expect(KoppelFlow.normalizeCode('https://klantio.nl/foo'), isNull);
      expect(KoppelFlow.normalizeCode('{"foo":"bar"}'), isNull);
      expect(KoppelFlow.normalizeCode('ABC'), isNull); // te kort
      expect(KoppelFlow.normalizeCode('ABCD12345678ABCD'), isNull); // te lang
      expect(KoppelFlow.normalizeCode('ABCD-1234'), isNull); // koppelteken
      expect(KoppelFlow.normalizeCode('ABCD_1234'), isNull); // underscore
    });

    test('handmatige lowercase invoer wordt genormaliseerd naar hoofdletters '
        'zodat de RPC (die p_koppel_code trimt+uppercase krijgt) dezelfde '
        'canonical string ontvangt als bij een QR-scan', () {
      const ruw = 'abcd1234';
      expect(KoppelFlow.normalizeCode(ruw), 'ABCD1234');
    });
  });
}
