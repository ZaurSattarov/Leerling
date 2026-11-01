/// Vertaalt een mislukte betaalaanvraag naar een begrijpelijke Nederlandse
/// melding met een passende vervolgstap. Nooit technische details tonen.
String betaalFoutMelding({int? status, Object? details}) {
  String fout = '';
  String code = '';
  if (details is Map) {
    fout = (details['error'] ?? '').toString().toLowerCase();
    code = (details['code'] ?? '').toString().toUpperCase();
  } else if (details != null) {
    fout = details.toString().toLowerCase();
  }

  if (status == 401) {
    return 'Je sessie is verlopen. Log opnieuw in en probeer het nog eens.';
  }
  if (fout.contains('mfa_required')) {
    return 'Dit account heeft extra beveiliging aan staan. Bevestig eerst je '
        'verificatiecode in de Instructeur-app en probeer het daarna opnieuw.';
  }
  if (fout.contains('geen toegang')) {
    return 'Deze factuur hoort niet bij jouw account. Neem contact op met je '
        'rijschool.';
  }
  if (status == 409 || fout.contains('al betaald')) {
    return 'Deze factuur is al betaald. Open de factuur opnieuw om de status '
        'te zien.';
  }
  if (code == 'KLANTIO_BILLING_BLOCKED' ||
      code == 'FREE_PLAN_NO_AUTOMATIC_PAYMENT_LINK' ||
      code == 'MOLLIE_NOT_CONNECTED' ||
      code == 'MOLLIE_PROFILE_MISSING') {
    return 'Online betalen is voor deze rijschool nu niet beschikbaar. Neem '
        'contact op met je instructeur.';
  }
  return 'Het aanmaken van de betaling is niet gelukt. Probeer het later '
      'opnieuw of neem contact op met je rijschool.';
}
