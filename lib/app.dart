import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/services/push_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/registreer_screen.dart';
import 'features/auth/verificatie_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/wachtwoord_vergeten_screen.dart';
import 'features/auth/wachtwoord_reset_code_screen.dart';
import 'features/koppelcode/koppelcode_screen.dart';
import 'features/home/home_screen.dart';
import 'features/planning/planning_screen.dart';
import 'features/planning/les_detail_screen.dart';
import 'features/les_logboek/les_logboek_screen.dart';
import 'features/examenadvies/examenadvies_screen.dart';
import 'features/help/help_screen.dart';
import 'features/legal/content/privacy_policy_nl.dart';
import 'features/legal/content/terms_conditions_nl.dart';
import 'features/legal/legal_document_screen.dart';
import 'features/examens/examens_screen.dart';
import 'features/lesvoorbereiding/lesvoorbereiding_screen.dart';
import 'features/voortgang/lespakket_detail_screen.dart';
import 'features/voortgang/voortgang_screen.dart';
import 'features/facturen/facturen_screen.dart';
import 'features/facturen/factuur_detail_screen.dart';
import 'features/beschikbaarheid/beschikbaarheid_screen.dart';
import 'features/notificaties/notificatie_instellingen_screen.dart';
import 'features/notificaties/notificaties_screen.dart';
import 'features/profiel/app_machtigingen_screen.dart';
import 'features/profiel/app_instellingen_screen.dart';
import 'features/profiel/beveiliging_screen.dart';
import 'features/profiel/lespakket_detail_screen.dart';
import 'features/profiel/mijn_rijschool_screen.dart';
import 'features/profiel/persoonlijke_gegevens_screen.dart';
import 'features/profiel/profiel_screen.dart';
import 'shared/widgets/main_scaffold.dart';
import 'shared/widgets/student_profile_gate.dart';

