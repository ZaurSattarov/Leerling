// Tests voor de gewijzigde sectievolgorde op Lesdetails: LESVOERTUIG staat
// nu vóór OPHAALLOCATIE (was andersom). Contactacties blijven daarvóór.
// Volgt hetzelfde bewezen patroon als ophaallocatie_kaart_test.dart /
// lesvoertuig_velden_test.dart: de kaarten zijn PRIVATE widgets in
// les_detail_screen.dart, dus getest via LesDetailScreen + Provider-
// overrides (zichtbaar gedrag) aangevuld met een brontekst-regressietest.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/features/planning/les_detail_screen.dart';
import 'package:leerling_app/features/planning/planning_provider.dart';
import 'package:leerling_app/models/les.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';

Les _bouwLes({
  String? locatie = 'Overtoom 283, Amsterdam',
  String? voertuigNaam = 'Toyota Aygo',
  String? voertuigMerk = 'Toyota',
  String? voertuigModel = 'Aygo',
  String? voertuigKenteken = '54-XT-RA',
  String? voertuigTransmissie = 'Automaat',
  String? voertuigCategorie = 'B',
}) {
  return Les(
    id: 'les-volgorde-1',
    instructeurId: 'instr-1',
    leerlingId: 'leerling-1',
    datum: '2026-08-20',
    starttijd: '10:00',
    eindtijd: '11:00',
    duurMinuten: 60,
    status: LesStatus.gepland,
    instructeurNaam: 'Jan Instructeur',
    instructeurTelefoon: '0612345678',
    locatie: locatie,
    voertuigNaam: voertuigNaam,
    voertuigMerk: voertuigMerk,
    voertuigModel: voertuigModel,
    voertuigKenteken: voertuigKenteken,
    voertuigTransmissie: voertuigTransmissie,
    voertuigCategorie: voertuigCategorie,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

Widget _bouwScherm(Les les) {
  return ProviderScope(
    overrides: [
      lesDetailProvider(les.id).overrideWith((ref) async => les),
      mijnProfielProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp(
      home: LesDetailScreen(id: les.id),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Lesdetails -- LESVOERTUIG vóór OPHAALLOCATIE', () {
    testWidgets(
        'wanneer beide aanwezig zijn staat LESVOERTUIG boven OPHAALLOCATIE',
        (tester) async {
      // Zeer hoog testviewport: de hele kaartenlijst past zonder scrollen,
      // zodat alle secties tegelijk gelayout zijn en hun Y-posities
      // rechtstreeks vergelijkbaar zijn (geen sliver-culling buiten beeld).
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_bouwScherm(_bouwLes()));
      await tester.pumpAndSettle();

      final voertuigTitel = find.text('LESVOERTUIG');
      final locatieTitel = find.text('OPHAALLOCATIE');
      expect(voertuigTitel, findsOneWidget);
      expect(locatieTitel, findsOneWidget);

      final voertuigY = tester.getTopLeft(voertuigTitel).dy;
      final locatieY = tester.getTopLeft(locatieTitel).dy;
      expect(voertuigY, lessThan(locatieY),
          reason: 'LESVOERTUIG moet vóór OPHAALLOCATIE staan');
    });

    testWidgets(
        'Contactacties (bellen/whatsapp) staan vóór zowel LESVOERTUIG als '
        'OPHAALLOCATIE', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_bouwScherm(_bouwLes()));
      await tester.pumpAndSettle();

      final bellenY = tester.getTopLeft(find.text('Bellen')).dy;
      final voertuigY = tester.getTopLeft(find.text('LESVOERTUIG')).dy;
      final locatieY = tester.getTopLeft(find.text('OPHAALLOCATIE')).dy;

      expect(bellenY, lessThan(voertuigY));
      expect(bellenY, lessThan(locatieY));
    });

    testWidgets(
        'alleen voertuig (geen locatie) blijft correct tonen, geen crash',
        (tester) async {
      final les = _bouwLes(locatie: '');
      await tester.pumpWidget(_bouwScherm(les));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('LESVOERTUIG'), findsOneWidget);
      expect(find.text('OPHAALLOCATIE'), findsNothing);
    });

    testWidgets(
        'alleen locatie (geen voertuig) blijft correct tonen, geen crash',
        (tester) async {
      final les = _bouwLes(
        voertuigNaam: '',
        voertuigMerk: '',
        voertuigModel: '',
        voertuigKenteken: '',
        voertuigTransmissie: '',
        voertuigCategorie: '',
      );
      await tester.pumpWidget(_bouwScherm(les));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('LESVOERTUIG'), findsNothing);
      expect(find.text('OPHAALLOCATIE'), findsOneWidget);
    });
  });

  group('les_detail_screen.dart -- brontekst bevestigt de volgorde', () {
    test('_VoertuigCard-blok staat vóór _LocatieCard-blok in de sliver-'
        'kinderenlijst', () {
      final bron =
          File('lib/features/planning/les_detail_screen.dart').readAsStringSync();
      final voertuigIndex = bron.indexOf('_VoertuigCard(les: les)');
      final locatieIndex = bron.indexOf('_LocatieCard(les: les)');
      expect(voertuigIndex, greaterThan(-1));
      expect(locatieIndex, greaterThan(-1));
      expect(voertuigIndex, lessThan(locatieIndex));
    });
  });
}
