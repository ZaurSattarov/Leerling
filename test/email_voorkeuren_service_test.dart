import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leerling_app/core/services/student_service.dart';
import 'package:leerling_app/features/notificaties/leerling_email_preference_registry.dart';
import 'package:leerling_app/features/notificaties/notificatie_instellingen_provider.dart';
import 'package:leerling_app/models/leerling_notificatie_voorkeuren.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final backend = PreferencesBackend();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://preferences-test.invalid',
      anonKey: 'synthetic-test-key',
      httpClient: MockClient(backend.handle),
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    backend.reset();
    await login('leerling-a');
  });

  test(
      'globale RPC geeft uitsluitend p_enabled mee en neemt serverantwoord over',
      () async {
    backend.rows['leerling-a']!['email_topics'] = {'L07': true, 'L11': true};
    final previous = await StudentService.getMijnNotificatieVoorkeuren();
    final saved = await StudentService.slaMijnEmailVoorkeurenOp(
      previous.copyWith(emailNotificaties: true),
      enabled: true,
    );
    expect(backend.lastBody, {'p_enabled': true});
    expect(
        backend.lastPath, '/rest/v1/rpc/klantio_email_set_learner_preferences');
    expect(saved.emailTopics, {'L07': true, 'L11': true});
    expect(saved.emailNotificaties, isTrue);
    expect(saved.updatedAt, '2026-10-25T12:00:00Z');
    await StudentService.slaMijnEmailVoorkeurenOp(
      saved.copyWith(emailNotificaties: false),
      enabled: false,
    );
    expect(backend.lastBody, {'p_enabled': false});
    final loaded = await StudentService.getMijnNotificatieVoorkeuren();
    expect(loaded.emailTopics, {'L07': true, 'L11': true});
    expect(loaded.emailNotificaties, isFalse);
  });

  test('alle 13 losse RPC-patches aan/uit behouden overige onderwerpen en push',
      () async {
    backend.rows['leerling-a']!['email_topics'] = {'L11': true};
    for (final topic in leerlingEmailPreferenceToggles.where((topic) => ![
          'L11',
          'L12',
          'L21',
          'L24',
          'L35',
          'L30',
          'L31'
        ].contains(topic.topicKey))) {
      for (final enabled in [true, false]) {
        final previous = await StudentService.getMijnNotificatieVoorkeuren();
        final saved = await StudentService.slaMijnEmailVoorkeurenOp(
          previous,
          topics: {topic.topicKey: enabled},
        );
        expect(backend.lastBody, {
          'p_topics': {topic.topicKey: enabled}
        });
        expect(saved.emailTopicEnabled(topic.topicKey), enabled);
        expect(saved.emailTopicEnabled('L11'), isTrue);
        expect(saved.nieuweLes, isTrue);
        final loaded = await StudentService.getMijnNotificatieVoorkeuren();
        expect(loaded.emailTopicEnabled(topic.topicKey), enabled);
      }
    }
  });

  for (final key in ['L11', 'L12', 'L21', 'L24', 'L35', 'L30', 'L31']) {
    test('aanvullend $key eigen partiele RPC en afzonderlijk teruglezen',
        () async {
      backend.rows['leerling-a']!.addAll({
        'email_notificaties': true,
        'email_topics': {'L07': true, 'L26': true},
      });
      final container = ProviderContainer();
      final sub = container.listen(notificatieInstellingenProvider, (_, __) {});
      addTearDown(sub.close);
      addTearDown(container.dispose);
      for (final enabled in [true, false]) {
        final previous =
            await container.read(notificatieInstellingenProvider.future);
        await container
            .read(notificatieInstellingenProvider.notifier)
            .opslaanEmail(
              previous.copyWith(
                  emailTopics: {...previous.emailTopics, key: enabled}),
            );
        expect(backend.lastPath,
            '/rest/v1/rpc/klantio_email_set_learner_preferences');
        expect(backend.lastBody, {
          'p_topics': {key: enabled}
        });
        container.invalidate(notificatieInstellingenProvider);
        final loaded =
            await container.read(notificatieInstellingenProvider.future);
        expect(loaded.userId, 'leerling-a');
        expect(loaded.emailTopicEnabled(key), enabled);
        expect(loaded.emailTopicEnabled('L07'), isTrue);
        expect(loaded.emailTopicEnabled('L26'), isTrue);
        expect(loaded.emailNotificaties, isTrue);
        expect(loaded.nieuweLes, isTrue);
      }
    });
  }

  test('push-upsert schrijft geen e-mailvelden en bewaart servertoestemming',
      () async {
    backend.rows['leerling-a']!.addAll({
      'email_notificaties': true,
      'email_topics': {'L07': true},
      'email_consent_version': 2,
    });
    final previous = await StudentService.getMijnNotificatieVoorkeuren();
    final saved = await StudentService.slaMijnNotificatieVoorkeurenOp(
      previous.copyWith(nieuweLes: false),
    );
    expect(backend.lastBody.keys.where((key) => key.startsWith('email_')),
        isEmpty);
    expect(saved.emailNotificaties, isTrue);
    expect(saved.emailTopicEnabled('L07'), isTrue);
    expect(saved.nieuweLes, isFalse);
  });

  test('eerste laadactie maakt uitsluitend eigen pushdefaults aan', () async {
    backend.rows.clear();
    final loaded = await StudentService.getMijnNotificatieVoorkeuren();
    expect(loaded.userId, 'leerling-a');
    expect(loaded.emailNotificaties, isFalse);
    expect(loaded.emailTopics, isEmpty);
    expect(backend.lastBody['user_id'], 'leerling-a');
    expect(backend.lastBody.keys.where((key) => key.startsWith('email_')),
        isEmpty);
  });

  test('geen ingelogde leerling of ander userId kan geen verzoek versturen',
      () async {
    const other = LeerlingNotificatieVoorkeuren(userId: 'leerling-b');
    await expectLater(
        StudentService.slaMijnEmailVoorkeurenOp(other, enabled: true),
        throwsStateError);
    expect(backend.requests, isEmpty);
    await StudentService.client.auth.signOut(scope: SignOutScope.local);
    backend.requests.clear();
    await expectLater(
        StudentService.getMijnNotificatieVoorkeuren(), throwsStateError);
    await expectLater(
        StudentService.slaMijnEmailVoorkeurenOp(other, enabled: false),
        throwsStateError);
    expect(backend.requests, isEmpty);
  });

  for (final code in ['PGRST202', '42703', '42501', '22023']) {
    test('$code wordt doorgegeven zonder fallback-write of lokale opt-in',
        () async {
      final previous = await StudentService.getMijnNotificatieVoorkeuren();
      backend.errorCode = code;
      backend.requests.clear();
      await expectLater(
          StudentService.slaMijnEmailVoorkeurenOp(
            previous.copyWith(emailNotificaties: true),
            enabled: true,
          ),
          throwsA(isA<PostgrestException>()));
      expect(backend.requests, hasLength(1));
      expect(backend.rows['leerling-a']!['email_notificaties'], isFalse);
    });
  }

  test('accountwissel verwerpt een lopend antwoord van vorig account',
      () async {
    final previous = await StudentService.getMijnNotificatieVoorkeuren();
    backend.pending = Completer<void>();
    final request =
        StudentService.slaMijnEmailVoorkeurenOp(previous, enabled: true);
    final assertion = expectLater(request, throwsStateError);
    await backend.started.future;
    await login('leerling-b');
    backend.pending!.complete();
    await assertion;
  });

  test('provider herlaadt op logout/login en bewaart voorkeuren per leerling',
      () async {
    backend.rows['leerling-a']!['email_topics'] = {'L07': true};
    final container = ProviderContainer();
    final sub = container.listen(notificatieInstellingenProvider, (_, __) {});
    addTearDown(sub.close);
    addTearDown(container.dispose);
    var value = await container.read(notificatieInstellingenProvider.future);
    expect(value.userId, 'leerling-a');
    expect(value.emailTopicEnabled('L07'), isTrue);
    await StudentService.client.auth.signOut(scope: SignOutScope.local);
    await Future<void>.delayed(Duration.zero);
    await expectLater(container.read(notificatieInstellingenProvider.future),
        throwsStateError);
    await login('leerling-b');
    await Future<void>.delayed(Duration.zero);
    value = await container.read(notificatieInstellingenProvider.future);
    expect(value.userId, 'leerling-b');
    expect(value.emailTopicEnabled('L07'), isFalse);
    await login('leerling-a');
    await Future<void>.delayed(Duration.zero);
    value = await container.read(notificatieInstellingenProvider.future);
    expect(value.userId, 'leerling-a');
    expect(value.emailTopicEnabled('L07'), isTrue);
  });

  test('provider negeert late opslag na accountwissel', () async {
    final container = ProviderContainer();
    final sub = container.listen(notificatieInstellingenProvider, (_, __) {});
    addTearDown(sub.close);
    addTearDown(container.dispose);
    final value = await container.read(notificatieInstellingenProvider.future);
    backend.pending = Completer<void>();
    final save = container
        .read(notificatieInstellingenProvider.notifier)
        .opslaanEmail(value.copyWith(emailNotificaties: true));
    final assertion = expectLater(save, throwsStateError);
    await backend.started.future;
    await login('leerling-b');
    await Future<void>.delayed(Duration.zero);
    await container.read(notificatieInstellingenProvider.future);
    backend.pending!.complete();
    await assertion;
    expect(container.read(notificatieInstellingenProvider).requireValue.userId,
        'leerling-b');
    expect(
        container
            .read(notificatieInstellingenProvider)
            .requireValue
            .emailNotificaties,
        isFalse);
  });
}

