import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/notificaties/leerling_email_preference_registry.dart';
import 'package:leerling_app/features/notificaties/notificatie_instellingen_provider.dart';
import 'package:leerling_app/features/notificaties/notificatie_instellingen_screen.dart';
import 'package:leerling_app/models/leerling_notificatie_voorkeuren.dart';
import 'package:leerling_app/shared/widgets/framer_toggle.dart';

class MemoryPreferences implements NotificatieVoorkeurenRepository {
  var value = const LeerlingNotificatieVoorkeuren(userId: 'leerling-a');
  Object? saveError;
  Completer<void>? pendingSave;
  int emailSaves = 0;
  bool? lastEnabled;
  Map<String, bool>? lastTopics;

  @override
  Future<LeerlingNotificatieVoorkeuren> laad() async => value;

  @override
  Future<LeerlingNotificatieVoorkeuren> slaOp(
    LeerlingNotificatieVoorkeuren next,
  ) async =>
      value = next;

  @override
  Future<LeerlingNotificatieVoorkeuren> slaEmailOp(
    LeerlingNotificatieVoorkeuren next, {
    bool? enabled,
    Map<String, bool>? topics,
  }) async {
    emailSaves++;
    lastEnabled = enabled;
    lastTopics = topics;
    await pendingSave?.future;
    if (saveError != null) throw saveError!;
    return value = next;
  }
}

