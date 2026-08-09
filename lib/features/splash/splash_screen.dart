import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../models/leerling_profiel.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animatie/opmaak 1-op-1 overgenomen van de Instructeur-app
  // (rijschool-planner-flutter/lib/features/splash/splash_screen.dart,
  // KlantioStartupSplash) zodat beide apps dezelfde startup-splash tonen.
  // Instructeur = "bron van waarheid"; hier alleen de tekst onderaan wijkt af
  // (LEERLINGENPORTAAL i.p.v. RIJPLANNER). De bestaande bootstrap-/
  // routinglogica hieronder (auth-check, redirect naar /login, /verificatie,
  // /home, /koppelcode) is bewust ongewijzigd gelaten.
  static double _logoSizeForWidth(double width) =>
      (width * 0.86).clamp(280.0, 360.0);

  static const _subtitleSlideDistance = 10.0;

  late final AnimationController _ctrl;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _subtitleOffset;
  late final Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.38, 0.62, curve: Curves.easeOut),
    );

    _subtitleOffset = Tween<double>(
      begin: _subtitleSlideDistance,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.44, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
      ),
    );

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

    context.go(profiel != null ? '/home' : '/koppelcode');
  }

  Future<LeerlingProfiel?> _laadProfiel() async {
    try {
      return await StudentService.getMijnProfiel();
    } catch (e) {
      debugPrint('[splash] profielcheck fout: $e');
      return null;
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
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final logoSize = _logoSizeForWidth(
            MediaQuery.sizeOf(context).width,
          );
          return Opacity(
            opacity: _screenFade.value,
            child: _SplashCanvas(
              logo: _logo(logoSize),
              logoSize: logoSize,
              subtitle: _subtitle(),
            ),
          );
        },
      ),
    );
  }

  Widget _logo(double logoSize) {
    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: Image.asset(
        'assets/images/klantio_splash_logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _subtitle() {
    return Transform.translate(
      offset: Offset(0, _subtitleOffset.value),
      child: FadeTransition(
        opacity: _subtitleFade,
        child: Text(
          'LEERLINGENPORTAAL',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.dark.withValues(alpha: 0.72),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 5.5,
            height: 1.0,
            decoration: TextDecoration.none,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _SplashCanvas extends StatelessWidget {
  final Widget logo;
  final double logoSize;
  final Widget subtitle;

  const _SplashCanvas({
    required this.logo,
    required this.logoSize,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: height * 0.46 - logoSize / 2,
                left: 0,
                right: 0,
                child: Center(child: logo),
              ),
              Positioned(
                top: height * 0.76,
                left: 24,
                right: 24,
                child: Center(child: subtitle),
              ),
            ],
          );
        },
      ),
    );
  }
}
