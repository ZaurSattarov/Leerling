import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/registreer_screen.dart';
import 'features/auth/wachtwoord_vergeten_screen.dart';
import 'features/koppelcode/koppelcode_screen.dart';
import 'features/home/home_screen.dart';
import 'features/planning/planning_screen.dart';
import 'features/planning/les_detail_screen.dart';
import 'features/voortgang/voortgang_screen.dart';
import 'features/facturen/facturen_screen.dart';
import 'features/facturen/factuur_detail_screen.dart';
import 'features/notificaties/notificaties_screen.dart';
import 'features/profiel/profiel_screen.dart';
import 'shared/widgets/main_scaffold.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn =
          Supabase.instance.client.auth.currentUser != null;
      final loc = state.matchedLocation;

      if (loc == '/splash') return null;

      final isAuthRoute = loc.startsWith('/login') ||
          loc.startsWith('/registreer') ||
          loc.startsWith('/wachtwoord-vergeten');

      if (!isLoggedIn && !isAuthRoute && loc != '/koppelcode') return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registreer',
        builder: (_, __) => const RegistreerScreen(),
      ),
      GoRoute(
        path: '/wachtwoord-vergeten',
        builder: (_, __) => const WachtwoordVergetenScreen(),
      ),
      GoRoute(
        path: '/koppelcode',
        builder: (_, __) => const KoppelcodeScreen(),
      ),

      // Notificaties — full screen, outside bottom nav
      GoRoute(
        path: '/notificaties',
        builder: (_, __) => const NotificatiesScreen(),
      ),

      // App routes with bottom nav shell
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/planning',
            builder: (_, __) => const PlanningScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    LesDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/voortgang',
            builder: (_, __) => const VoortgangScreen(),
          ),
          GoRoute(
            path: '/facturen',
            builder: (_, __) => const FacturenScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    FactuurDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/profiel',
            builder: (_, __) => const ProfielScreen(),
          ),
        ],
      ),
    ],
  );
});

class LeerlingApp extends ConsumerWidget {
  const LeerlingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Mijn Rijschool',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textHint),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
    );
  }
}
