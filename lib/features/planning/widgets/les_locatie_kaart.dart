import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/services/les_kaart_service.dart';
import '../../../core/utils/les_kaart.dart';
import '../../../core/utils/maps_uri.dart';
import '../../../models/les.dart';

const double kLesKaartHoogte = 170;
const double _pinBreedte = 34;
const double _pinHoogte = 44;

const String _donkereKaartStijl = '''
[{"elementType":"geometry","stylers":[{"color":"#222936"}]},
{"elementType":"labels.text.fill","stylers":[{"color":"#AEB6C4"}]},
{"elementType":"labels.text.stroke","stylers":[{"color":"#222936"}]},
{"featureType":"road","elementType":"geometry","stylers":[{"color":"#3A4354"}]},
{"featureType":"water","elementType":"geometry","stylers":[{"color":"#141A24"}]},
{"featureType":"poi","stylers":[{"visibility":"off"}]}]
''';

/// Mag er een Google-kaart getekend worden? Op iOS crasht een kaart zonder
/// Maps-sleutel de hele app, dus vragen we het eerst aan de native kant.
final kaartBeschikbaarProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  if (Platform.isAndroid) return true;
  if (!Platform.isIOS) return false;
  try {
    return await const MethodChannel('klantio/kaart')
            .invokeMethod<bool>('isGeconfigureerd') ??
        false;
  } catch (_) {
    return false;
  }
});

final _pinMarkerProvider = FutureProvider<BitmapDescriptor>((ref) async {
  const schaal = 3.0;
  const r = _pinBreedte / 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(schaal);
  final pad = Path()
    ..moveTo(r, _pinHoogte)
    ..cubicTo(r * 0.72, _pinHoogte * 0.8, 0, _pinHoogte * 0.62, 0, r)
    ..arcToPoint(const Offset(_pinBreedte, r), radius: const Radius.circular(r))
    ..cubicTo(
      _pinBreedte,
      _pinHoogte * 0.62,
      r * 1.28,
      _pinHoogte * 0.8,
      r,
      _pinHoogte,
    )
    ..close();
  canvas.drawPath(pad, Paint()..color = AppColors.primary);
  canvas.drawCircle(
    const Offset(r, r),
    r * 0.38,
    Paint()..color = Colors.white,
  );
  final beeld = await recorder.endRecording().toImage(
        (_pinBreedte * schaal).round(),
        (_pinHoogte * schaal).round(),
      );
  final data = await beeld.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(
    data!.buffer.asUint8List(),
    width: _pinBreedte,
    height: _pinHoogte,
  );
});

/// Compacte kaart met het volledige ophaaladres. Tikken opent de navigatie in
/// Google Maps. Zonder kaart of plek blijft [terugval] staan.
class LesLocatieKaart extends ConsumerWidget {
  final Les les;
  final Widget terugval;

  /// Vervangt de Google-kaart in tests.
  final Widget Function(LesKaartPunt punt, bool donker)? kaartBouwer;

  const LesLocatieKaart({
    super.key,
    required this.les,
    required this.terugval,
    this.kaartBouwer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adres = les.locatie?.trim() ?? '';
    if (adres.isEmpty) return const SizedBox.shrink();

    final beschikbaar = kaartBouwer != null ||
        (ref.watch(kaartBeschikbaarProvider).valueOrNull ?? false);
    if (!beschikbaar) return terugval;

    final punt = ref
        .watch(
          lesKaartPuntProvider((
            adres: adres,
            lat: les.ophaalLat,
            lng: les.ophaalLng,
            coordAdres: les.ophaalCoordAdres,
          )),
        )
        .valueOrNull;
    if (punt == null) return terugval;

    final donker = Theme.of(context).brightness == Brightness.dark;
    final tekst = donker ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final sub = donker ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Semantics(
      button: true,
      label: 'Open navigatie naar $adres in Google Maps',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: donker ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: donker ? AppColors.darkBorder : AppColors.border,
            width: 0.75,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('les_kaart_navigatie'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => MapsUri.openNavigatie(context, adres),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: kLesKaartHoogte,
                      child: IgnorePointer(
                        child: kaartBouwer?.call(punt, donker) ??
                            _GoogleKaart(punt: punt, donker: donker),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ophaaladres',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tekst,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              adres,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                color: tekst,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(CoolIcons.navigation, size: 20, color: sub),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleKaart extends ConsumerWidget {
  final LesKaartPunt punt;
  final bool donker;

  const _GoogleKaart({required this.punt, required this.donker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plek = LatLng(punt.lat, punt.lng);
    final marker = ref.watch(_pinMarkerProvider).valueOrNull;
    return GoogleMap(
      key: ValueKey('${punt.lat},${punt.lng}'),
      initialCameraPosition: CameraPosition(target: plek, zoom: 15),
      style: donker ? _donkereKaartStijl : null,
      liteModeEnabled: Theme.of(context).platform == TargetPlatform.android,
      markers: {
        Marker(
          markerId: const MarkerId('ophaaladres'),
          position: plek,
          icon: marker ?? BitmapDescriptor.defaultMarker,
          consumeTapEvents: true,
        ),
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: false,
    );
  }
}
