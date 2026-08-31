import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leerling_app/models/leerling_profiel.dart';
import 'package:leerling_app/core/services/student_service.dart';
import 'package:leerling_app/shared/providers/auth_provider.dart';
import 'package:leerling_app/shared/widgets/student_profile_gate.dart';

void main() {
  testWidgets('succesvolle koppeling gevolgd door timeout vraagt geen code',
      (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(
      router,
      mijnProfielProvider.overrideWith((ref) => Future.error(
            const ProfileLookupException(wasKnownCoupled: true),
          )),
    ));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.byKey(const Key('profile-gate-retry')), findsOneWidget);
    expect(find.text('Koppeling behouden'), findsOneWidget);
  });

  testWidgets('retry laadt profiel en laat app door', (tester) async {
    var attempts = 0;
    final router = _router();
    await tester.pumpWidget(_app(
      router,
      mijnProfielProvider.overrideWith((ref) async {
        attempts++;
        if (attempts == 1) {
          throw const ProfileLookupException(wasKnownCoupled: true);
        }
        return _profiel(compleet: true);
      }),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-gate-retry')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const Key('profile-gate-child')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('expliciet ontbrekend profiel gaat naar koppelcode',
      (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(
      router,
      mijnProfielProvider.overrideWith((ref) async => null),
    ));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/koppelcode');
  });

  testWidgets('incompleet profiel gaat naar profiel afronden', (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(
      router,
      mijnProfielProvider
          .overrideWith((ref) async => _profiel(compleet: false)),
    ));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/profiel-afronden',
    );
  });

  testWidgets('compleet profiel laat app door', (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(
      router,
      mijnProfielProvider.overrideWith((ref) async => _profiel(compleet: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-gate-child')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });
}

Widget _app(GoRouter router, Override override) {
  return ProviderScope(
    overrides: [override],
    child: MaterialApp.router(routerConfig: router),
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const StudentProfileGate(
          child: Scaffold(
            body: Text('App', key: Key('profile-gate-child')),
          ),
        ),
      ),
      GoRoute(
        path: '/koppelcode',
        builder: (_, __) => const Scaffold(body: Text('Koppelcode')),
      ),
      GoRoute(
        path: '/profiel-afronden',
        builder: (_, __) => const Scaffold(body: Text('Profiel afronden')),
      ),
    ],
  );
}

LeerlingProfiel _profiel({required bool compleet}) {
  return LeerlingProfiel.fromJson({
    'id': 'student-1',
    'instructeur_id': 'instructor-1',
    'voornaam': 'Sara',
    'achternaam': compleet ? 'Jansen' : '',
    'email': compleet ? 'sara@example.nl' : null,
    'geboortedatum': compleet ? '2001-04-12' : null,
    'avatar_id': compleet ? 'female_1' : null,
  });
}
