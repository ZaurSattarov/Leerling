import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:leerling_app/features/profiel/account_deletion_exception.dart';
import 'package:leerling_app/features/profiel/account_deletion_flow.dart';
import 'package:leerling_app/shared/widgets/main_scaffold.dart';

Widget _routerHarness({
  required Widget Function(BuildContext context) home,
  GoRouter? router,
}) {
  final go = router ??
      GoRouter(
        initialLocation: '/app',
        routes: [
          GoRoute(
            path: '/app',
            builder: (context, _) => Scaffold(body: home(context)),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
        ],
      );
  return ProviderScope(child: MaterialApp.router(routerConfig: go));
}

void main() {
  test('VERWIJDER trim/case: alleen exacte bevestiging telt', () {
    expect(isLeerlingDeleteConfirmation('verwijder'), isTrue);
    expect(isLeerlingDeleteConfirmation('  VERWIJDER  '), isTrue);
    expect(isLeerlingDeleteConfirmation('verwijder!'), isFalse);
    expect(isLeerlingDeleteConfirmation('verwijderen'), isFalse);
    expect(isLeerlingDeleteConfirmation(''), isFalse);
  });

  test('client stuurt geen spoofbare leerling_id/user_id in delete-payload',
      () {
    final source =
        File('lib/core/services/student_service.dart').readAsStringSync();
    expect(source, contains('delete-leerling-account'));
    expect(source, contains('verwijderAccount'));
    final start = source.indexOf('static Future<void> verwijderAccount');
    final end = source.indexOf('static Future<void> stuurWachtwoordReset');
    final fn = source.substring(start, end);
    expect(fn, isNot(contains('leerling_id')));
    expect(fn, isNot(contains("'user_id'")));
    expect(fn, isNot(contains('"user_id"')));
  });

  test('uitloggen is idempotent bij lege sessie', () {
    final source =
        File('lib/core/services/student_service.dart').readAsStringSync();
    expect(
      source,
      contains('if (client.auth.currentSession == null) return;'),
    );
  });

  testWidgets('navbar-safe sheet houdt inhoud boven de navbar-footprint',
      (tester) async {
    late double inset;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showKlantioNavbarSafeSheet<void>(
                      context: context,
                      builder: (ctx, bottom) {
                        inset = bottom;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(24, 16, 24, bottom),
                          child: const Text('Account verwijderen'),
                        );
                      },
                    );
                  },
                  child: const Text('open-sheet'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();

    expect(inset, greaterThan(40));
    expect(find.text('Account verwijderen'), findsOneWidget);
  });

  testWidgets('foutieve bevestiging houdt CTA uit', (tester) async {
    await tester.pumpWidget(
      _routerHarness(
        home: (context) => TextButton(
          onPressed: () => AccountDeletionFlow.start(
            context,
            deleteAccount: () async {},
            signOut: () async {},
          ),
          child: const Text('open-delete'),
        ),
      ),
    );

    await tester.tap(find.text('open-delete'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('leerling_delete_confirm_field')),
      'nee',
    );
    await tester.pump();

    final deleteBtn = tester.widget<FilledButton>(
      find.byKey(const Key('leerling_delete_confirm_cta')),
    );
    expect(deleteBtn.onPressed, isNull);
  });

  testWidgets('correcte VERWIJDER maakt CTA actief', (tester) async {
    await tester.pumpWidget(
      _routerHarness(
        home: (context) => TextButton(
          onPressed: () => AccountDeletionFlow.start(
            context,
            deleteAccount: () async {},
            signOut: () async {},
          ),
          child: const Text('open-delete'),
        ),
      ),
    );

    await tester.tap(find.text('open-delete'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('leerling_delete_confirm_field')),
      '  verwijder  ',
    );
    await tester.pump();

    final deleteBtn = tester.widget<FilledButton>(
      find.byKey(const Key('leerling_delete_confirm_cta')),
    );
    expect(deleteBtn.onPressed, isNotNull);
  });

  testWidgets(
      'backendfout: geen signOut en geen navigatie, foutmelding zichtbaar',
      (tester) async {
    var signOutCount = 0;
    var deleteCount = 0;
    final router = GoRouter(
      initialLocation: '/app',
      routes: [
        GoRoute(
          path: '/app',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => AccountDeletionFlow.start(
                context,
                deleteAccount: () async {
                  deleteCount += 1;
                  throw AccountDeletionException('Server weigerde');
                },
                signOut: () async => signOutCount += 1,
              ),
              child: const Text('open-fail'),
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerHarness(home: (_) => const SizedBox(), router: router));

    await tester.tap(find.text('open-fail'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('leerling_delete_confirm_field')),
      'VERWIJDER',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('leerling_delete_confirm_cta')));
    await tester.pumpAndSettle();

    expect(deleteCount, 1);
    expect(signOutCount, 0);
    expect(find.text('login'), findsNothing);
    expect(find.text('Server weigerde'), findsWidgets);
    expect(find.text('Account verwijderen'), findsOneWidget);
  });

  testWidgets(
      'succes: signOut daarna exact één keer /login, geen tweede fout',
      (tester) async {
    final volgorde = <String>[];
    var signOutCount = 0;
    final router = GoRouter(
      initialLocation: '/app',
      routes: [
        GoRoute(
          path: '/app',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => AccountDeletionFlow.start(
                context,
                deleteAccount: () async => volgorde.add('delete'),
                signOut: () async {
                  signOutCount += 1;
                  volgorde.add('signOut');
                },
              ),
              child: const Text('open-ok'),
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerHarness(home: (_) => const SizedBox(), router: router));

    await tester.tap(find.text('open-ok'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('leerling_delete_confirm_field')),
      'VERWIJDER',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('leerling_delete_confirm_cta')));
    await tester.pumpAndSettle();

    expect(volgorde, ['delete', 'signOut']);
    expect(signOutCount, 1);
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('finishSuccessfulDeletion: signOut daarna exact één /login',
      (tester) async {
    final volgorde = <String>[];
    final router = GoRouter(
      initialLocation: '/app',
      routes: [
        GoRoute(
          path: '/app',
          builder: (_, __) => const Scaffold(body: Text('app')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('app'), findsOneWidget);

    await AccountDeletionFlow.finishSuccessfulDeletion(
      router: router,
      signOut: () async => volgorde.add('signOut'),
    );
    await tester.pumpAndSettle();

    expect(volgorde, ['signOut']);
    expect(find.text('login'), findsOneWidget);
  });
}
