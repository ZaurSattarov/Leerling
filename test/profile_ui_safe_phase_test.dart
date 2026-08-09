import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/constants/app_colors.dart';
import 'package:leerling_app/features/profiel/widgets/profile_info_row.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  testWidgets('ProfileInfoRow toont rijbewijscategorie en lange waarden',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: ProfileInfoRow(
              icon: Icons.directions_car_outlined,
              iconColor: AppColors.iconDark,
              label: 'Rijbewijscategorie',
              value: 'een.heel.lang.emailadres.voor.test@example-rijschool.nl',
              maxValueLines: 3,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Rijbewijscategorie'), findsOneWidget);
    expect(find.textContaining('example-rijschool.nl'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Persoonlijke gegevens en Mijn rijschool gebruiken gedeelde detailrij',
      () {
    final persoonlijk =
        read('lib/features/profiel/persoonlijke_gegevens_screen.dart');
    final rijschool = read('lib/features/profiel/mijn_rijschool_screen.dart');

    expect(persoonlijk, contains('ProfileInfoRow'));
    expect(rijschool, contains('ProfileInfoRow'));
    expect(persoonlijk, isNot(contains('class _GegevensRij')));
    expect(rijschool, isNot(contains('class _GegevensRij')));
  });

  test('Mijn rijschool gebruikt geen email als naamfallback', () {
    final source = read('lib/features/profiel/mijn_rijschool_screen.dart');
    expect(source, contains("label: 'Naam instructeur'"));
    expect(source, isNot(contains('email ??')));
    expect(source, isNot(contains('email! : instructeur.naam')));
  });

  test('Lespakket-tegel heeft pakketnaam in subtitel en geen losse trailing',
      () {
    final source = read('lib/features/profiel/profiel_screen.dart');
    expect(source, contains('_lespakketSubtitle'));
    expect(source, contains('lessen resterend'));
    expect(source, isNot(contains('trailingText: p?.pakketNaam')));
  });

  test(
      'Beschikbaarheid gebruikt eigen TimeInputFormatter, geïntegreerd in '
      'één formulier, en behoudt validatie', () {
    final source =
        read('lib/features/beschikbaarheid/beschikbaarheid_screen.dart');
    // Begin/Einde zijn sinds de samenvoeging rechtstreeks bewerkbare
    // tekstvelden in "Tijdblok toevoegen" -- geen los tweede
    // tijd-picker-sheet meer, geen platform-picker.
    expect(source, isNot(contains('_KlantioTijdPickerSheet')));
    expect(source, isNot(contains("Text('Tijd gebruiken')")));
    expect(source, contains('TimeInputFormatter'));
    expect(source, isNot(contains('showTimePicker')));
    expect(source, contains('Starttijd moet vóór eindtijd zijn.'));
  });

  test('Examenstatussen gepland geslaagd gezakt hebben semantische badges', () {
    final source = read('lib/features/examens/examens_screen.dart');
    expect(source, contains('AppColors.infoBg'));
    expect(source, contains('AppColors.successBg'));
    expect(source, contains('AppColors.dangerBg'));
    expect(source, contains('ExamenStatus.gepland'));
    expect(source, contains('ExamenStatus.geslaagd'));
    expect(source, contains('ExamenStatus.gezakt'));
  });

  test('Contactsheet toont bellen whatsapp en email met ContactUri', () {
    final source = read('lib/features/profiel/profiel_screen.dart');
    expect(source, contains("'Bellen'"));
    expect(source, contains("'WhatsApp'"));
    expect(source, contains("'E-mail'"));
    expect(source, contains('ContactUri.tel'));
    expect(source, contains('ContactUri.whatsapp'));
    expect(source, contains('ContactUri.email'));
  });

  test('Meldingen groeperen en onderscheiden ongelezen meldingen', () {
    final source = read('lib/features/notificaties/notificaties_screen.dart');
    expect(source, contains('_groepeerNotificaties'));
    expect(source, contains("'Vandaag'"));
    expect(source, contains("'Deze week'"));
    expect(source, contains("'Eerder'"));
    expect(source, contains('AppColors.primaryLight'));
  });

  test('Help gebruikt uitsluitend het officiële supportkanaal', () {
    final source = read('lib/features/help/help_screen.dart');
    expect(source, contains('info@klantio.com'));
    expect(source, contains('Klantio Support'));
    expect(
      source,
      contains('Stuur ons een e-mail. We reageren zo snel mogelijk.'),
    );
    expect(source, isNot(contains('Supportadres nog niet geconfigureerd')));
    expect(source, isNot(contains('Bel je rijschool')));
    expect(source, isNot(contains('ContactUri.tel')));
    expect(source, contains('ContactUri.email'));
  });

  test('Wachtwoordreset heeft loading succes en foutstatus', () {
    final source = read('lib/features/profiel/profiel_screen.dart');
    expect(source, contains('_wachtwoordResetLaden'));
    expect(source, contains('Resetmail wordt verstuurd'));
    expect(source, contains('E-mail met resetlink verstuurd'));
    expect(source, contains('Versturen mislukt. Probeer opnieuw.'));
  });

  test('Juridische routes openen in-app pagina met conceptcontent', () {
    final app = read('lib/app.dart');
    final privacy = read('lib/features/legal/content/privacy_policy_nl.dart');
    final terms = read('lib/features/legal/content/terms_conditions_nl.dart');
    expect(app, contains('/profiel/privacy'));
    expect(app, contains('/profiel/algemene-voorwaarden'));
    expect(app, contains('LegalDocumentScreen'));
    expect(privacy, contains('Juridisch concept'));
    expect(terms, contains('Juridisch concept'));
    expect(privacy, contains('Nog vast te stellen'));
    expect(terms, contains('Nog vast te stellen'));
  });
}
