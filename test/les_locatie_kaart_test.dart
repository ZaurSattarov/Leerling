import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/services/les_kaart_service.dart';
import 'package:leerling_app/core/utils/les_kaart.dart';
import 'package:leerling_app/core/utils/maps_uri.dart';
import 'package:leerling_app/features/planning/widgets/les_locatie_kaart.dart';
import 'package:leerling_app/models/les.dart';

Les maakLes({Map<String, dynamic> extra = const {}}) => Les.fromJson({
      'id': 'les-1',
      'leerling_id': 'l',
      'instructeur_id': 'i',
      'datum': '2026-11-07',
      'starttijd': '10:00',
      'eindtijd': '11:00',
      'status': 'gepland',
      'locatie': 'Damrak 1, Amsterdam',
      ...extra,
    });

Future<void> toon(
  WidgetTester tester,
  Les les, {
  List<AdresTreffer> treffers = const [],
  bool metKaart = true,
  Brightness helderheid = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kaartBeschikbaarProvider.overrideWith((_) async => metKaart),
        lesKaartServiceProvider.overrideWithValue(
          LesKaartService(zoek: (_) async => treffers),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: helderheid),
        home: Scaffold(
          body: LesLocatieKaart(
            les: les,
            terugval: const Text('terugval'),
            kaartBouwer: metKaart ? (_, __) => const Text('kaart') : null,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('coördinaten buiten Nederland of onbruikbaar worden geweigerd', () {
    expect(lesCoordinaatGeldig(52.37, 4.89), isTrue);
    expect(lesCoordinaatGeldig(0, 0), isFalse);
    expect(lesCoordinaatGeldig(double.nan, 4.89), isFalse);
    expect(lesCoordinaatGeldig(null, 4.89), isFalse);
  });

  test('bewaard punt geldt alleen voor hetzelfde adres', () {
    LesKaartPunt? punt(String adres) => bewaardLesKaartPunt(
          adres: adres,
          lat: 52.37,
          lng: 4.89,
          coordAdres: 'Damrak 1, Amsterdam',
        );
    expect(punt(' damrak 1,  amsterdam'), isNotNull);
    expect(punt('Coolsingel 1, Rotterdam'), isNull);
  });

  test('navigatie gebruikt het adres zonder API-sleutel', () {
    final uri = MapsUri.navigatieUri(' Damrak 1 ');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], 'Damrak 1');
    expect(uri.queryParameters.containsKey('key'), isFalse);
  });

  for (final helderheid in Brightness.values) {
    testWidgets('bewaard punt toont de kaart in $helderheid', (tester) async {
      await toon(
        tester,
        maakLes(
          extra: {
            'ophaal_lat': 52.37,
            'ophaal_lng': 4.89,
            'ophaal_coord_adres': 'Damrak 1, Amsterdam',
          },
        ),
        helderheid: helderheid,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('kaart'), findsOneWidget);
      expect(find.text('Damrak 1, Amsterdam'), findsOneWidget);
    });
  }

  testWidgets('bestaande les zoekt het adres op de telefoon', (tester) async {
    await toon(tester, maakLes(), treffers: [(lat: 52.37, lng: 4.89, plaats: 'Amsterdam', postcode: null)]);
    expect(find.text('kaart'), findsOneWidget);
  });

  testWidgets('onbekend adres houdt de gewone card', (tester) async {
    await toon(tester, maakLes());
    expect(find.text('terugval'), findsOneWidget);
  });

  testWidgets('zonder Maps-sleutel blijft de gewone card', (tester) async {
    await toon(tester, maakLes(), metKaart: false);
    expect(tester.takeException(), isNull);
    expect(find.text('terugval'), findsOneWidget);
  });
}
