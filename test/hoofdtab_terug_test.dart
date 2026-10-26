import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leerling_app/shared/widgets/main_scaffold.dart';

void main() {
  testWidgets('systeem-Back op Planning gaat naar Home', (tester) async {
    final router = GoRouter(
      initialLocation: '/planning',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const HoofdtabTerugScope(
            isHome: true,
            child: Text('Home'),
          ),
        ),
        GoRoute(
          path: '/planning',
          builder: (_, __) => const HoofdtabTerugScope(
            isHome: false,
            child: Text('Planning'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Planning'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
