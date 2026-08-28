import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/notificaties/notificatie_instellingen_provider.dart';
import 'package:leerling_app/features/notificaties/notificatie_instellingen_screen.dart';
import 'package:leerling_app/models/leerling_notificatie_voorkeuren.dart';

void main() {
  group('Notificatie-instellingen opslag', () {
    test('eerste opening maakt exact een voorkeurenrecord met defaults',
        () async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a');
      final container = ProviderContainer(
        overrides: [
          notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final voorkeuren =
          await container.read(notificatieInstellingenProvider.future);

      expect(repo.createdRecords, 1);
      expect(voorkeuren.nieuweLes, isTrue);
      expect(voorkeuren.lesVerplaatst, isTrue);
      expect(voorkeuren.examenadvies, isTrue);
    });

    test('herhaald openen maakt geen duplicaat', () async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a');
      final container = ProviderContainer(
        overrides: [
          notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificatieInstellingenProvider.future);
      container.invalidate(notificatieInstellingenProvider);
      await container.read(notificatieInstellingenProvider.future);

      expect(repo.createdRecords, 1);
    });

    test('toggle opslaan werkt en refresh behoudt waarden', () async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a');
      final container = ProviderContainer(
        overrides: [
          notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final eerste =
          await container.read(notificatieInstellingenProvider.future);
      await container
          .read(notificatieInstellingenProvider.notifier)
          .opslaan(eerste.copyWith(nieuweLes: false));

      container.invalidate(notificatieInstellingenProvider);
      final opnieuw =
          await container.read(notificatieInstellingenProvider.future);

      expect(repo.saveCalls, 1);
      expect(opnieuw.nieuweLes, isFalse);
    });

    test('mislukte update rolt UI-state terug', () async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a');
      final container = ProviderContainer(
        overrides: [
          notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final eerste =
          await container.read(notificatieInstellingenProvider.future);
      repo.failNextSave = true;

      await expectLater(
        container
            .read(notificatieInstellingenProvider.notifier)
            .opslaan(eerste.copyWith(nieuweLes: false)),
        throwsException,
      );

      final state = container.read(notificatieInstellingenProvider).valueOrNull;
      expect(state?.nieuweLes, isTrue);
    });

    test('andere leerling krijgt eigen voorkeuren', () async {
      final repoA = _FakeVoorkeurenRepository(userId: 'leerling-a');
      final repoB = _FakeVoorkeurenRepository(userId: 'leerling-b');
      final containerA = ProviderContainer(
        overrides: [
          notificatieVoorkeurenRepositoryProvider.overrideWithValue(repoA),
        ],
      );
      final containerB = ProviderContainer(
        overrides: [
          notificatieVoorkeurenRepositoryProvider.overrideWithValue(repoB),
        ],
      );
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      final a = await containerA.read(notificatieInstellingenProvider.future);
      await containerA
          .read(notificatieInstellingenProvider.notifier)
          .opslaan(a.copyWith(examenadvies: false));
      final b = await containerB.read(notificatieInstellingenProvider.future);

      expect(b.userId, 'leerling-b');
      expect(b.examenadvies, isTrue);
    });
  });

  group('Notificatie-instellingen scherm', () {
    testWidgets('loading-state werkt', (tester) async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a')
        ..loadCompleter = Completer<LeerlingNotificatieVoorkeuren>();

      await tester.pumpWidget(_screen(repo));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Notificaties'), findsOneWidget);
      expect(find.byKey(const Key('notificatie_instellingen_lijst')),
          findsNothing);
    });

    testWidgets('error-state werkt', (tester) async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a')
        ..failLoad = true;

      await tester.pumpWidget(_screen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Instellingen laden lukt niet'), findsOneWidget);
    });

    testWidgets('toggle opslaan werkt in de UI', (tester) async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a');

      await tester.pumpWidget(_screen(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byKey(const Key('toggle_nieuwe_les')),
        matching: find.byType(Switch),
      ));
      await tester.pumpAndSettle();

      expect(repo.record?.nieuweLes, isFalse);
    });

    testWidgets('altijd-actief items hebben geen toggle en geen marketing',
        (tester) async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a');

      await tester.pumpWidget(_screen(repo));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Bericht van je instructeur'),
        320,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Les geannuleerd'), findsOneWidget);
      expect(find.text('Les start binnenkort'), findsOneWidget);
      expect(find.text('Bericht van je instructeur'), findsOneWidget);
      expect(find.text('Altijd actief'), findsNWidgets(3));
      expect(
          find.text('Account- en beveiligingsmeldingen'), findsNothing);
      expect(find.text('Serviceberichten van Klantio'), findsNothing);
      expect(
          find.textContaining('marketing', findRichText: true), findsNothing);
    });

    testWidgets('tekstschaling geeft geen overflow', (tester) async {
      final repo = _FakeVoorkeurenRepository(userId: 'leerling-a');

      await tester.pumpWidget(_screen(
        repo,
        textScaleFactor: 1.3,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Profiel- en scope guards', () {
    test('App-instellingen groepeert machtigingen onder Profiel', () {
      final profile =
          File('lib/features/profiel/profiel_screen.dart').readAsStringSync();
      final settings = File('lib/features/profiel/app_instellingen_screen.dart')
          .readAsStringSync();
      final app = File('lib/app.dart').readAsStringSync();

      expect(profile, contains("label: 'Notificaties'"));
      expect(profile, contains("'/profiel/notificatie-instellingen'"));
      expect(profile, contains("label: 'App-instellingen'"));
      expect(profile, contains("'/profiel/app-instellingen'"));
      expect(profile, contains('Machtigingen en beveiliging'));
      expect(profile, isNot(contains("label: 'App-machtigingen'")));
      expect(profile, isNot(contains("label: 'Beveiliging'")));
      expect(settings, isNot(contains("label: 'Notificatie-instellingen'")));
      expect(settings, isNot(contains("'/profiel/notificatie-instellingen'")));
      expect(settings, contains("'/profiel/app-machtigingen'"));
      expect(settings, contains("'/profiel/beveiliging'"));
      expect(profile, contains("label: 'Privacy'"));
      expect(app, contains("path: '/profiel/app-machtigingen'"));
      expect(app, contains("path: '/profiel/beveiliging'"));
      expect(app, contains("path: '/profiel/app-instellingen'"));
      expect(app, contains("path: '/profiel/notificatie-instellingen'"));
    });

    test(
        'Privacy blijft los en instellingenkaart gebruikt gedeelde componenten',
        () {
      final source =
          File('lib/features/profiel/profiel_screen.dart').readAsStringSync();

      expect(source, isNot(contains("label: 'Wachtwoord'")));
      expect(source, contains('ProfielMenuCard'));
      expect(source, contains('ProfielMenuTile'));
      expect(source, contains("'/profiel/privacy'"));
    });

    test('switchstijl is centraal en claimt geen background push', () {
      final source =
          File('lib/features/notificaties/notificatie_instellingen_screen.dart')
              .readAsStringSync();

      expect(source, contains('SwitchTheme('));
      expect(source, contains('_notificationSwitchTheme'));
      expect(RegExp("Key\\('toggle_").allMatches(source), hasLength(12));
      expect(source, contains('class _LockedRow'));
      expect(source, contains('return AppColors.primary;'));
      expect(source, contains('return AppColors.white;'));
      expect(source, contains('return AppColors.border;'));
      expect(source, isNot(contains('background push')));
      expect(source, isNot(contains('geluid')));
      expect(source, isNot(contains('app gesloten')));
    });

    test('uitloggen wist lokale notificatievoorkeur-state', () {
      final source =
          File('lib/features/profiel/profiel_screen.dart').readAsStringSync();

      expect(
          source, contains('ref.invalidate(notificatieInstellingenProvider)'));
    });
  });
}

Widget _screen(
  _FakeVoorkeurenRepository repo, {
  double textScaleFactor = 1,
}) {
  return ProviderScope(
    overrides: [
      notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: const NotificatieInstellingenScreen(),
      ),
    ),
  );
}

class _FakeVoorkeurenRepository implements NotificatieVoorkeurenRepository {
  final String userId;
  LeerlingNotificatieVoorkeuren? record;
  int createdRecords = 0;
  int saveCalls = 0;
  bool failLoad = false;
  bool failNextSave = false;
  Completer<LeerlingNotificatieVoorkeuren>? loadCompleter;

  _FakeVoorkeurenRepository({required this.userId});

  @override
  Future<LeerlingNotificatieVoorkeuren> laad() async {
    if (failLoad) throw Exception('laden mislukt');
    final completer = loadCompleter;
    if (completer != null) return completer.future;
    record ??= _defaults();
    if (createdRecords == 0) createdRecords = 1;
    return record!;
  }

  @override
  Future<LeerlingNotificatieVoorkeuren> slaOp(
    LeerlingNotificatieVoorkeuren voorkeuren,
  ) async {
    if (failNextSave) {
      failNextSave = false;
      throw Exception('opslaan mislukt');
    }
    saveCalls++;
    record = voorkeuren;
    return record!;
  }

  LeerlingNotificatieVoorkeuren _defaults() {
    return LeerlingNotificatieVoorkeuren(userId: userId);
  }
}
