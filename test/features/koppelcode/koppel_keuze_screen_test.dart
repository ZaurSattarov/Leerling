import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:leerling_app/features/koppelcode/koppel_keuze_screen.dart';

void main() {
  // We bouwen een minimale GoRouter met stubs voor /koppelcode/scan en
  // /koppelcode/handmatig zodat de tap-navigatie aantoonbaar naar de juiste
  // route gaat, zonder de echte QR-scanner-plugin (mobile_scanner) te
  // instantiëren -- dat vereist een platform-kanaal.
  Widget _buildApp() {
    final router = GoRouter(
      initialLocation: '/koppelcode',
      routes: [
        GoRoute(
          path: '/koppelcode',
          builder: (_, __) => const KoppelKeuzeScreen(),
        ),
        GoRoute(
          path: '/koppelcode/scan',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('SCANNER-STUB')),
          ),
        ),
        GoRoute(
          path: '/koppelcode/handmatig',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('HANDMATIG-STUB')),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('LOGIN-STUB')),
          ),
        ),
      ],
    );
    return ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets(
      'toont beide koppel-opties (QR-scan én koppelcode) na registratie',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Koppel je account'), findsOneWidget);
    expect(find.text('Scan QR-code'), findsOneWidget);
    expect(find.text('Koppelcode invoeren'), findsOneWidget);
    expect(find.text('of'), findsOneWidget);
    // QR is de aanbevolen optie
    expect(find.text('AANBEVOLEN'), findsOneWidget);
  });

  testWidgets('tap op "Scan QR-code" navigeert naar /koppelcode/scan',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan QR-code'));
    await tester.pumpAndSettle();

    expect(find.text('SCANNER-STUB'), findsOneWidget);
  });

  testWidgets(
      'tap op "Koppelcode invoeren" navigeert naar /koppelcode/handmatig -- '
      'de bestaande handmatige flow blijft volledig bereikbaar',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Koppelcode invoeren'));
    await tester.pumpAndSettle();

    expect(find.text('HANDMATIG-STUB'), findsOneWidget);
  });
}
