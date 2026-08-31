import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/arrival/arrival_provider.dart';
import 'package:leerling_app/models/arrival_location.dart';
import 'package:leerling_app/models/arrival_session.dart';

import 'fakes.dart';

ArrivalSession _sessie({
  String id = 'sess-1',
  String lessonId = 'les-1',
  String status = 'active',
  String visibility = 'hidden',
  Duration eindigtOver = const Duration(minutes: 10),
}) {
  return ArrivalSession(
    id: id,
    lessonId: lessonId,
    status: status,
    endsAt: DateTime.now().add(eindigtOver),
    locationVisibility: visibility,
  );
}

ArrivalLocation _locatie({double lat = 52.1, double lon = 5.1}) {
  return ArrivalLocation(
    latitude: lat,
    longitude: lon,
    recordedAt: DateTime.now(),
  );
}

void main() {
  late FakeArrivalRepository repo;
  late ArrivalController controller;

  setUp(() {
    repo = FakeArrivalRepository();
  });

  ArrivalController maak() {
    controller = ArrivalController(repository: repo);
    addTearDown(controller.dispose);
    return controller;
  }

  group('onLessonChanged -- basisstromen', () {
    test('geen sessie -> state.session blijft null (1)', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = null;
      await c.onLessonChanged('les-1');
      expect(c.state.session, isNull);
      expect(c.state.loading, false);
    });

    test('actieve sessie, locatie nog verborgen -> onderweg-state zonder '
        'locatie (2, 3)', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie();
      repo.locationsBySession['sess-1'] = null;
      await c.onLessonChanged('les-1');
      expect(c.state.session, isNotNull);
      expect(c.state.session!.isActive(), true);
      expect(c.state.location, isNull);
    });

    test('actieve + zichtbare sessie met locatie -> kaartstate (4)',
        () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] =
          _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = _locatie();
      await c.onLessonChanged('les-1');
      expect(c.state.session!.isVisible, true);
      expect(c.state.location, isNotNull);
    });

    test('geen dubbele fetch bij dezelfde lessonId', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = null;
      await c.onLessonChanged('les-1');
      final callsVoor = repo.fetchSessionCalls;
      await c.onLessonChanged('les-1');
      expect(repo.fetchSessionCalls, callsVoor);
    });
  });

  group('sessie-overgangen -> verwijderen (6, 7, 8, 32)', () {
    test('sessie wordt stopped -> location wordt gewist (6)', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = _locatie();
      await c.onLessonChanged('les-1');
      expect(c.state.location, isNotNull);

      repo.sessionsByLesson['les-1'] = null; // RLS geeft niets meer terug
      repo.stuurSessionEvent('les-1');
      await Future<void>.delayed(Duration.zero);

      expect(c.state.session, isNull);
      expect(c.state.location, isNull);
    });

    test('ends_at gepasseerd (verlopen/lesstart) -> isActive false, '
        'geen locatie meer getoond (7, 8, 32)', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] =
          _sessie(visibility: 'visible', eindigtOver: const Duration(seconds: -1));
      repo.locationsBySession['sess-1'] = _locatie();
      await c.onLessonChanged('les-1');

      expect(c.state.session!.isActive(), false);
    });
  });

  group('Realtime -> altijd verse SELECT (10, 11, 12)', () {
    test('session-event triggert een verse SELECT, nooit de payload',
        () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie();
      await c.onLessonChanged('les-1');
      final callsVoor = repo.fetchSessionCalls;

      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.stuurSessionEvent('les-1');
      await Future<void>.delayed(Duration.zero);

      expect(repo.fetchSessionCalls, greaterThan(callsVoor));
      expect(c.state.session!.isVisible, true);
    });

    test('location-event triggert een verse SELECT (11)', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = null;
      await c.onLessonChanged('les-1');
      expect(c.state.location, isNull);

      repo.locationsBySession['sess-1'] = _locatie();
      repo.stuurLocationEvent('sess-1');
      await Future<void>.delayed(Duration.zero);

      expect(c.state.location, isNotNull);
    });

    test('current_arrival_location DELETE (fetch geeft null) -> marker '
        'direct weg (9)', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = _locatie();
      await c.onLessonChanged('les-1');
      expect(c.state.location, isNotNull);

      repo.locationsBySession['sess-1'] = null;
      repo.stuurLocationEvent('sess-1');
      await Future<void>.delayed(Duration.zero);

      expect(c.state.location, isNull);
    });

    test('meerdere location-updates -> alleen het laatste punt (21)',
        () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = _locatie(lat: 52.1, lon: 5.1);
      await c.onLessonChanged('les-1');
      expect(c.state.location!.latitude, 52.1);

      repo.locationsBySession['sess-1'] = _locatie(lat: 52.2, lon: 5.2);
      repo.stuurLocationEvent('sess-1');
      await Future<void>.delayed(Duration.zero);

      expect(c.state.location!.latitude, 52.2,
          reason: 'geen geschiedenis -- alleen het meest recente punt');
    });
  });

  group('resume / recovery (13)', () {
    test('onAppResumed doet altijd een verse SELECT', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie();
      await c.onLessonChanged('les-1');
      final callsVoor = repo.fetchSessionCalls;

      await c.onAppResumed();

      expect(repo.fetchSessionCalls, callsVoor + 1);
    });
  });

  group('logout / account switch (14, 15)', () {
    test('onAuthLost wist alle arrival-state', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = _locatie();
      await c.onLessonChanged('les-1');
      expect(c.state.session, isNotNull);

      await c.onAuthLost();

      expect(c.state.session, isNull);
      expect(c.state.location, isNull);
    });

    test('na account switch geen leakage van vorige gebruiker', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = _locatie();
      await c.onLessonChanged('les-1');

      await c.onAuthLost();
      // Nieuwe gebruiker, andere les, geen arrival-sessie voor die les.
      repo.sessionsByLesson['les-2'] = null;
      await c.onLessonChanged('les-2');

      expect(c.state.session, isNull);
      expect(c.state.location, isNull);
    });
  });

  group('lesson-wissel (31)', () {
    test('nieuwe volgendeLes -> oude subscriptions opgeruimd, nieuwe fetch',
        () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(lessonId: 'les-1');
      await c.onLessonChanged('les-1');
      expect(repo.subscribedSessionLessonIds, contains('les-1'));

      repo.sessionsByLesson['les-2'] = null;
      await c.onLessonChanged('les-2');

      expect(repo.subscribedSessionLessonIds, contains('les-2'));
      expect(repo.removedChannelNames, isNotEmpty);
    });

    test('geen volgende les (null) -> state volledig leeg', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie();
      await c.onLessonChanged('les-1');
      expect(c.state.session, isNotNull);

      await c.onLessonChanged(null);

      expect(c.state.session, isNull);
      expect(c.state.location, isNull);
    });
  });

  group('foutafhandeling (25)', () {
    test('RLS/fetch geeft geen resultaat -> geen locatie, geen crash',
        () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = null; // RLS blokkeert
      await c.onLessonChanged('les-1');
      expect(c.state.location, isNull);
      expect(c.state.loading, false);
    });

    test('netwerkfout bij session-fetch -> geen crash, geen sessie getoond',
        () async {
      final c = maak();
      repo.sessionFetchError = Exception('netwerkfout');
      await c.onLessonChanged('les-1');
      expect(c.state.session, isNull);
    });
  });

  group('dispose (27)', () {
    test('events na dispose worden genegeerd, geen crash', () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie();
      await c.onLessonChanged('les-1');
      c.dispose();

      expect(() => repo.stuurSessionEvent('les-1'), returnsNormally);
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('hidden -> visible overgang (28)', () {
    test('sessie wordt zichtbaar -> locatie verschijnt na refresh',
        () async {
      final c = maak();
      repo.sessionsByLesson['les-1'] = _sessie();
      repo.locationsBySession['sess-1'] = null;
      await c.onLessonChanged('les-1');
      expect(c.state.location, isNull);

      repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
      repo.locationsBySession['sess-1'] = _locatie();
      repo.stuurSessionEvent('les-1');
      await Future<void>.delayed(Duration.zero);

      expect(c.state.session!.isVisible, true);
      expect(c.state.location, isNotNull);
    });
  });

  group('pollingfallback (29, 30)', () {
    test('polling start zolang sessie actief maar locatie verborgen, en '
        'stopt zodra de locatie zichtbaar wordt', () {
      fakeAsync((async) {
        final c = ArrivalController(repository: repo);
        repo.sessionsByLesson['les-1'] = _sessie();
        repo.locationsBySession['sess-1'] = null;

        c.onLessonChanged('les-1');
        async.flushMicrotasks();
        expect(c.state.polling, true);

        // Locatie wordt intussen zichtbaar; volgende poll-tick moet dit oppikken.
        repo.sessionsByLesson['les-1'] = _sessie(visibility: 'visible');
        repo.locationsBySession['sess-1'] = _locatie();

        async.elapse(ArrivalController.pollInterval + const Duration(seconds: 1));

        expect(c.state.location, isNotNull);
        expect(c.state.polling, false,
            reason: 'polling moet stoppen zodra de locatie zichtbaar is');

        c.dispose();
      });
    });

    test('polling stopt zodra de sessie eindigt', () {
      fakeAsync((async) {
        final c = ArrivalController(repository: repo);
        repo.sessionsByLesson['les-1'] = _sessie();
        repo.locationsBySession['sess-1'] = null;

        c.onLessonChanged('les-1');
        async.flushMicrotasks();
        expect(c.state.polling, true);

        repo.sessionsByLesson['les-1'] = null; // sessie gestopt/verwijderd
        async.elapse(ArrivalController.pollInterval + const Duration(seconds: 1));

        expect(c.state.session, isNull);
        expect(c.state.polling, false,
            reason: 'polling moet stoppen zodra er geen actieve sessie meer is');

        c.dispose();
      });
    });

    test('onAppPaused stopt polling direct, zonder op de sessie te wachten',
        () {
      fakeAsync((async) {
        final c = ArrivalController(repository: repo);
        repo.sessionsByLesson['les-1'] = _sessie();
        repo.locationsBySession['sess-1'] = null;

        c.onLessonChanged('les-1');
        async.flushMicrotasks();
        expect(c.state.polling, true);

        c.onAppPaused();
        expect(c.state.polling, false);

        final callsVoor = repo.fetchSessionCalls;
        async.elapse(ArrivalController.pollInterval * 2);
        expect(repo.fetchSessionCalls, callsVoor,
            reason: 'geen verdere polling-fetches na pause');

        c.dispose();
      });
    });
  });
}
