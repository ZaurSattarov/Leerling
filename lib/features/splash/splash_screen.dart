import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../models/leerling_profiel.dart';
import '../../shared/widgets/app_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  Timer? _bootstrapTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    _bootstrapTimer = Timer(const Duration(milliseconds: 1200), _bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('[splash] bootstrap user=${user?.id ?? 'null'}');
    if (user == null) {
      context.go('/login');
      return;
    }

    final profiel = await _laadProfiel();
    if (!mounted) return;

    final route = profiel != null ? '/home' : '/koppelcode';
    debugPrint('[splash] profiel=${profiel?.id ?? 'null'} route=$route');
    context.go(route);
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
    _bootstrapTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const AppLogo(
                    size: 88,
                    padding: 14,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mijn Rijschool',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Leerling app',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
