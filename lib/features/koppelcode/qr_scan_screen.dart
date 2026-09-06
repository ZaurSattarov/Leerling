import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import 'koppel_flow.dart';

/// Full-screen QR-scanner voor de koppel-flow.
///
/// Leest de QR-code die de Instructeur-app genereert in
/// `snelle_leerling_screen.dart` (via `qr_flutter`) -- de payload is
/// exact de 8-tekens KOPPELCODE (zie `quick_student_flow.dart`
/// StudentCouplingShareData.qrPayload => code). Deze scanner
/// normaliseert die string via [KoppelFlow.normalizeCode] en voedt hem
/// aan dezelfde canonical RPC (`koppel_leerling_met_code`) via
/// [KoppelFlow.koppelEnNavigeer] die de handmatige koppelcode-invoer
/// ook gebruikt. Er is geen tweede koppelmechanisme.
///
/// UI ontwerp (op verzoek 1-op-1 met de meegestuurde referentiescreen-
/// afbeelding, kleuren vervangen door Klantio-primary
/// `AppColors.primary`):
///   * donkere/zwarte cameraweergave, portrait-only
///   * vierkant scan-venster gecentreerd, ~70% breedte
///   * gele L-vormige corner brackets op de vier hoeken
///   * animerende horizontale scanline die op- en neer beweegt tussen
///     de top- en bottombracket (2s, easeInOut, oneindig reverse)
///   * top-right torch/flash toggle
///   * boven-links terugpijl (afspringen naar de keuze-pagina)
///   * korte instructie onder het scan-venster
///
/// Life-cycle: `MobileScannerController` wordt aangemaakt in initState
/// en gedisposeer d in dispose zodat de camera netjes stopt bij
/// pop/verlaten. Bij succesvolle scan pauzeert de controller direct om
/// dubbele detectie te voorkomen.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    // We hebben alleen QR nodig -- 1D-formaten uitsluiten scheelt CPU en
    // voorkomt dat een streepjescode per ongeluk als koppelcode wordt
    // opgevat.
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );
  late final AnimationController _scanAnim;

  bool _bezig = false;
  String? _fout;
  bool _flashAan = false;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_bezig) return; // dubbele detectie voorkomen
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final ruw = barcodes.first.rawValue;
    if (ruw == null || ruw.isEmpty) return;

    // Zet de scanner direct op pauze zodat er tijdens de RPC-call geen
    // tweede detectie binnenkomt en zodat de camera zichtbaar tot rust
    // komt.
    setState(() {
      _bezig = true;
      _fout = null;
    });
    await _controller.stop();
    unawaited(HapticFeedback.selectionClick());
    if (!mounted) return;

    try {
      await KoppelFlow.koppelEnNavigeer(
        context: context,
        ref: ref,
        ruweCode: ruw,
      );
      // Bij succes navigeert de flow zelf naar /home of /profiel-afronden;
      // deze widget wordt dan gepopt en dispose stopt de camera al.
    } on KoppelException catch (e) {
      if (!mounted) return;
      setState(() {
        _fout = e.boodschap;
        _bezig = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fout = e.toString().replaceFirst('Exception: ', '');
        _bezig = false;
      });
    }
  }

  Future<void> _herstart() async {
    setState(() {
      _fout = null;
      _bezig = false;
    });
    try {
      await _controller.start();
    } catch (_) {
      // start() gooit als de camera al draait -- veilig te negeren.
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await _controller.toggleTorch();
      if (!mounted) return;
      setState(() => _flashAan = !_flashAan);
    } catch (_) {
      // Toestel zonder flash -- stille no-op.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Camera-preview + dubbeldetectie-filter
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, _) => _CameraFoutView(
                fout: error,
                onOpnieuw: _herstart,
              ),
            ),

            // Semi-transparant donker masker met een uitgesneden scan-
            // venster in het midden.
            const _ScanMasker(),

            // Scan-venster: brackets + animerende scanline
            Center(
              child: _ScanVenster(scanAnim: _scanAnim),
            ),

            // Top-bar: terug + flash-toggle (visueel dicht bij de
            // referentiescreen-afbeelding).
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _RondeIconKnop(
                      icoon: Icons.arrow_back_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/koppelcode');
                        }
                      },
                    ),
                    const Spacer(),
                    _RondeIconKnop(
                      icoon: _flashAan
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),

            // Onderaan: uitleg + evt. foutmelding / loading + link
            // terug naar handmatige koppelcode.
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_fout != null) ...[
                        _FoutBalk(
                          boodschap: _fout!,
                          onOpnieuw: _herstart,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Richt op de QR-code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Houd de camera stil boven de QR-code die je van je '
                        'rijinstructeur hebt gekregen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (_bezig) ...[
                        const SizedBox(height: 16),
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () =>
                            context.go('/koppelcode/handmatig'),
                        icon: const Icon(Icons.keyboard_rounded,
                            color: Colors.white70, size: 18),
                        label: const Text(
                          'Liever koppelcode intypen',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ScanMasker extends StatelessWidget {
  const _ScanMasker();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final grootte = _venstergrootte(constraints);
          return CustomPaint(
            painter: _ScanMaskerPainter(vensterGrootte: grootte),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          );
        },
      ),
    );
  }
}

