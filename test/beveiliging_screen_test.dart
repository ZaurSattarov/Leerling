import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source =
      File('lib/features/profiel/beveiliging_screen.dart').readAsStringSync();
  final rowSource =
      File('lib/features/profiel/widgets/settings_action_row.dart')
          .readAsStringSync();

  test('beveiligingsheader en passwordkaart gebruiken auth-data', () {
    // Sinds de header-refactor (klantio_header_test.dart) heeft
    // MainDetailHeader geen eyebrowText-parameter meer.
    // Sinds 2026-10-06: SettingsScaffold (Instructeur-app), e-mailadres als
    // alleen-lezen veld.
    expect(source, contains("titel: 'Beveiliging'"));
    expect(source, contains('StudentService.currentUser?.email'));
    expect(source, contains("label: 'E-mailadres'"));
    expect(source, isNot(contains('@gmail.com')));
    expect(source, contains('Wachtwoord herstellen'));
  });

  test('wachtwoord herstellen is een tegel met laadstatus (geen losse knop)',
      () {
    expect(source, contains("title: 'Wachtwoord herstellen'"));
    expect(source, contains('Resetlink wordt verstuurd'));
    expect(source, isNot(contains('OutlinedButton.icon')));
  });

  test('resetkaart en resetrij gebruiken dezelfde resetmethode', () {
    expect(
      RegExp(r'StudentService\.stuurWachtwoordReset').allMatches(source),
      hasLength(1),
    );
    expect(source, contains('email == null || _resetLaden ? null : _stuurReset'));
    expect(source, contains('De resetlink is verstuurd'));
    expect(source, contains('Het versturen van de resetlink is mislukt'));
  });

  test('accountbeveiliging toont drie echte acties', () {
    expect(source, contains("title: 'Ingelogd account'"));
    expect(source, contains("title: 'Wachtwoord herstellen'"));
    expect(source, contains("title: 'Uitloggen op dit apparaat'"));
    expect(source, isNot(contains('Gebruik altijd je eigen account')));
    expect(source, contains('showModalBottomSheet'));
    expect(source, contains('StudentService.uitloggen()'));
    expect(source, contains('showDialog<bool>'));
  });

  test('settingsrij is gedeeld en toegankelijk', () {
    expect(rowSource, contains('class SettingsActionRow'));
    expect(rowSource, contains('Semantics('));
    // Delegeert aan ProfielMenuTile (zelfde tegel als het Profiel-hoofdscherm).
    expect(rowSource, contains('ProfielMenuTile('));
  });
}
