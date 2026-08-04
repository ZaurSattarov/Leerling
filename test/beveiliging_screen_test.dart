import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source =
      File('lib/features/profiel/beveiliging_screen.dart').readAsStringSync();
  final rowSource =
      File('lib/features/profiel/widgets/settings_action_row.dart')
          .readAsStringSync();

  test('beveiligingsheader en passwordkaart gebruiken auth-data', () {
    expect(source, contains("eyebrowText: 'APP-INSTELLINGEN'"));
    expect(source, contains("title: 'Beveiliging'"));
    expect(source, contains('StudentService.currentUser?.email'));
    expect(source, contains('maxLines: 2'));
    expect(source, isNot(contains('@gmail.com')));
    expect(source, contains('Wachtwoord herstellen'));
  });

  test('resetknop is compact en responsive', () {
    expect(source, contains('LayoutBuilder'));
    expect(source, contains('constraints.maxWidth * 0.62'));
    expect(source, contains('constraints.maxWidth >= 300'));
    expect(source, contains('OutlinedButton.icon'));
    expect(source, contains('minimumSize: const Size(0, 52)'));
    expect(source, contains('CircularProgressIndicator'));
  });

  test('resetkaart en resetrij gebruiken dezelfde resetmethode', () {
    expect(
      RegExp(r'StudentService\.stuurWachtwoordReset').allMatches(source),
      hasLength(1),
    );
    expect(
      source,
      contains('onTap: email == null || _resetLaden ? null : _stuurReset'),
    );
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
    expect(rowSource,
        contains('EdgeInsets.symmetric(horizontal: 18, vertical: 14)'));
    expect(rowSource, contains('chevron_right_rounded'));
  });
}
