// Registratiescherm vereenvoudigd (2026-09-01): "Volledige naam" is
// volledig verwijderd -- alleen e-mailadres + wachtwoord blijven over. Deze
// tests bewijzen dat het naamveld en de bijbehorende validatie echt weg
// zijn, dat de bestaande e-mail-/wachtwoordvalidatie ongewijzigd werkt, en
// dat de signup-payload geen naam meer bevat.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/auth/registreer_screen.dart';

void main() {
  Future<void> pompScherm(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegistreerScreen()));
    await tester.pump();
  }

  testWidgets('naamveld bestaat niet meer op het registratiescherm',
      (tester) async {
    await pompScherm(tester);

    expect(find.widgetWithText(TextFormField, 'Volledige naam'), findsNothing);
    expect(find.text('Volledige naam'), findsNothing);
    // Precies twee invoervelden: e-mailadres + wachtwoord.
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('scherm bevat uitsluitend e-mail, wachtwoord, actie en link',
      (tester) async {
    await pompScherm(tester);

    expect(find.text('E-mailadres'), findsOneWidget);
    expect(find.text('Wachtwoord (min. 8 tekens)'), findsOneWidget);
    expect(find.text('Account aanmaken ›'), findsOneWidget);
    expect(find.text('Al een account? '), findsOneWidget);
    expect(find.text('Inloggen'), findsOneWidget);
  });

  testWidgets('lege e-mail wordt geweigerd (bestaande validatie intact)',
      (tester) async {
    await pompScherm(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Wachtwoord (min. 8 tekens)'),
        'geldigwachtwoord');
    await tester.tap(find.text('Account aanmaken ›'));
    await tester.pump();

    expect(find.text('Vul je e-mailadres in'), findsOneWidget);
  });

  testWidgets('te kort wachtwoord wordt geweigerd (bestaande validatie intact)',
      (tester) async {
    await pompScherm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mailadres'),
        'leerling@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Wachtwoord (min. 8 tekens)'),
        'kort1');
    await tester.tap(find.text('Account aanmaken ›'));
    await tester.pump();

    expect(find.text('Minimaal 8 tekens'), findsOneWidget);
  });

  testWidgets(
      'geldig e-mailadres + geldig wachtwoord geeft geen enkele '
      'validatiefout meer (geen naam-validation, submit gaat door)',
      (tester) async {
    await pompScherm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mailadres'),
        'leerling@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Wachtwoord (min. 8 tekens)'),
        'geldigwachtwoord');
    await tester.tap(find.text('Account aanmaken ›'));
    await tester.pump();

    expect(find.text('Vul je e-mailadres in'), findsNothing);
    expect(find.text('Ongeldig e-mailadres'), findsNothing);
    expect(find.text('Vul een wachtwoord in'), findsNothing);
    expect(find.text('Minimaal 8 tekens'), findsNothing);
    expect(find.text('Vul je naam in'), findsNothing);
  });

  test('signup-payload bevat geen naam/full_name meer', () {
    final source =
        File('lib/features/auth/registreer_screen.dart').readAsStringSync();
    expect(source, isNot(contains("'naam':")));
    expect(source, isNot(contains("'full_name'")));
    expect(source, isNot(contains('_naamCtrl')));
    // role/type/account_type zijn niet naam-gerelateerd en blijven bestaan.
    expect(source, contains("'role': 'leerling'"));
  });
}
