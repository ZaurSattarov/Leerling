import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../arrival_map_utils.dart';

/// Herbruikbare, interne Google Maps-weergave (Feature 2/4). Gebruikt zowel
/// voor de live instructeur/lesauto-positie (Live Aankomst) als voor de
/// statische ophaallocatie-weergave (geen route/ETA, dat is een latere,
/// aparte stap) -- ÉÉN gedeelde kaartimplementatie i.p.v. twee losse.
///
/// [latitude]/[longitude] zijn de PRIMAIRE (bewegende) marker -- `null`
/// zolang er geen live positie is. [pickupPosition] is de secundaire,
/// statische ophaallocatie-marker -- `null` zolang er geen coördinaten
/// bekend zijn (bv. adres nog niet gegeocodeerd, of leeg adres).
///
/// De aanroeper is de enige bron van waarheid over WANNEER deze widget
/// getoond wordt en met welke posities -- deze widget berekent of cachet
/// zelf nooit of een locatie nog geldig/zichtbaar is. Geef een nieuwe `key`
/// mee bij een betekenisvolle identiteitswissel (nieuwe sessie, andere les),
/// zodat nooit camera-/controllerstate van een vorige context blijft hangen.
class ArrivalLiveMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final double height;

  /// Ophaallocatie als losse, statische marker -- alleen getoond als
  /// coördinaten bekend zijn (bv. via geocoding van `Les.locatie`, zie
  /// `core/services/geocoding_service.dart`).
  final LatLng? pickupPosition;

  /// Voorbereid voor een latere routepolyline/ETA-uitbreiding -- vandaag
  /// altijd `null`/ongebruikt. Toegevoegd zodat die uitbreiding later geen
  /// wijziging aan de aanroepers van deze widget vereist, geen eigen
  /// route-logica hier.
  final List<LatLng>? polylinePoints;

  /// `false` voor een compacte kaart-preview die zelf getikt wordt om iets
  /// anders te openen (voorkomt pan/zoom-gestures die conflicteren met de
  /// tik) -- `true` voor de fullscreen-weergave.
  final bool gesturesEnabled;

  const ArrivalLiveMap({
    super.key,
    this.latitude,
    this.longitude,
    this.height = 160,
    this.pickupPosition,
    this.polylinePoints,
    this.gesturesEnabled = true,
  });

  @override
  State<ArrivalLiveMap> createState() => _ArrivalLiveMapState();
}

class _ArrivalLiveMapState extends State<ArrivalLiveMap> {
  // Zoom-niveau dat straatniveau-detail toont zonder te ver in te zoomen --
  // bruikbaar voor "waar is de lesauto/ophaallocatie" zonder een
  // navigatie-achtige close-up.
  static const double _zoom = 15.5;

  // Alleen gebruikt als er noch een primaire, noch een pickup-positie
  // bekend is (bv. adres leeg of geocoding nog niet klaar) -- puur om de
  // GoogleMap-widget een geldige `initialCameraPosition` te geven, nooit
  // getoond als een echte marker/locatie.
  static const LatLng _nederlandCentroid = LatLng(52.1, 5.3);

  GoogleMapController? _controller;
  LatLng? _laatsteCameraPositie;
  bool _mapCreated = false;
  bool _timedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // google_maps_flutter exposeert geen foutcallback voor een mislukte
    // platform-view-initialisatie (bv. ontbrekende/ongeldige key native-
    // side) -- alleen onMapCreated bij succes. Deze timeout is een best-
    // effort UX-signaal, GEEN bewezen foutdetectie: als onMapCreated te
    // lang uitblijft, tonen we een nette fallback i.p.v. oneindig te
    // wachten. Een al-geïnitialiseerde, native "grijze kaart" door een
    // ongeldige key wordt hier NIET gedetecteerd -- dat signaal bestaat
    // niet in de Dart-API van dit package.
    _timeoutTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_mapCreated) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ArrivalLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final primair = _primairePositie;
    if (primair != null) {
      // Live-modus: volg de bewegende primaire marker (bestaande >=25m-
      // recenterlogica), zelfde gedrag als voorheen.
      if (oldWidget.latitude != widget.latitude ||
          oldWidget.longitude != widget.longitude) {
        _verplaatsCameraIndienNodig(primair);
      }
      return;
    }
    // Geen primaire (live) positie: eenmalig centreren zodra de statische
    // ophaallocatie-marker alsnog binnenkomt (bv. geocoding rondt pas na de
    // eerste build af).
    if (widget.pickupPosition != null &&
        widget.pickupPosition != oldWidget.pickupPosition) {
      _verplaatsCameraIndienNodig(widget.pickupPosition!);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  LatLng? get _primairePositie {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng get _cameraFocus =>
      _primairePositie ?? widget.pickupPosition ?? _nederlandCentroid;

  void _verplaatsCameraIndienNodig(LatLng nieuw) {
    final controller = _controller;
    if (controller == null) return;
    if (!arrivalMapShouldRecenter(
        previous: _laatsteCameraPositie, next: nieuw)) {
      return;
    }
    _laatsteCameraPositie = nieuw;
    try {
      controller.animateCamera(CameraUpdate.newLatLng(nieuw));
    } catch (_) {
      // Controller kan al disposed zijn (widget snel weer weg) -- negeren,
      // geen crash. Geen bredere claim over native foutafhandeling hier.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) return const ArrivalLiveMapFallback();

    final markers = <Marker>{};
    final primair = _primairePositie;
    if (primair != null) {
      markers.add(arrivalMapMarkerFor(widget.latitude!, widget.longitude!));
    }
    final pickup = widget.pickupPosition;
    if (pickup != null) {
      markers.add(Marker(
        markerId: const MarkerId('ophaallocatie'),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
      ));
    }

    final punten = widget.polylinePoints;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition:
              CameraPosition(target: _cameraFocus, zoom: _zoom),
          markers: markers,
          polylines: {
            if (punten != null && punten.length >= 2)
              Polyline(
                polylineId: const PolylineId('route'),
                points: punten,
                color: AppColors.primary,
                width: 4,
              ),
          },
          // Uitsluitend de instructeur/lesauto-positie of de ophaallocatie --
          // nooit de eigen locatie van de leerling.
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          trafficEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          scrollGesturesEnabled: widget.gesturesEnabled,
          zoomGesturesEnabled: widget.gesturesEnabled,
          rotateGesturesEnabled: widget.gesturesEnabled,
          tiltGesturesEnabled: widget.gesturesEnabled,
          onMapCreated: (controller) {
            _timeoutTimer?.cancel();
            _controller = controller;
            _laatsteCameraPositie = _cameraFocus;
            _mapCreated = true;
          },
        ),
      ),
    );
  }
}

/// Nette fallback wanneer de kaart niet (tijdig) bruikbaar geïnitialiseerd
/// kon worden. Blokkeert nooit de rest van het scherm.
class ArrivalLiveMapFallback extends StatelessWidget {
  const ArrivalLiveMapFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.successBorder, width: 0.75),
      ),
      alignment: Alignment.center,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Live locatie tijdelijk niet beschikbaar',
          style: TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      ),
    );
  }
}
