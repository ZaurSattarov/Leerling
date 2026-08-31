import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:leerling_app/features/arrival/arrival_provider.dart';
import 'package:leerling_app/features/arrival/live_aankomst_fullscreen_screen.dart';
import 'package:leerling_app/models/arrival_location.dart';
import 'package:leerling_app/models/arrival_session.dart';
import 'package:leerling_app/models/les.dart';

import 'fakes.dart';

Les _bouwLes({String? locatie, String id = 'les-1'}) {
  return Les(
    id: id,
    instructeurId: 'instr-1',
    leerlingId: 'leerling-1',
    datum: '2026-08-04',
    starttijd: '10:00',
    eindtijd: '11:00',
    duurMinuten: 60,
    status: LesStatus.gepland,
    locatie: locatie,
    aangemaaktOp: '2026-01-01T00:00:00Z',
    bijgewerktOp: '2026-01-01T00:00:00Z',
  );
}

Future<ArrivalController> _bouwController(
  FakeArrivalRepository repo,
  Les les,
) async {
  final controller = ArrivalController(repository: repo);
  await controller.onLessonChanged(les.id);
  return controller;
}

/// Pusht de fullscreen-weergave op een echte Navigator-stack (zoals
/// `_LiveAankomstOphaalKaart` in de praktijk doet) zodat `Navigator.pop()`
/// -- incl. het automatische pop-gedrag van het scherm zelf -- iets heeft
/// om naar terug te gaan.
Widget _bouwMetNavigatorStack(ArrivalController controller, Les les) {
  return ProviderScope(
    overrides: [
      arrivalControllerProvider.overrideWith((ref) => controller),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LiveAankomstFullscreenScreen(les: les),
                ),
              ),
              child: const Text('open fullscreen'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('LiveAankomstFullscreenScreen', () {
    testWidgets('actieve sessie -> kaart + statuskaart + terugknop',
        (tester) async {
      final les = _bouwLes(locatie: 'Overtoom 283, Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = ArrivalSession(
        id: 'sess-1',
        lessonId: les.id,
        status: 'active',
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        locationVisibility: 'visible',
      );
      repo.locationsBySession['sess-1'] = ArrivalLocation(
        latitude: 52.1,
        longitude: 5.1,
        recordedAt: DateTime.now(),
      );
      final controller = await _bouwController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwMetNavigatorStack(controller, les));
      await tester.tap(find.text('open fullscreen'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveAankomstFullscreenScreen), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Instructeur onderweg'), findsOneWidget);
      expect(find.text('Overtoom 283, Amsterdam'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Geen technische termen/ETA in de zichtbare UI.
      expect(find.textContaining('ETA'), findsNothing);
      expect(find.textContaining('session_id'), findsNothing);
    });

    testWidgets('terugknop sluit het scherm', (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = ArrivalSession(
        id: 'sess-1',
        lessonId: les.id,
        status: 'active',
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        locationVisibility: 'visible',
      );
      repo.locationsBySession['sess-1'] = ArrivalLocation(
        latitude: 52.1,
        longitude: 5.1,
        recordedAt: DateTime.now(),
      );
      final controller = await _bouwController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwMetNavigatorStack(controller, les));
      await tester.tap(find.text('open fullscreen'));
      await tester.pumpAndSettle();
      expect(find.byType(LiveAankomstFullscreenScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(LiveAankomstFullscreenScreen), findsNothing);
      expect(find.text('open fullscreen'), findsOneWidget);
    });

    testWidgets(
        'sessie stopt terwijl fullscreen open is -> sluit zichzelf direct, '
        'nooit de laatste locatie als actueel laten staan', (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = ArrivalSession(
        id: 'sess-1',
        lessonId: les.id,
        status: 'active',
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        locationVisibility: 'visible',
      );
      repo.locationsBySession['sess-1'] = ArrivalLocation(
        latitude: 52.1,
        longitude: 5.1,
        recordedAt: DateTime.now(),
      );
      final controller = await _bouwController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwMetNavigatorStack(controller, les));
      await tester.tap(find.text('open fullscreen'));
      await tester.pumpAndSettle();
      expect(find.byType(LiveAankomstFullscreenScreen), findsOneWidget);

      repo.sessionsByLesson[les.id] = null; // instructeur heeft gestopt
      repo.stuurSessionEvent(les.id);
      await tester.pumpAndSettle();

      expect(find.byType(LiveAankomstFullscreenScreen), findsNothing,
          reason: 'scherm moet zichzelf sluiten zodra de sessie stopt');
      expect(find.text('open fullscreen'), findsOneWidget);
    });

    testWidgets(
        'geen actieve sessie -> statische ophaallocatie-weergave blijft '
        'open (nooit auto-pop), met "Route"-knop als secundaire actie',
        (tester) async {
      final les = _bouwLes(locatie: 'Amsterdam');
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;
      final controller = await _bouwController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwMetNavigatorStack(controller, les));
      await tester.tap(find.text('open fullscreen'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveAankomstFullscreenScreen), findsOneWidget,
          reason: 'nooit live geweest -> scherm mag niet zichzelf sluiten');
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Ophaallocatie'), findsOneWidget);
      expect(find.text('Amsterdam'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      // Secundaire externe-navigatie-actie is beschikbaar, maar apart van
      // de hoofdkaart/terugknop.
      expect(find.bySemanticsLabel('Route openen in Maps'), findsOneWidget);
    });

    testWidgets('geen adres -> geen "Route"-knop (niets om extern naar toe '
        'te navigeren)', (tester) async {
      final les = _bouwLes(locatie: null);
      final repo = FakeArrivalRepository();
      repo.sessionsByLesson[les.id] = null;
      final controller = await _bouwController(repo, les);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bouwMetNavigatorStack(controller, les));
      await tester.tap(find.text('open fullscreen'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveAankomstFullscreenScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Route openen in Maps'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