// Push notificaties (Fase 5): nodig om vanuit een achtergrond-/cold-start-
// tik te kunnen navigeren zonder een widget-BuildContext bij de hand te
// hebben. Dit bestond nog niet in deze app (anders dan de Instructeur-app).
final rootNavigatorKey = GlobalKey<NavigatorState>();

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _event = data.event;
      if (data.event == AuthChangeEvent.signedIn) {
        PushService.requestPermissionAndRegister();
      }
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;
  AuthChangeEvent? _event;
  AuthChangeEvent? get event => _event;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final loc = state.uri.path;

      if (loc == '/splash') return null;

      // Password recovery deep link — redirect to reset screen
      if (authNotifier.event == AuthChangeEvent.passwordRecovery) {
        return loc == '/reset-password' ? null : '/reset-password';
      }

      final isAuthRoute = loc.startsWith('/login') ||
          loc.startsWith('/registreer') ||
          loc.startsWith('/wachtwoord-vergeten');
      final isPublicRoute = isAuthRoute ||
          loc == '/verificatie' ||
          loc == '/wachtwoord-reset-code' ||
          loc == '/reset-password';

      if (!isLoggedIn && !isPublicRoute) return '/login';

      if (isLoggedIn) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user?.emailConfirmedAt == null && loc != '/verificatie') {
          return '/verificatie';
        }
        if (isAuthRoute) return '/splash';
      }
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
        path: '/verificatie',
        builder: (_, state) => VerificatieScreen(
          email: state.extra as String? ??
              Supabase.instance.client.auth.currentUser?.email ??
              '',
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/wachtwoord-vergeten',
        builder: (_, __) => const WachtwoordVergetenScreen(),
      ),
      GoRoute(
        path: '/wachtwoord-reset-code',
        builder: (_, state) => WachtwoordResetCodeScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/koppelcode',
        builder: (_, __) => const KoppelcodeScreen(),
      ),

      // Help — full screen, outside bottom nav
      GoRoute(
        path: '/help',
        builder: (_, __) => const StudentProfileGate(
          child: HelpScreen(),
        ),
      ),

      // Notificaties — full screen, outside bottom nav
      GoRoute(
        path: '/notificaties',
        builder: (_, __) => const StudentProfileGate(
          child: NotificatiesScreen(),
        ),
      ),

      // Beschikbaarheid — full screen, outside bottom nav
      GoRoute(
        path: '/profiel/notificatie-instellingen',
        builder: (_, __) => const StudentProfileGate(
          child: NotificatieInstellingenScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/app-instellingen',
        builder: (_, __) => const StudentProfileGate(
          child: AppInstellingenScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/app-machtigingen',
        builder: (_, __) => const StudentProfileGate(
          child: AppMachtigingenScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/beveiliging',
        builder: (_, __) => const StudentProfileGate(
          child: BeveiligingScreen(),
        ),
      ),

      GoRoute(
        path: '/beschikbaarheid',
        builder: (_, __) => const StudentProfileGate(
          child: BeschikbaarheidScreen(),
        ),
      ),

      // ── Detailschermen — bewust BUITEN de ShellRoute (dus geen bottom
      // navbar), consistent met /help, /notificaties en /beschikbaarheid
      // hierboven. Elk heeft een terugpijl (MainDetailHeader) i.p.v. een
      // tabbestemming te zijn. Absolute paden (bv. '/planning/:id') zijn
      // hier bewust NIET meer genest onder hun hoofdtab-route -- GoRouter
      // matcht op het volledige pad, ongeacht waar de route in de boom
      // staat, en `context.push('/planning/$id')`-aanroepen (absoluut pad)
      // blijven daardoor ongewijzigd werken.
      GoRoute(
        path: '/planning/:id',
        builder: (_, state) => StudentProfileGate(
          child: LesDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/les-logboek',
        builder: (_, __) => const StudentProfileGate(
          child: LesLogboekScreen(),
        ),
      ),
      GoRoute(
        path: '/examenadvies',
        builder: (_, __) => const StudentProfileGate(
          child: ExamenadviesScreen(),
        ),
      ),
      GoRoute(
        path: '/examens',
        builder: (_, __) => const StudentProfileGate(
          child: ExamensScreen(),
        ),
      ),
      GoRoute(
        path: '/lesvoorbereiding',
        builder: (_, __) => const StudentProfileGate(
          child: LesvoorbereidingScreen(),
        ),
      ),
      GoRoute(
        path: '/voortgang/lespakket',
        builder: (_, __) => const StudentProfileGate(
          child: LespakketDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/lespakket',
        builder: (_, __) => const StudentProfileGate(
          child: ProfielLespakketScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/persoonlijke-gegevens',
        builder: (_, __) => const StudentProfileGate(
          child: ProfielPersoonlijkeGegevensScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/mijn-rijschool',
        builder: (_, __) => const StudentProfileGate(
          child: MijnRijschoolScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/privacy',
        builder: (_, __) => const StudentProfileGate(
          child: LegalDocumentScreen(document: privacyPolicyNl),
        ),
      ),
      GoRoute(
        path: '/profiel/algemene-voorwaarden',
        builder: (_, __) => const StudentProfileGate(
          child: LegalDocumentScreen(document: termsConditionsNl),
        ),
      ),
      GoRoute(
        path: '/facturen/:id',
        builder: (_, state) => StudentProfileGate(
          child: FactuurDetailScreen(id: state.pathParameters['id']!),
        ),
      ),

      // App routes with bottom nav shell -- alleen de vijf echte hoofdtabs
      ShellRoute(
        builder: (_, __, child) => StudentProfileGate(
          child: MainScaffold(child: child),
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/planning',
            builder: (_, __) => const PlanningScreen(),
          ),
          GoRoute(
            path: '/voortgang',
            builder: (_, __) => const VoortgangScreen(),
          ),
          GoRoute(
            path: '/facturen',
            builder: (_, __) => const FacturenScreen(),
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
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: AppColors.surface,
          modalBarrierColor: Colors.black54,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: AppColors.dark,
          headerForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          todayBorder:
              BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
          todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          hourMinuteTextStyle:
              const TextStyle(fontSize: 44, fontWeight: FontWeight.w700),
          dayPeriodTextStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          dialHandColor: AppColors.primary,
          dialBackgroundColor: AppColors.surface,
          hourMinuteColor: AppColors.surface,
          entryModeIconColor: AppColors.textSecondary,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme.copyWith(
                headlineMedium: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
                headlineSmall: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
                titleLarge: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
                titleMedium: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                titleSmall: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                bodyLarge:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                bodyMedium: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                bodySmall:
                    const TextStyle(color: AppColors.textHint, fontSize: 12),
                labelLarge:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                labelMedium: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                labelSmall: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.dark.withValues(alpha: 0.20),
          selectionHandleColor: AppColors.primary,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.white;
          }),
          checkColor: WidgetStateProperty.all(AppColors.white),
          side: const BorderSide(color: AppColors.border),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(AppColors.primary),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.white;
            }
            return AppColors.textHint;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.border;
          }),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.dark, width: 1.15),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.dangerText, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppColors.dangerText, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle:
              GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
          floatingLabelStyle: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: AppColors.border),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.dark,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          margin: EdgeInsets.zero,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 0.5,
        ),
      ),
    );
  }
}