class _ScanMaskerPainter extends CustomPainter {
  const _ScanMaskerPainter({required this.vensterGrootte});
  final double vensterGrootte;

  @override
  void paint(Canvas canvas, Size size) {
    final maskerVerf = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final venster = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: vensterGrootte,
      height: vensterGrootte,
    );

    final buiten = Path()..addRect(Offset.zero & size);
    final gat = Path()
      ..addRRect(
          RRect.fromRectAndRadius(venster, const Radius.circular(20)));
    final masker = Path.combine(PathOperation.difference, buiten, gat);
    canvas.drawPath(masker, maskerVerf);
  }

  @override
  bool shouldRepaint(covariant _ScanMaskerPainter old) =>
      old.vensterGrootte != vensterGrootte;
}

class _ScanVenster extends StatelessWidget {
  const _ScanVenster({required this.scanAnim});
  final AnimationController scanAnim;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, buiten) {
        final grootte = _venstergrootte(
            BoxConstraints.tightFor(width: buiten.maxWidth));
        return SizedBox(
          width: grootte,
          height: grootte,
          child: Stack(
            children: [
              // Corner brackets (4 hoeken)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CornerBracketsPainter(
                    kleur: AppColors.primary,
                    dikte: 5,
                    lengte: grootte * 0.18,
                  ),
                ),
              ),
              // Animerende scanline
              AnimatedBuilder(
                animation: scanAnim,
                builder: (context, _) {
                  // 8% marge boven/onder zodat de lijn precies binnen de
                  // bracket-hoeken beweegt, net als in de referentie-
                  // screenshot.
                  final marge = grootte * 0.08;
                  final t = Curves.easeInOut.transform(scanAnim.value);
                  final y = marge + (grootte - marge * 2) * t;
                  return Positioned(
                    left: 8,
                    right: 8,
                    top: y - 1,
                    child: _Scanline(kleur: AppColors.primary),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Scanline extends StatelessWidget {
  const _Scanline({required this.kleur});
  final Color kleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kleur.withValues(alpha: 0.0),
            kleur,
            kleur.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: kleur.withValues(alpha: 0.55),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter({
    required this.kleur,
    required this.dikte,
    required this.lengte,
  });
  final Color kleur;
  final double dikte;
  final double lengte;

  @override
  void paint(Canvas canvas, Size size) {
    final verf = Paint()
      ..color = kleur
      ..strokeWidth = dikte
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // top-left
    canvas.drawLine(Offset(0, lengte), const Offset(0, 0), verf);
    canvas.drawLine(const Offset(0, 0), Offset(lengte, 0), verf);
    // top-right
    canvas.drawLine(
        Offset(size.width - lengte, 0), Offset(size.width, 0), verf);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, lengte), verf);
    // bottom-left
    canvas.drawLine(
        Offset(0, size.height - lengte), Offset(0, size.height), verf);
    canvas.drawLine(
        Offset(0, size.height), Offset(lengte, size.height), verf);
    // bottom-right
    canvas.drawLine(Offset(size.width - lengte, size.height),
        Offset(size.width, size.height), verf);
    canvas.drawLine(Offset(size.width, size.height - lengte),
        Offset(size.width, size.height), verf);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter old) =>
      old.kleur != kleur || old.dikte != dikte || old.lengte != lengte;
}

class _RondeIconKnop extends StatelessWidget {
  const _RondeIconKnop({required this.icoon, required this.onTap});
  final IconData icoon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icoon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _FoutBalk extends StatelessWidget {
  const _FoutBalk({required this.boodschap, required this.onOpnieuw});
  final String boodschap;
  final VoidCallback onOpnieuw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              boodschap,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onOpnieuw,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Opnieuw',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _CameraFoutView extends StatelessWidget {
  const _CameraFoutView({required this.fout, required this.onOpnieuw});
  final MobileScannerException fout;
  final VoidCallback onOpnieuw;

  @override
  Widget build(BuildContext context) {
    final vriendelijk = switch (fout.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Klantio heeft geen toestemming om je camera te gebruiken. '
            'Geef in je telefooninstellingen camera-toegang aan Klantio en '
            'probeer het opnieuw.',
      MobileScannerErrorCode.unsupported =>
        'Dit toestel ondersteunt de QR-scanner niet. Gebruik de handmatige '
            'koppelcode.',
      _ =>
        'De camera kon niet worden gestart. Probeer het opnieuw of gebruik '
            'de handmatige koppelcode.',
    };

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded,
              color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            vriendelijk,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: onOpnieuw,
                child: const Text('Opnieuw proberen'),
              ),
              TextButton(
                onPressed: () =>
                    GoRouter.of(context).go('/koppelcode/handmatig'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Koppelcode invoeren'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

double _venstergrootte(BoxConstraints c) {
  final basis = c.maxWidth.isFinite ? c.maxWidth : 320.0;
  return (basis * 0.72).clamp(220.0, 320.0);
}
