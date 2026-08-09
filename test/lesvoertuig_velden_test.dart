// Regressietests voor de Impeccable-redesign van de voertuigweergave in
// Lesdetails (Planning -> LesDetailScreen):
// - voertuiggegevens staan nu op EXACT één plek (_VoertuigCard, sectietitel
//   "LESVOERTUIG"), niet langer ook samengevat in _LesInformatieCard;
// - kenteken/transmissie/categorie zijn losse label/waarde-rijen i.p.v. één
//   samengestelde "54-XT-RA - Automaat - Categorie B"-string;
// - Lestype is verplaatst naar _LesInformatieCard (was een eigen kaart);
// - ontbrekende velden worden individueel verborgen, nooit "null".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/features/planning/les_detail_screen.dart';
import 'package:leerling_app/features/planning/planning_provider.dart';
import 'package:leerling_app/features/profiel/rijschool_provider.dart';
import 'package:leerling_app/models/instructeur.dart';
import 'package:leerling_app/models/les.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';

Les _bouwLes({
  String id = 'les-voertuig-1',
  String? lesType,
  String? instructeurNaam,
  String? voertuigNaam,
  String? voertuigMerk,
  String? voertuigModel,
  String? voertuigKenteken,
  String? voertuigTransmissie,
  String? voertuigCategorie,
}) {
  return Les(
    id: id,
    instructeurId: 'instr-1',
    leerlingId: 'leerling-1',
    datum: '2026-08-07',
    starttijd: '20:00',
    eindtijd: '21:00',
    duurMinuten: 60,
    status: LesStatus.gepland,
    lesType: lesType,
    instructeurNaam: instructeurNaam,
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

Widget _bouwScherm(Les les, {String? rijschoolNaam}) {
  return ProviderScope(
    overrides: [
      lesDetailProvider(les.id).overrideWith((ref) async => les),
      mijnProfielProvider.overrideWith((ref) async => null),
      mijnInstructeurProvider.overrideWith((ref) async => rijschoolNaam == null
          ? null
          : Instructeur(id: 'instr-1', rijschoolNaam: rijschoolNaam)),
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

  group('Lesvoertuig -- volledige gegevens', () {
    testWidgets('voertuig, kenteken, transmissie en categorie staan elk '
        'afzonderlijk zichtbaar', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(
        voertuigMerk: 'BMW',
        voertuigModel: 'X5',
        voertuigKenteken: '54-XT-RA',
        voertuigTransmissie: 'automatic',
        voertuigCategorie: 'B',
      )));
      await tester.pumpAndSettle();

      expect(find.text('LESVOERTUIG'), findsOneWidget);
      expect(find.text('BMW X5'), findsOneWidget);
      expect(find.text('Kenteken'), findsOneWidget);
      expect(find.text('54-XT-RA'), findsOneWidget);
      expect(find.text('Transmissie'), findsOneWidget);
      expect(find.text('Automaat'), findsOneWidget);
      expect(find.text('Categorie'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets(
        'voertuig staat maar ÉÉN keer op het scherm -- geen dubbele '
        '"Lesvoertuig"/"LESVOERTUIG"-sectie meer in LESINFORMATIE',
        (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(
        voertuigMerk: 'BMW',
        voertuigModel: 'X5',
        voertuigKenteken: '54-XT-RA',
        voertuigTransmissie: 'automatic',
        voertuigCategorie: 'B',
      )));
      await tester.pumpAndSettle();

      expect(find.text('LESVOERTUIG'), findsOneWidget);
      expect(find.text('BMW X5'), findsOneWidget);
      expect(find.textContaining('Lesvoertuig'), findsNothing);
    });

    testWidgets('geen samengestelde string ("54-XT-RA · Automaat") meer '
        'ergens op het scherm', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(
        voertuigMerk: 'BMW',
        voertuigModel: 'X5',
        voertuigKenteken: '54-XT-RA',
        voertuigTransmissie: 'automatic',
        voertuigCategorie: 'B',
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('54-XT-RA ·'), findsNothing);
      expect(find.textContaining('Categorie B'), findsNothing);
    });
  });

  group('Lesvoertuig -- nette fallbacks bij ontbrekende velden', () {
    testWidgets('zonder kenteken: rij "Kenteken" wordt niet getoond, '
        'transmissie en categorie blijven zichtbaar', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(
        voertuigMerk: 'BMW',
        voertuigModel: 'X5',
        voertuigTransmissie: 'automatic',
        voertuigCategorie: 'B',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Kenteken'), findsNothing);
      expect(find.text('Transmissie'), findsOneWidget);
      expect(find.text('Categorie'), findsOneWidget);
    });

    testWidgets('zonder transmissie: rij "Transmissie" wordt niet getoond',
        (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(
        voertuigMerk: 'BMW',
        voertuigModel: 'X5',
        voertuigKenteken: '54-XT-RA',
        voertuigCategorie: 'B',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Transmissie'), findsNothing);
      expect(find.text('Kenteken'), findsOneWidget);
      expect(find.text('Categorie'), findsOneWidget);
    });

    testWidgets('zonder categorie: rij "Categorie" wordt niet getoond',
        (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(
        voertuigMerk: 'BMW',
        voertuigModel: 'X5',
        voertuigKenteken: '54-XT-RA',
        voertuigTransmissie: 'automatic',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Categorie'), findsNothing);
      expect(find.text('Kenteken'), findsOneWidget);
      expect(find.text('Transmissie'), findsOneWidget);
    });

    testWidgets('nergens het letterlijke woord "null" zichtbaar, ook niet '
        'bij een gedeeltelijk ingevuld voertuig', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes(
        voertuigMerk: 'BMW',
        voertuigModel: 'X5',
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('null', findRichText: true), findsNothing);
    });

    testWidgets(
        'helemaal geen voertuig gekoppeld: de hele LESVOERTUIG-kaart '
        'verbergt zich volledig', (tester) async {
      await tester.pumpWidget(_bouwScherm(_bouwLes()));
      await tester.pumpAndSettle();

      expect(find.text('LESVOERTUIG'), findsNothing);
      expect(find.text('Kenteken'), findsNothing);
      expect(find.text('Transmissie'), findsNothing);
      expect(find.text('Categorie'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Lesinformatie -- rijschool, instructeur en lestype', () {
    testWidgets('rijschool, instructeur en lestype staan zichtbaar in de '
        'LESINFORMATIE-kaart', (tester) async {
      await tester.pumpWidget(_bouwScherm(
        _bouwLes(lesType: 'Pakketles', instructeurNaam: 'Zaur Sattarov'),
        rijschoolNaam: 'Rijschool Klantio',
      ));
      await tester.pumpAndSettle();

      expect(find.text('LESINFORMATIE'), findsOneWidget);
      expect(find.text('Rijschool'), findsOneWidget);
      expect(find.text('Rijschool Klantio'), findsOneWidget);
      expect(find.text('Instructeur'), findsOneWidget);
      expect(find.text('Zaur Sattarov'), findsOneWidget);
      expect(find.text('Lestype'), findsOneWidget);
      expect(find.text('Pakketles'), findsOneWidget);
    });
  });

  group('Lesvoertuig -- responsive & tekstschaal', () {
    for (final breedte in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
          'geen overflow op ${breedte.toInt()}px met volledige voertuig- en '
          'lesinformatie', (tester) async {
        tester.view.physicalSize = Size(breedte, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_bouwScherm(
          _bouwLes(
            lesType: 'Pakketles',
            instructeurNaam:
                'Een Instructeur Met Een Best Wel Lange Volledige Naam',
            voertuigMerk: 'Volkswagen',
            voertuigModel: 'Touran Comfortline Automaat Lang Model',
            voertuigKenteken: '54-XT-RA',
            voertuigTransmissie: 'automatic',
            voertuigCategorie: 'B',
          ),
          rijschoolNaam:
              'Een Hele Lange Rijschoolnaam Uit Een Grote Nederlandse Stad',
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'overflow of exception op ${breedte.toInt()}px');
      });
    }

    testWidgets('geen overflow bij 130% tekstschaal', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 900),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _bouwScherm(
            _bouwLes(
              lesType: 'Pakketles',
              instructeurNaam: 'Zaur Sattarov',
              voertuigMerk: 'BMW',
              voertuigModel: 'X5',
              voertuigKenteken: '54-XT-RA',
              voertuigTransmissie: 'automatic',
              voertuigCategorie: 'B',
            ),
            rijschoolNaam: 'Rijschool Klantio',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