Future<void> login(String userId) =>
    StudentService.client.auth.recoverSession(jsonEncode({
      'access_token': 'synthetic-local-session',
      'refresh_token': 'synthetic-local-refresh',
      'token_type': 'bearer',
      'user': {
        'id': userId,
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-10-25T00:00:00Z',
      },
    }));

/// Wire-level fixture: no network, no real account and no assertion of real RLS.
class PreferencesBackend {
  final rows = <String, Map<String, dynamic>>{};
  final requests = <http.Request>[];
  Map<String, dynamic> lastBody = {};
  String? lastPath;
  String? errorCode;
  Completer<void>? pending;
  Completer<void> started = Completer<void>();

  void reset() {
    rows.clear();
    for (final id in ['leerling-a', 'leerling-b']) {
      rows[id] = {
        'user_id': id,
        'nieuwe_les': true,
        'email_notificaties': false,
        'email_topics': <String, bool>{}
      };
    }
    requests.clear();
    errorCode = null;
    pending = null;
    started = Completer<void>();
    lastBody = {};
  }

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    lastPath = request.url.path;
    lastBody = request.body.isEmpty
        ? {}
        : jsonDecode(request.body) as Map<String, dynamic>;
    final userId = StudentService.currentUser?.id;
    final body = lastBody;
    if (request.url.path.startsWith('/auth/')) return http.Response('{}', 200);
    if (request.url.path.contains('/rpc/')) {
      if (!started.isCompleted) started.complete();
      await pending?.future;
      if (errorCode != null) {
        return response(request,
            {'code': errorCode, 'message': 'Synthetic RPC failure'}, 400);
      }
      final row = rows[userId]!;
      if (body.containsKey('p_enabled')) {
        row['email_notificaties'] = body['p_enabled'];
      }
      if (body['p_topics'] != null) {
        row['email_topics'] = {
          ...row['email_topics'] as Map,
          ...body['p_topics'] as Map,
        };
      }
      row['updated_at'] = '2026-10-25T12:00:00Z';
      return response(request, row);
    }
    final id =
        request.url.queryParameters['user_id']?.replaceFirst('eq.', '') ??
            lastBody['user_id'] as String?;
    if (request.method == 'GET') {
      return response(request, rows[id] == null ? [] : [rows[id]]);
    }
    final row = rows.putIfAbsent(id!, () => {'user_id': id});
    row.addAll(lastBody);
    return response(request, [row]);
  }

  http.Response response(http.Request request, Object body,
          [int status = 200]) =>
      http.Response(
        jsonEncode(body is List &&
                request.headers['Accept'] == 'application/vnd.pgrst.object+json'
            ? body.single
            : body),
        status,
        request: request,
        headers: {'content-type': 'application/json'},
      );
}
