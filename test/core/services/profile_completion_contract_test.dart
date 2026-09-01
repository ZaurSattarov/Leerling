import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profielafronding gebruikt uitsluitend de beveiligde RPC', () {
    final source =
        File('lib/core/services/student_service.dart').readAsStringSync();
    expect(source, contains("'voltooi_leerling_profiel'"));
    expect(source, contains("'p_achternaam'"));
    expect(source, contains("'p_geboortedatum'"));
    expect(source, contains("'p_avatar_id'"));
  });

  // Aanmeld herstelronde, vervolg (2026-09-01): PGRST202 in productie
  // bevestigde dat de client p_geslacht/p_adres al meestuurde vóórdat de
  // live RPC die parameters ondersteunde. Canonical migratie:
  // rijschool-planner-flutter/supabase/migrations/
  // 20260901120000_voltooi_leerling_profiel_geslacht_adres.sql (gedeployed).
  test('profielafronding stuurt geslacht/adres alleen mee als ingevuld', () {
    final source =
        File('lib/core/services/student_service.dart').readAsStringSync();
    expect(source, contains("'p_geslacht'"));
    expect(source, contains("'p_adres'"));
    // Bestaande 3 parameters blijven onvoorwaardelijk verplicht -- alleen
    // geslacht/adres zijn optioneel toegevoegd (geen regressie op de
    // bestaande achternaam/geboortedatum/avatar-flow).
    expect(source, contains('String? geslacht'));
    expect(source, contains('String? adres'));
  });

  test('profile gate hervat incomplete profiel-flow', () {
    final source =
        File('lib/shared/widgets/student_profile_gate.dart').readAsStringSync();
    expect(source, contains('isProfielCompleet'));
    expect(source, contains("'/profiel-afronden'"));
  });

  // Aanmeld herstelronde, vervolg: geboortedatum date picker, geslacht-
  // selectie en de "Profiel afronden"-knop gebruikten allemaal een
  // afwijkende bruin/rode kleur i.p.v. het officiële Klantio primary-token.
  test('datepicker: geselecteerde dag gebruikt AppColors.primary', () {
    final source = File('lib/app.dart').readAsStringSync();
    expect(source, contains('dayForegroundColor'));
    expect(source, contains('dayBackgroundColor'));
    expect(source, contains('WidgetState.selected'));
  });

  test('geslachtselectie gebruikt solid AppColors.primary (geen ChoiceChip)',
      () {
    final source = File('lib/features/profiel/profiel_afronden_screen.dart')
        .readAsStringSync();
    expect(source, isNot(contains('ChoiceChip')));
    expect(source, contains('class _GeslachtOptie'));
    expect(source, contains('selected ? AppColors.primary : AppColors.white'));
    expect(source, contains('selected ? Colors.white : AppColors.textPrimary'));
  });

  test('"Profiel afronden" gebruikt het bestaande ElevatedButton-thema', () {
    final source = File('lib/features/profiel/profiel_afronden_screen.dart')
        .readAsStringSync();
    expect(source, contains('ElevatedButton('));
    expect(source, isNot(contains('FilledButton(')));
  });

  test('splash behandelt profielnetwerkfout niet als ontbrekend profiel', () {
    final source =
        File('lib/features/splash/splash_screen.dart').readAsStringSync();
    expect(source, contains('on ProfileLookupException'));
    expect(source, contains("context.go('/home')"));
    expect(
      source,
      isNot(contains('profielcheck fout')),
    );
  });
}
