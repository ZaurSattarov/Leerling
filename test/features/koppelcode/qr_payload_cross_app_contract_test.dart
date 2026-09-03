import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/koppelcode/koppel_flow.dart';

/// CROSS-APP CONTRACT-TEST -- Instructeur QR ↔ Leerling scanner.
///
/// De Instructeur-app genereert de QR-code in
/// `rijschool-planner-flutter/lib/features/leerlingen/quick_student_flow.dart`
/// (`StudentCouplingShareData`): `String get qrPayload => code;`.
///
/// De payload IS dus exact de 8-tekens koppelcode, zonder prefix, zonder
/// JSON-wrapping, zonder URL-schema. Deze test bewaakt dat contract door
/// vanuit een set representatieve payloads te bewijzen dat
/// `KoppelFlow.normalizeCode` ze exact accepteert en het canonical formaat
/// oplevert dat vervolgens naar `koppel_leerling_met_code({p_koppel_code})`
/// gaat -- dezelfde RPC die de handmatige koppelcode-flow ook gebruikt.
///
/// Verandering aan het Instructeur-QR-formaat (bv. wrapping in JSON of een
/// URL) MOET deze test roodgevaald krijgen zodat de Leerling-scanner
/// tegelijk mee wordt aangepast. Nooit een tweede parallel QR-formaat
/// bouwen (Absolute Regel #2).
void main() {
  test('directe koppelcode-string uit Instructeur qrPayload wordt 1:1 '
      'geaccepteerd door de scanner', () {
    // Zoals gegenereerd door de Instructeur-app.
    const qrUitInstructeur = 'A1B2C3D4';
    expect(KoppelFlow.normalizeCode(qrUitInstructeur), 'A1B2C3D4');
  });

  test('lowercase QR (indien ooit door een QR-lezer zo terugkomt) wordt '
      'genormaliseerd naar dezelfde canonical code als de handmatige '
      'invoer', () {
    expect(KoppelFlow.normalizeCode('a1b2c3d4'),
        KoppelFlow.normalizeCode('A1B2C3D4'));
  });

  test('een JSON- of URL-wrapping (nieuw formaat) mag NIET stilzwijgend '
      'als koppelcode worden opgevat', () {
    // Als de Instructeur-app ooit besluit een URL of JSON in de QR te
    // stoppen, moet de scanner een duidelijke foutmelding tonen ("Deze
    // code herkennen we niet") in plaats van er een gokje op te wagen.
    expect(KoppelFlow.normalizeCode('https://klantio.nl/k/A1B2C3D4'), isNull);
    expect(KoppelFlow.normalizeCode('{"code":"A1B2C3D4"}'), isNull);
    expect(KoppelFlow.normalizeCode('KLANTIO:A1B2C3D4'), isNull);
  });
}
