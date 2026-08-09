// Tests voor de samengevoegde "Tijdblok toevoegen"-flow: Begin/Einde zijn
// sinds deze wijziging rechtstreeks bewerkbare velden in ÉÉN formulier --
// geen los tweede tijd-picker-sheet meer. Volgt hetzelfde end-to-end
// pump-patroon als beschikbaarheid_navigator_guard_test.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/core/constants/app_colors.dart';
import 'package:leerling_app/features/beschikbaarheid/beschikbaarheid_screen.dart';
import 'package:leerling_app/models/leerling_profiel.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';

LeerlingProfiel _profiel() => const LeerlingProfiel(
      id: 'leerling-1',
      instructeurId: 'instr-1',
      voornaam: 'Lisa',
      achternaam: 'Jansen',
      pakket: PakketType.standaard,
      status: LeerlingStatus.actief,
      lessenTotaal: 20,
      lessenGevolgd: 13,
      aangemaaktOp: '2026-01-01T00:00:00Z',
      bijgewerktOp: '2026-01-01T00:00:00Z',
    );

Widget _bouwScherm() {
  return ProviderScope(
    overrides: [
      mijnProfielProvider.overrideWith((ref) async => _profiel()),
    ],
    child: const MaterialApp(home: BeschikbaarheidScreen()),
  );
}

/// Opent "Tijdblok toevoegen" (FAB). Standaardwaarden: Begin 09:00,
/// Einde 12:00 (zie _BeschikbaarheidFormulierState).
Future<void> _openFormulier(WidgetTester tester) async {
  await tester.pumpWidget(_bouwScherm());
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));

  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

