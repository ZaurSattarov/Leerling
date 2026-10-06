import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/push_service.dart';
import '../../core/services/student_service.dart';
import 'splash_layout.dart';
import 'splash_phase_animations.dart';
import 'widgets/splash_logo_mark.dart';
import 'widgets/splash_svg_element.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Opbouw (lay-out, woordmerk-wipe, korte tijdlijn) volgt de
  // Instructeur-splash (rijschool-planner-flutter/lib/features/splash/).
  // Eigen aan de Leerling-app: het merkteken "Behaald" bouwt zichzelf op
  // uit vier blokken + het doel-hoekje (zie SplashLogoMark), en de
  // achtergrond is het donker van het Leerling-app-icoon. De bestaande
  // bootstrap-/routinglogica hieronder (auth-check, redirect naar /login,
  // /verificatie, /home, /koppelcode) is bewust ongewijzigd gelaten -- dit
  // widget blijft een geroute pagina die zelf navigeert na afloop van de
  // animatie.
  static const _klantioAssetPath = 'assets/Splash Screen/KLANTIO.svg';
  static const _portaalAssetPath = 'assets/Splash Screen/LEERLINGENPORTAAL.svg';

  late final AnimationController _ctrl;
  late final SplashPhaseAnimations _phases;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: SplashPhaseAnimations.totalDuration,
    );
    _phases = SplashPhaseAnimations(_ctrl);

    _ctrl.forward().whenCompleteOrCancel(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    if (user.emailConfirmedAt == null) {
      await StudentService.uitloggen();
      if (mounted) context.go('/verificatie', extra: user.email ?? '');
      return;
    }

    final profiel = await _laadProfiel();
    if (!mounted) return;

    if (profiel.isNetworkError) {
      context.go('/home');
      return;
    }

    PushService.markRouterReady();
    final deeplinkUitgevoerd = await PushService.flushPendingNavigation();
    if (!mounted) return;
    if (deeplinkUitgevoerd) return;

    context.go(profiel.exists ? '/home' : '/koppelcode');
  }

  Future<_SplashProfileResult> _laadProfiel() async {
    try {
      final profiel = await StudentService.getMijnProfiel();
      return _SplashProfileResult(exists: profiel != null);
    } on ProfileLookupException {
      return const _SplashProfileResult(isNetworkError: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final composition = SplashLayout.composeFor(
            MediaQuery.sizeOf(context).width,
          );
          final exit = _phases.exitFade.value.clamp(0.0, 1.0);

          return _SplashCanvas(
            composition: composition,
            exitProgress: exit,
            mark: SplashLogoMark(
              elementKey: const ValueKey('splash-logo-mark'),
              size: composition.markSize,
              phases: _phases,
            ),
            klantio: SplashSvgElement(
              elementKey: const ValueKey('splash-klantio'),
              assetPath: _klantioAssetPath,
              width: composition.klantioWidth,
              height: composition.klantioHeight,
              appear: _phases.klantioReveal,
              wipe: true,
            ),
            portaal: SplashSvgElement(
              elementKey: const ValueKey('splash-leerlingenportaal'),
              assetPath: _portaalAssetPath,
              width: composition.portaalWidth,
              height: composition.portaalHeight,
              appear: _phases.portaalAppear,
            ),
          );
        },
      ),
    );
  }
}

class _SplashProfileResult {
  const _SplashProfileResult({
    this.exists = false,
    this.isNetworkError = false,
  });

  final bool exists;
  final bool isNetworkError;
}

/// Legt de vaste lay-out van de splash vast: effen achtergrond +
/// gecentreerde compositie van het merkteken, KLANTIO (gecentreerd) en
/// LEERLINGENPORTAAL (klein, rechts uitgelijnd onder het woordmerk) --
/// zelfde structuur als `_SplashCanvas` in de Instructeur-app. Puur
/// structuur -- alle intro-beweging zit in de animaties die van buitenaf
/// worden doorgegeven. Bij de uitgang stijgt de lockup licht op en vervaagt
/// naar de achtergrond, waarna de splash zelf doornavigeert.
class _SplashCanvas extends StatelessWidget {
  final SplashComposition composition;
  final double exitProgress;
  final Widget mark;
  final Widget klantio;
  final Widget portaal;

  const _SplashCanvas({
    required this.composition,
    required this.exitProgress,
    required this.mark,
    required this.klantio,
    required this.portaal,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.splashBackground,
      child: Center(
        child: Opacity(
          opacity: 1.0 - exitProgress,
          child: Transform.translate(
            offset: Offset(0, -16 * composition.scale * exitProgress),
            child: Transform.scale(
              scale: 1.0 + 0.045 * exitProgress,
              child: SizedBox(
                height: composition.totalHeight,
                width: composition.klantioWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    mark,
                    SizedBox(height: composition.gapMarkToKlantio),
                    klantio,
                    SizedBox(height: composition.gapKlantioToPortaal),
                    // LEERLINGENPORTAAL: klein, hangt net voorbij de rechterrand
                    // van het woordmerk -- exact dezelfde compositieregel als
                    // RIJPLANNER bij de Instructeur-app. De extra verticale drop
                    // is een pure paint-verschuiving (geen layout-effect), dus
                    // merkteken/KLANTIO en hun centrering blijven ongewijzigd.
                    Transform.translate(
                      offset: Offset(
                        composition.portaalRightOverhang,
                        composition.portaalExtraDrop,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: portaal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
