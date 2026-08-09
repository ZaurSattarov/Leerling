// Hardening tegen de gemelde '!_debugLocked'-assertion (dubbele
// Navigator-operaties). Zie onderzoek: geen bevestigde reproductie
// gevonden voor een dubbele tik alleen (Navigator.push/pop ontgrendelt
// synchroon vóórdat een tweede aanroep start), maar
// beschikbaarheid_screen.dart had wél entry points die
// showModalBottomSheet/showDialog konden aanroepen zonder enige guard
// tegen een tweede aanroep terwijl de eerste nog open staat. Deze test
// bevestigt dat de toegevoegde guards dat structureel voorkomen -- zonder
// kunstmatige delay, puur via de bestaande open/laden-state.
//
// Sinds de Begin/Einde-samenvoeging bestaat het losse tijd-picker-sheet
// (en daarmee de _tijdSheetOpen-guard) niet meer -- Starttijd/Eindtijd zijn
// nu rechtstreeks bewerkbare velden in hetzelfde "Tijdblok toevoegen"-
// formulier, dus er is geen tweede modal meer om dubbel te openen.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BeschikbaarheidScreen -- geen dubbele Navigator-operaties', () {
    testWidgets(
        'dubbele/snelle tik op FAB "Tijd toevoegen" opent slechts één sheet '
        'en geeft geen enkele exception', (tester) async {
      await tester.pumpWidget(_bouwScherm());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Twee taps zonder pump ertussen -- simuleert een dubbele/snelle tik.
      await tester.tap(fab, warnIfMissed: false);
      await tester.tap(fab, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Slechts één sheet-instantie in de boom, geen gestapelde duplicaten.
      expect(find.text('Tijdblok toevoegen'), findsOneWidget);
      // Precies één modale route -- Begin/Einde zitten nu in datzelfde
      // sheet, er is geen tweede tijd-picker-modal meer om dubbel te openen.
      expect(find.byType(BottomSheet).evaluate().length, 1);
    });
  });

  group('beschikbaarheid_screen.dart -- guards aanwezig (bron-guard)', () {
    late String bron;
    setUpAll(() {
      bron = File('lib/features/beschikbaarheid/beschikbaarheid_screen.dart')
          .readAsStringSync();
    });

    test('_toonFormulier en _verwijder hebben elk een re-entrancy-guard, '
        'geen kunstmatige delay', () {
      expect(bron, contains('bool _formulierOpen = false;'));
      expect(bron, contains('bool _verwijderDialoogOpen = false;'));
      expect(bron, contains('if (_formulierOpen) return;'));
      expect(bron, contains('if (_verwijderDialoogOpen) return;'));
      expect(bron, isNot(contains('Future.delayed')));
    });

    test('los tijd-picker-sheet is verwijderd -- Begin/Einde zijn '
        'geïntegreerd in het formulier', () {
      expect(bron, isNot(contains('_KlantioTijdPickerSheet')));
      expect(bron, isNot(contains('_tijdSheetOpen')));
      expect(bron, isNot(contains("Text('Tijd gebruiken')")));
    });
  });
}
