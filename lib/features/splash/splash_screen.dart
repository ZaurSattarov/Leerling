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
  late final AnimationController _ctrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.87, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.40, curve: Curves.easeOut),
    );

    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.81, 1.0, curve: Curves.easeIn),
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
      backgroundColor: AppColors.surface,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Opacity(
            opacity: _screenFade.value,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── KLANTIO met rode balk ─────────────────────────────────
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 9,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Text(
                            'KLANTIO',
                            style: GoogleFonts.inter(
                              color: AppColors.dark,
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── LEERLINGEN subtitle ───────────────────────────────────
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'LEERLINGENPORTAAL',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 5.5,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
