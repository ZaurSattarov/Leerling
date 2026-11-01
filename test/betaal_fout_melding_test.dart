import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/betaal_fout_melding.dart';

void main() {
  test('mfa_required wordt een begrijpelijke melding met vervolgstap', () {
    final melding =
        betaalFoutMelding(status: 403, details: {'error': 'mfa_required'});
    expect(melding, contains('verificatiecode'));
    expect(melding, isNot(contains('mfa_required')));
    expect(melding, isNot(contains('403')));
  });

  test('andermans factuur geeft een duidelijke melding', () {
    expect(
      betaalFoutMelding(
          status: 403, details: {'error': 'Geen toegang tot deze factuur'}),
      contains('niet bij jouw account'),
    );
  });

  test('al betaald, verlopen sessie en niet-beschikbaar', () {
    expect(betaalFoutMelding(status: 409), contains('al betaald'));
    expect(betaalFoutMelding(status: 401), contains('Log opnieuw in'));
    expect(
      betaalFoutMelding(details: {'code': 'MOLLIE_NOT_CONNECTED'}),
      contains('niet beschikbaar'),
    );
  });

  test('onbekende fouten tonen nooit technische tekst', () {
    final melding = betaalFoutMelding(
        status: 500, details: 'FunctionException(status: 500) DEBUG');
    expect(melding, isNot(contains('Exception')));
    expect(melding, isNot(contains('DEBUG')));
    expect(melding, contains('Probeer het later opnieuw'));
  });
}