void main() {
  test('oude rijen hebben alle e-mailvoorkeuren uit; push blijft behouden', () {
    final value = LeerlingNotificatieVoorkeuren.fromJson({'user_id': 'a'});
    expect(value.emailNotificaties, isFalse);
    expect(value.emailTopics, isEmpty);
    expect(value.nieuweLes, isTrue);
    for (final topic in leerlingEmailPreferenceToggles) {
      expect(value.emailTopicEnabled(topic.topicKey), isFalse);
    }
    expect(leerlingEmailPreferenceToggles.map((e) => e.topicKey).toSet(), {
      'L07',
      'L08',
      'L09',
      'L10',
      'L13',
      'L14',
      'L16',
      'L19',
      'L20',
      'L22',
      'L23',
      'L25',
      'L26',
    });
  });

  test('pushserialisatie bevat geen e-mailvelden of toestemmingsstempels', () {
    final value = LeerlingNotificatieVoorkeuren.fromJson({
      'user_id': 'a',
      'email_notificaties': true,
      'email_topics': {'L07': true, 'L11': true},
      'email_consent_since': '2026-10-25T12:00:00Z',
      'email_topic_since': {'L07': '2026-10-25T12:00:00Z'},
      'email_consent_version': 2,
    });
    expect(value.copyWith(nieuweLes: false).emailTopics,
        {'L07': true, 'L11': true});
    expect(
        value.toJson().keys.where((key) => key.startsWith('email_')), isEmpty);
    expect(value.copyWith(nieuweLes: false).emailNotificaties, isTrue);
  });

  test('ongeldige topicwaarden leveren geen impliciete toestemming op', () {
    final value = LeerlingNotificatieVoorkeuren.fromJson({
      'user_id': 'a',
      'email_topics': {'L07': 'true', 'L08': null, 'L09': true},
    });
    expect(value.emailTopicEnabled('L07'), isFalse);
    expect(value.emailTopicEnabled('L08'), isFalse);
    expect(value.emailTopicEnabled('L09'), isTrue);
    expect(() => value.emailTopics['L10'] = true, throwsUnsupportedError);
  });

  test('alle 13 onderwerpen bewaren afzonderlijk aan en uit na herladen',
      () async {
    final repo = MemoryPreferences();
    final container = ProviderContainer(overrides: [
      notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(notificatieInstellingenProvider, (_, __) {});
    addTearDown(sub.close);
    var value = await container.read(notificatieInstellingenProvider.future);
    final notifier = container.read(notificatieInstellingenProvider.notifier);
    await notifier.opslaanEmail(value.copyWith(emailNotificaties: true));
    expect(repo.lastEnabled, isTrue);
    expect(repo.lastTopics, isNull);
    expect(repo.value.emailTopics, isEmpty);
    for (final topic in leerlingEmailPreferenceToggles) {
      value = repo.value;
      await notifier.opslaanEmail(value.copyWith(emailTopics: {
        ...value.emailTopics,
        topic.topicKey: true,
      }));
      expect(repo.value.emailTopicEnabled(topic.topicKey), isTrue);
      expect(repo.lastEnabled, isNull);
      expect(repo.lastTopics, {topic.topicKey: true});
      expect(repo.value.nieuweLes, isTrue);
    }
    for (final topic in leerlingEmailPreferenceToggles) {
      value = repo.value;
      await notifier.opslaanEmail(value.copyWith(emailTopics: {
        ...value.emailTopics,
        topic.topicKey: false,
      }));
      container.invalidate(notificatieInstellingenProvider);
      final loaded =
          await container.read(notificatieInstellingenProvider.future);
      expect(loaded.emailTopicEnabled(topic.topicKey), isFalse);
    }
    final newSession = ProviderContainer(overrides: [
      notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(newSession.dispose);
    final loaded =
        await newSession.read(notificatieInstellingenProvider.future);
    expect(loaded.emailNotificaties, isTrue);
    expect(loaded.emailTopics.values, everyElement(isFalse));
  });

  test('globale opt-out bewaart onderwerpkeuzes en push', () async {
    final repo = MemoryPreferences()
      ..value = const LeerlingNotificatieVoorkeuren(
        userId: 'leerling-a',
        emailNotificaties: true,
        emailTopics: {'L07': true, 'L26': true},
        nieuweLes: false,
      );
    final container = ProviderContainer(overrides: [
      notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final value = await container.read(notificatieInstellingenProvider.future);
    await container
        .read(notificatieInstellingenProvider.notifier)
        .opslaanEmail(value.copyWith(emailNotificaties: false));
    expect(repo.value.emailNotificaties, isFalse);
    expect(repo.value.emailTopics, {'L07': true, 'L26': true});
    expect(repo.value.nieuweLes, isFalse);
  });

  testWidgets('alle groepen, Nederlandse labels en 13 zelfstandige schakelaars',
      (tester) async {
    final repo = MemoryPreferences();
    await tester.pumpWidget(screen(repo));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('email_meldingen')), 400);
    expect(find.text('E-MAILMELDINGEN'), findsOneWidget);
    await toggle(tester, 'toggle_email_notificaties');
    expect(repo.value.emailNotificaties, isTrue);
    expect(repo.value.emailTopics, isEmpty);
    for (final topic in leerlingEmailPreferenceToggles) {
      final row = find.byKey(Key('email_topic_${topic.topicKey}'));
      await tester.scrollUntilVisible(row, 180);
      expect(find.descendant(of: row, matching: find.text(topic.title)),
          findsOneWidget);
      expect(find.text(topic.topicKey), findsNothing);
      final control =
          find.descendant(of: row, matching: find.byType(FramerToggle));
      await Scrollable.ensureVisible(tester.element(control), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(repo.value.emailTopicEnabled(topic.topicKey), isTrue);
    }
    expect(repo.value.nieuweLes, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opslagfout herstelt schakelaar en geeft duidelijke fout',
      (tester) async {
    final repo = MemoryPreferences()..saveError = StateError('RPC ontbreekt');
    await tester.pumpWidget(screen(repo));
    await tester.pumpAndSettle();
    await toggle(tester, 'toggle_email_notificaties');
    expect(repo.value.emailNotificaties, isFalse);
    expect(find.text('E-mailvoorkeuren opslaan mislukt. Probeer het opnieuw.'),
        findsOneWidget);
    expect(
        tester
            .widget<FramerToggle>(find.descendant(
              of: find.byKey(const Key('toggle_email_notificaties')),
              matching: find.byType(FramerToggle),
            ))
            .value,
        isFalse);
  });

  testWidgets('tijdens opslag zijn wijzigingen geblokkeerd', (tester) async {
    final repo = MemoryPreferences()..pendingSave = Completer<void>();
    await tester.pumpWidget(screen(repo));
    await tester.pumpAndSettle();
    await toggle(tester, 'toggle_email_notificaties');
    expect(
        tester
            .widget<FramerToggle>(find.descendant(
              of: find.byKey(const Key('toggle_email_notificaties')),
              matching: find.byType(FramerToggle),
            ))
            .onChanged,
        isNull);
    repo.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(repo.emailSaves, 1);
  });

  testWidgets('mobiel 320px met 130 procent tekst heeft geen overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryPreferences();
    await tester.pumpWidget(screen(repo, scale: 1.3));
    await tester.pumpAndSettle();
    await toggle(tester, 'toggle_email_notificaties');
    for (final topic in leerlingEmailPreferenceToggles) {
      await tester.scrollUntilVisible(
          find.byKey(Key('email_topic_${topic.topicKey}')), 180);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget screen(MemoryPreferences repo, {double scale = 1}) => ProviderScope(
      overrides: [
        notificatieVoorkeurenRepositoryProvider.overrideWithValue(repo)
      ],
      child: MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: const NotificatieInstellingenScreen(),
      )),
    );

Future<void> toggle(WidgetTester tester, String key) async {
  final row = find.byKey(Key(key));
  await tester.scrollUntilVisible(row, 240);
  final control = find.descendant(of: row, matching: find.byType(FramerToggle));
  await Scrollable.ensureVisible(tester.element(control), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
}
