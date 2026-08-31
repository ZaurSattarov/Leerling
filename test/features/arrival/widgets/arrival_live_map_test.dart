import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:leerling_app/features/arrival/widgets/arrival_live_map.dart';

void main() {
  group('ArrivalLiveMap', () {
    testWidgets('marker-positie komt exact uit latitude/longitude',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArrivalLiveMap(latitude: 52.123, longitude: 5.456),
        ),
      ));
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers.single.position, const LatLng(52.123, 5.456));
    });

    testWidgets('pickupPosition voegt een tweede, statische marker toe',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArrivalLiveMap(
            latitude: 52.1,
            longitude: 5.1,
            pickupPosition: LatLng(52.2, 5.2),
          ),
        ),
      ));
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers, hasLength(2));
      expect(
        map.markers.map((m) => m.markerId),
        containsAll(const [MarkerId('instructeur'), MarkerId('ophaallocatie')]),
      );
    });

    testWidgets('geen pickupPosition -> slechts 1 marker (huidige situatie: '
        'Les-model heeft geen ophaallocatie-coördinaten)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArrivalLiveMap(latitude: 52.1, longitude: 5.1),
        ),
      ));
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers, hasLength(1));
    });

    testWidgets('gesturesEnabled: false schakelt alle pan/zoom/rotate/tilt '
        'gestures uit (compacte preview-modus)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArrivalLiveMap(
            latitude: 52.1,
            longitude: 5.1,
            gesturesEnabled: false,
          ),
        ),
      ));
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.scrollGesturesEnabled, false);
      expect(map.zoomGesturesEnabled, false);
      expect(map.rotateGesturesEnabled, false);
      expect(map.tiltGesturesEnabled, false);
    });

    testWidgets('gesturesEnabled: true (default, fullscreen) laat gestures '
        'aan', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArrivalLiveMap(latitude: 52.1, longitude: 5.1),
        ),
      ));
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.scrollGesturesEnabled, true);
      expect(map.zoomGesturesEnabled, true);
    });

    testWidgets('nooit de eigen locatie van de leerling', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArrivalLiveMap(latitude: 52.1, longitude: 5.1),
        ),
      ));
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.myLocationEnabled, false);
      expect(map.myLocationButtonEnabled, false);
    });

    group('statische modus (geen live/primaire positie)', () {
      testWidgets(
          'geen latitude/longitude, wel pickupPosition -> uitsluitend de '
          'ophaallocatie-marker', (tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
            body: ArrivalLiveMap(pickupPosition: LatLng(52.3, 5.4)),
          ),
        ));
        await tester.pump();

        final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
        expect(map.markers, hasLength(1));
        expect(map.markers.single.markerId, const MarkerId('ophaallocatie'));
        expect(map.markers.single.position, const LatLng(52.3, 5.4));
      });

      testWidgets(
          'camera centreert op de pickup-positie als er geen primaire '
          'positie is', (tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
            body: ArrivalLiveMap(pickupPosition: LatLng(52.3, 5.4)),
          ),
        ));
        await tester.pump();

        final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
        expect(map.initialCameraPosition.target, const LatLng(52.3, 5.4));
      });

      testWidgets('geen enkele positie bekend -> geen marker, geen crash',
          (tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: ArrivalLiveMap()),
        ));
        await tester.pump();

        final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
        expect(map.markers, isEmpty);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets(
        'polylinePoints (voorbereiding route/ETA) -- ongebruikt blijft geen '
        'polyline tonen, met >=2 punten wel', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ArrivalLiveMap(latitude: 52.1, longitude: 5.1)),
      ));
      await tester.pump();
      expect(
          tester.widget<GoogleMap>(find.byType(GoogleMap)).polylines, isEmpty);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArrivalLiveMap(
            latitude: 52.1,
            longitude: 5.1,
            polylinePoints: [LatLng(52.1, 5.1), LatLng(52.2, 5.2)],
          ),
        ),
      ));
      await tester.pump();
      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.polylines, hasLength(1));
      expect(map.polylines.single.points,
          const [LatLng(52.1, 5.1), LatLng(52.2, 5.2)]);
    });
  });
}
