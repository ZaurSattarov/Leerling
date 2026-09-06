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
import 'widgets/splash_svg_element.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Visuele opbouw/animatie 1-op-1 overgenomen van de Instructeur-app
  // (rijschool-planner-flutter/lib/features/splash/splash_screen.dart,
  // KlantioStartupSplash) zodat beide apps dezelfde startup-splash tonen --
  // Instructeur = bron van waarheid. Alleen de assets (ICON/KLANTIO/
  // LEERLINGENPORTAAL i.p.v. L icon/KLANTIO/RIJPLANNER) en de
  // achtergrondkleur (#131528 i.p.v. AppColors.primary) wijken af. De
  // bestaande bootstrap-/routinglogica hieronder (auth-check, redirect naar
  // /login, /verificatie, /home, /koppelcode) is bewust ongewijzigd
  // gelaten -- dit widget blijft, anders dan de Instructeur-splash, een
  // geroute pagina die zelf navigeert na afloop van de animatie.
  static const _lIconAssetPath = 'assets/Splash Screen/l ICON.svg';
  static const _klantioAssetPath = 'assets/Splash Screen/KLANTIO.svg';
  static const _portaalAssetPath =
      'assets/Splash Screen/LEERLINGENPORTAAL.svg';

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
          return _SplashCanvas(
            composition: composition,
            lIcon: SplashSvgElement(
              elementKey: const ValueKey('splash-l-icon'),
              assetPath: _lIconAssetPath,
              width: composition.lSize,
              height: composition.lSize,
              appear: _phases.lAppear,
              appearScaleFrom: 0.92,
            ),
            klantio: SplashSvgElement(
              elementKey: const ValueKey('splash-klantio'),
              assetPath: _klantioAssetPath,
              width: composition.klantioWidth,
              height: composition.klantioHeight,
              appear: _phases.klantioAppear,
              appearScaleFrom: 0.97,
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
/// gecentreerde compositie van ICON, KLANTIO (gecentreerd) en
/// LEERLINGENPORTAAL (klein, rechts uitgelijnd onder het woordmerk) --
/// zelfde structuur als `_SplashCanvas` in de Instructeur-app. Puur
/// structuur -- alle beweging zit in de (intro-)animaties die van
/// buitenaf worden doorgegeven; na de intro blijft alles gewoon stilstaan.
class _SplashCanvas extends StatelessWidget {
  final SplashComposition composition;
  final Widget lIcon;
  final Widget klantio;
  final Widget portaal;

  const _SplashCanvas({
    required this.composition,
    required this.lIcon,
    required this.klantio,
    required this.portaal,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.splashBackground,
      child: Center(
        child: SizedBox(
          height: composition.totalHeight,
          width: composition.klantioWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              lIcon,
              SizedBox(height: composition.gapLToKlantio),
              klantio,
              SizedBox(height: composition.gapKlantioToPortaal),
              // LEERLINGENPORTAAL: klein, hangt net voorbij de rechterrand
              // van het woordmerk -- exact dezelfde compositieregel als
              // RIJPLANNER bij de Instructeur-app. De extra verticale drop
              // is een pure paint-verschuiving (geen layout-effect), dus
              // ICON/KLANTIO en hun centrering blijven ongewijzigd.
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
    );
  }
}