/// Begin (index 0) en Einde (index 1) -- zelfde volgorde als de Row in de
/// build().
Finder _tijdVelden() => find.byType(TextField);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Tijdblok toevoegen -- één samengevoegd formulier', () {
    testWidgets('opent slechts één modal, Begin en Einde direct zichtbaar',
        (tester) async {
      await _openFormulier(tester);

      expect(find.text('Tijdblok toevoegen'), findsOneWidget);
      expect(find.byType(BottomSheet).evaluate().length, 1);
      expect(find.text('Begin'), findsOneWidget);
      expect(find.text('Einde'), findsOneWidget);
      expect(find.text('Snelle keuzes'), findsOneWidget);
      // Geen spoor meer van het oude tweede-sheet-scherm.
      expect(find.text('Tijd gebruiken'), findsNothing);
      expect(find.text('Tijd kiezen'), findsNothing);
    });

    testWidgets('Starttijd (Begin) kan handmatig getypt worden',
        (tester) async {
      await _openFormulier(tester);

      await tester.enterText(_tijdVelden().at(0), '10:15');
      await tester.pump();

      expect(tester.widget<TextField>(_tijdVelden().at(0)).controller!.text,
          '10:15');
    });

    testWidgets('Eindtijd (Einde) kan handmatig getypt worden',
        (tester) async {
      await _openFormulier(tester);

      await tester.enterText(_tijdVelden().at(1), '18:30');
      await tester.pump();

      expect(tester.widget<TextField>(_tijdVelden().at(1)).controller!.text,
          '18:30');
    });
  });

  group('Tijdblok toevoegen -- snelle keuzes contextueel', () {
    testWidgets('snelle keuze past Begin aan wanneer Begin actief is',
        (tester) async {
      await _openFormulier(tester);
      // Begin is standaard het actieve veld.

      await tester.tap(find.text('13:00'));
      await tester.pump();

      final velden = _tijdVelden();
      expect(tester.widget<TextField>(velden.at(0)).controller!.text,
          '13:00');
      expect(tester.widget<TextField>(velden.at(1)).controller!.text,
          '12:00');
    });

    testWidgets('snelle keuze past Einde aan wanneer Einde actief is',
        (tester) async {
      await _openFormulier(tester);

      // Tik in het Einde-veld -- FocusNode-listener maakt Einde actief.
      await tester.tap(_tijdVelden().at(1));
      await tester.pump();
      await tester.tap(find.text('17:00'));
      await tester.pump();

      final velden = _tijdVelden();
      expect(tester.widget<TextField>(velden.at(0)).controller!.text,
          '09:00');
      expect(tester.widget<TextField>(velden.at(1)).controller!.text,
          '17:00');
    });
  });

  group('Tijdblok toevoegen -- precies één doos per veld, geen pastel', () {
    testWidgets(
        'Begin en Einde hebben allebei precies één InputDecorator-doos '
        '(geen los omhullend Container-vlak eromheen)', (tester) async {
      await _openFormulier(tester);

      for (final label in ['Begin', 'Einde']) {
        // Directe ouder van het label + veld mag geen eigen gekleurde
        // BoxDecoration hebben -- de doos IS het TextField zelf.
        final kolom = find
            .ancestor(of: find.text(label), matching: find.byType(Column))
            .first;
        final containersErin =
            find.descendant(of: kolom, matching: find.byType(Container));
        for (final el in containersErin.evaluate()) {
          final container = el.widget as Container;
          final decoration = container.decoration;
          if (decoration is BoxDecoration) {
            expect(decoration.color, isNull,
                reason:
                    '$label: geen los Container-vlak met een eigen kleur '
                    'om het TextField heen (dubbele doos).');
          }
        }
      }
    });

    testWidgets(
        'beide velden gebruiken exact dezelfde witte vulling en dezelfde '
        'randradius', (tester) async {
      await _openFormulier(tester);

      final velden = _tijdVelden();
      for (final veld in [velden.at(0), velden.at(1)]) {
        final decoration = tester.widget<TextField>(veld).decoration!;
        expect(decoration.filled, isTrue);
        expect(decoration.fillColor, AppColors.white);
        expect(decoration.fillColor, isNot(AppColors.primaryLight));
        final enabledBorder = decoration.enabledBorder as OutlineInputBorder;
        expect(enabledBorder.borderRadius, BorderRadius.circular(14));
      }
    });

    testWidgets(
        'alleen de rand wordt AppColors.primary bij focus -- de vulling en '
        'tekstkleur veranderen niet', (tester) async {
      await _openFormulier(tester);

      final veld = tester.widget<TextField>(_tijdVelden().at(0));
      final decoration = veld.decoration!;
      final enabledBorder = decoration.enabledBorder as OutlineInputBorder;
      final focusedBorder = decoration.focusedBorder as OutlineInputBorder;

      expect(enabledBorder.borderSide.color, AppColors.border);
      expect(focusedBorder.borderSide.color, AppColors.primary);
      // Geen enkele randkleur is de pastel-tint.
      expect(enabledBorder.borderSide.color, isNot(AppColors.primaryLight));
      expect(focusedBorder.borderSide.color, isNot(AppColors.primaryLight));
    });

    testWidgets(
        'tijdtekst blijft altijd donker/leesbaar, ook op het net-aangeraakte '
        'veld (nooit wit-op-wit)', (tester) async {
      await _openFormulier(tester);

      // Begin is standaard het actieve veld (zie _actiefVeld default).
      await tester.tap(_tijdVelden().at(0));
      await tester.pump();

      for (final veld in [_tijdVelden().at(0), _tijdVelden().at(1)]) {
        final style = tester.widget<TextField>(veld).style!;
        expect(style.color, AppColors.textPrimary);
        expect(style.color, isNot(Colors.white));
      }
    });

    test('bronbestand gebruikt AppColors.primaryLight nergens als vulling',
        () {
      final bron =
          File('lib/features/beschikbaarheid/beschikbaarheid_screen.dart')
              .readAsStringSync();
      expect(bron, isNot(contains('color: AppColors.primaryLight')));
    });
  });

  group('Tijdblok toevoegen -- validatie zonder crash', () {
    testWidgets('gedeeltelijke invoer zoals "15:" veroorzaakt geen crash',
        (tester) async {
      await _openFormulier(tester);

      await tester.enterText(_tijdVelden().at(0), '15');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.widget<TextField>(_tijdVelden().at(0)).controller!.text,
          '15:');
    });

    testWidgets(
        'Opslaan met een onvolledig veld toont validatiefout, geen crash, '
        'en slaat niet op', (tester) async {
      await _openFormulier(tester);

      await tester.enterText(_tijdVelden().at(0), '15');
      await tester.pump(); // Begin toont nu "15:" -- niet volledig geldig.
      await tester.ensureVisible(find.text('Opslaan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opslaan'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Gebruik 24-uursnotatie, bijvoorbeeld 09:00.'),
          findsOneWidget);
    });

    testWidgets(
        'Opslaan met geldige Begin/Einde gebruikt de nieuwe waarden (geen '
        'validatiefout, alleen de verwachte netwerkfout in dit testmilieu)',
        (tester) async {
      await _openFormulier(tester);

      await tester.enterText(_tijdVelden().at(0), '0600');
      await tester.pump();
      await tester.enterText(_tijdVelden().at(1), '0800');
      await tester.pump();
      await tester.ensureVisible(find.text('Opslaan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opslaan'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Geen validatiefout -- de ingevoerde tijden zijn geldig en
      // Begin < Einde, dus de flow komt voorbij de eigen validatie door
      // naar de (in dit testmilieu zonder Supabase onvermijdelijke)
      // netwerkfoutafhandeling.
      expect(
          find.text('Gebruik 24-uursnotatie, bijvoorbeeld 09:00.'),
          findsNothing);
      expect(find.text('Starttijd moet vóór eindtijd zijn.'), findsNothing);
    });
  });

  group('Tijdblok toevoegen -- toetsenbord', () {
    testWidgets('zichtbaar toetsenbord (viewInsets) veroorzaakt geen '
        'layoutfout', (tester) async {
      await _openFormulier(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Opslaan blijft bereikbaar (formulier is scrollbaar).
      expect(find.text('Opslaan'), findsOneWidget);
    });
  });

  group('beschikbaarheid_screen.dart -- bestaande Supabase-save ongewijzigd',
      () {
    test('_opslaanFormulier gebruikt nog steeds dezelfde StudentService-'
        'aanroepen met dag/startTijd/eindTijd/voorkeurScore', () {
      final bron =
          File('lib/features/beschikbaarheid/beschikbaarheid_screen.dart')
              .readAsStringSync();
      expect(bron, contains('StudentService.updateBeschikbaarheid('));
      expect(bron, contains('StudentService.voegBeschikbaarheidToe('));
      expect(bron, contains('dagVanWeek: _dag,'));
      expect(bron, contains('voorkeurScore: _score,'));
      expect(bron, contains('_formatTijd(_startTijd)'));
      expect(bron, contains('_formatTijd(_eindTijd)'));
    });
  });
}
