// Tests voor de altijd-aanwezige Live Aankomst-banner op Lesdetails
// (2026-09-03). Zelfde bewezen patroon als ophaallocatie_kaart_test.dart:
// LesDetailScreen + ProviderScope-overrides voor zichtbaar gedrag. De
// banner staat los van `les.locatie` (in tegenstelling tot de bestaande
// Ophaallocatiekaart) -- dat is hier expliciet gedekt.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:leerling_app/features/arrival/arrival_provider.dart';
import 'package:leerling_app/features/planning/les_detail_screen.dart';
import 'package:leerling_app/features/planning/planning_provider.dart';
import 'package:leerling_app/models/arrival_session.dart';
import 'package:leerling_app/models/arrival_settings_info.dart';
import 'package:leerling_app/models/les.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';

import 'features/arrival/fakes.dart';

Les _bouwLes({
  String? locatie = 'Amsterdam',
  required String datum,
  required String starttijd,
  LesStatus status = LesStatus.gepland,
  String id = 'les-banner-1',
}) {
  return Les(
    id: id,
    instructeurId: 'instr-1',
    leerlingId: 'leerling-1',
    datum: datum,
    starttijd: starttijd,
    eindtijd: '11:00',
    duurMinuten: 60,
    status: status,
    locatie: locatie,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

ArrivalSession _sessie({required String lessonId}) {
  return ArrivalSession(
    id: 'sess-1',
    lessonId: lessonId,
    status: 'active',
    endsAt: DateTime.now().add(const Duration(minutes: 30)),
    locationVisibility: 'hidden',
  );
}

Widget _bouwScherm(
  Les les, {
  required FakeArrivalRepository repo,
  ArrivalSettingsInfo? settings,
}) {
  return ProviderScope(
    overrides: [
      lesDetailProvider(les.id).overrideWith((ref) async => les),
      mijnProfielProvider.overrideWith((ref) async => null),
      arrivalRepositoryProvider.overrideWithValue(repo),
      if (settings != null)
        arrivalSettingsProvider(les.id).overrideWith((ref) async => settings),
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

  group('Live Aankomst-banner -- basisstromen', () {
    testWidgets('1+2. vóór het venster: correcte titel + dynamisch tijdstip',
        (tester) async {
      // Les om 14:00, ver in de toekomst (onafhankelijk van de werkelijke
      // testklok) -- 15 min venster, "nu" (de echte klok) ligt daar altijd
      // ver vóór.
      final les = _bouwLes(datum: '2030-01-01', starttijd: '14:00');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;

      await tester.pumpWidget(_bouwScherm(
        les,
        repo: repo,
        settings: const ArrivalSettingsInfo(
            eligible: true, visibleFromMinutes: 15),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live Aankomst'), findsOneWidget);
      expect(
        find.text(
            'De live locatie van je instructeur wordt zichtbaar vanaf 13:45.'),
        findsOneWidget,
      );
    });

    testWidgets('2. het tijdstip in de banner is dynamisch berekend uit de '
        'ingestelde instructeur-instelling, niet hardcoded', (tester) async {
      // Zelfde les, ANDER venster (20 i.p.v. 15) -> ander tijdstip.
      final les = _bouwLes(datum: '2030-01-01', starttijd: '14:00');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;

      await tester.pumpWidget(_bouwScherm(
        les,
        repo: repo,
        settings: const ArrivalSettingsInfo(
            eligible: true, visibleFromMinutes: 20),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'De live locatie van je instructeur wordt zichtbaar vanaf 13:40.'),
        findsOneWidget,
      );
    });

    testWidgets('3. vanaf het venster, nog niet gestart', (tester) async {
      final nu = DateTime.now();
      final lesStart = nu.add(const Duration(minutes: 5));
      final les = _bouwLes(
        datum:
            '${lesStart.year}-${lesStart.month.toString().padLeft(2, '0')}-${lesStart.day.toString().padLeft(2, '0')}',
        starttijd:
            '${lesStart.hour.toString().padLeft(2, '0')}:${lesStart.minute.toString().padLeft(2, '0')}',
      );
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;

      await tester.pumpWidget(_bouwScherm(
        les,
        repo: repo,
        settings: const ArrivalSettingsInfo(
            eligible: true, visibleFromMinutes: 10),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live Aankomst'), findsOneWidget);
      expect(
        find.text('Je instructeur kan vanaf nu zijn live locatie delen. '
            'Zodra hij onderweg is, zie je hem hier op de kaart.'),
        findsOneWidget,
      );
      // Nog geen kaart -- er is nog geen actieve sessie.
      expect(find.byType(GoogleMap), findsNothing);
    });

    testWidgets('5. actieve sessie -> "Live Aankomst actief"', (tester) async {
      final les = _bouwLes(datum: '2026-08-04', starttijd: '10:00');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = _sessie(lessonId: les.id);
      repo.locationsBySession['sess-1'] = null; // nog verborgen, mag geen probleem zijn

      await tester.pumpWidget(_bouwScherm(
        les,
        repo: repo,
        settings: const ArrivalSettingsInfo(
            eligible: true, visibleFromMinutes: 15),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live Aankomst actief'), findsOneWidget);
      expect(
        find.text('Je instructeur is onderweg. Je kunt zijn locatie '
            'hieronder live volgen.'),
        findsOneWidget,
      );
    });
  });

  group('Live Aankomst-banner -- 10/15/20 minuten', () {
    for (final minuten in [10, 15, 20]) {
      testWidgets('$minuten minuten venster: correct berekend tijdstip',
          (tester) async {
        final les = _bouwLes(datum: '2030-01-01', starttijd: '14:00');
        final repo = FakeArrivalRepository();
        repo.sessionsByLesson[les.id] = null;

        await tester.pumpWidget(_bouwScherm(
          les,
          repo: repo,
          settings: ArrivalSettingsInfo(
              eligible: true, visibleFromMinutes: minuten),
        ));
        await tester.pumpAndSettle();

        final verwacht = DateTime(2030, 1, 1, 14, 0)
            .subtract(Duration(minutes: minuten));
        final label =
            '${verwacht.hour.toString().padLeft(2, '0')}:${verwacht.minute.toString().padLeft(2, '0')}';
        expect(
          find.text(
              'De live locatie van je instructeur wordt zichtbaar vanaf $label.'),
          findsOneWidget,
        );
      });
    }
  });

  group('Live Aankomst-banner -- geen banner', () {
    testWidgets('niet eligible (instellingen uit / lestype niet toegestaan) '
        '-> geen banner, geen foutmelding', (tester) async {
      final les = _bouwLes(datum: '2026-09-03', starttijd: '14:00');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;

      await tester.pumpWidget(_bouwScherm(
        les,
        repo: repo,
        settings: ArrivalSettingsInfo.nietBeschikbaar,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live Aankomst'), findsNothing);
      expect(find.text('Live Aankomst actief'), findsNothing);
      expect(find.textContaining('Fout'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('geannuleerde les -> geen banner', (tester) async {
      final les = _bouwLes(
        datum: '2026-09-03',
        starttijd: '14:00',
        status: LesStatus.geannuleerd,
      );
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;

      await tester.pumpWidget(_bouwScherm(
        les,
        repo: repo,
        settings: const ArrivalSettingsInfo(
            eligible: true, visibleFromMinutes: 15),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live Aankomst'), findsNothing);
    });

    testWidgets('nog niet geladen (settings-fetch loading) -> geen banner, '
        'geen crash, geen lege sectie zichtbaar', (tester) async {
      final les = _bouwLes(datum: '2026-09-03', starttijd: '14:00');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;

      // Geen `settings`-override -> gebruikt de echte repo (fake), die
      // synchroon `nietBeschikbaar` teruggeeft zodra de future resolvet.
      // Vóór pumpAndSettle (dus nog "loading") mag er geen crash zijn.
      await tester.pumpWidget(_bouwScherm(les, repo: repo));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Live Aankomst-banner -- onafhankelijk van locatie', () {
    testWidgets('les zonder ingevulde locatie toont de banner alsnog '
        '(voorheen mountte de hele sectie niet zonder adres)', (tester) async {
      final les = _bouwLes(
          datum: '2030-01-01', starttijd: '14:00', locatie: null);
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;

      await tester.pumpWidget(_bouwScherm(
        les,
        repo: repo,
        settings: const ArrivalSettingsInfo(
            eligible: true, visibleFromMinutes: 15),
      ));
      await tester.pumpAndSettle();

      expect(find.text('OPHAALLOCATIE'), findsNothing);
      expect(find.text('Live Aankomst'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
