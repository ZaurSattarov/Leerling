import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/core/utils/app_error_formatter.dart';
import 'package:leerling_app/features/facturen/facturen_provider.dart';
import 'package:leerling_app/features/facturen/facturen_screen.dart';
import 'package:leerling_app/features/notificaties/notificaties_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const ruweFout = 'ClientException with SocketException: Failed host lookup: '
      'voorbeeld.invalid uri=https://voorbeeld.invalid/rest/v1/facturen'
      '?select=*&leerling_id=eq.123e4567-e89b-12d3-a456-426614174000';

  test('ruwe netwerkfout lekt geen host, url of id', () {
    final tekst = AppErrorFormatter.toFriendlyDutch(
      Exception(ruweFout),
      fallback: 'Geen verbinding. Facturen kunnen nu niet worden geladen.',
      contextMessage: 'Facturen laden',
    );
    expect(tekst, 'Geen verbinding. Facturen kunnen nu niet worden geladen.');
    expect(tekst, isNot(contains('voorbeeld.invalid')));
    expect(tekst, isNot(contains('rest/v1')));
    expect(tekst, isNot(contains('leerling_id')));
    expect(tekst, isNot(contains('123e4567')));
  });

  test('bekende servercodes krijgen een eigen Nederlandse zin', () {
    expect(
      AppErrorFormatter.toFriendlyDutch(Exception('geen_actief_schoollid')),
      'Je rijschool kan op dit moment niet gekoppeld worden. Neem contact op met je rijinstructeur.',
    );
    expect(
      AppErrorFormatter.toFriendlyDutch(Exception('mfa_required')),
      contains('extra beveiliging'),
    );
  });

  test('eigen Nederlandse fout blijft leesbaar', () {
    expect(
      AppErrorFormatter.toFriendlyDutch(
        Exception('Deze koppelcode is ongeldig.'),
      ),
      'Deze koppelcode is ongeldig.',
    );
  });

  testWidgets('Facturen offline toont een nette melding en Opnieuw proberen',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        facturenProvider.overrideWith((ref) async => throw Exception(ruweFout)),
        ongelezenNotificatiesProvider.overrideWith((ref) async => 0),
      ],
      child: const MaterialApp(home: FacturenScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Kon facturen niet laden'), findsOneWidget);
    expect(
      find.text('Geen verbinding. Facturen kunnen nu niet worden geladen.'),
      findsOneWidget,
    );
    expect(find.text('Opnieuw proberen'), findsOneWidget);
    expect(find.textContaining('voorbeeld.invalid'), findsNothing);
    expect(find.textContaining('leerling_id'), findsNothing);
    expect(find.textContaining('rest/v1'), findsNothing);
  });
}
