import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/lifecycle/account_scoped_invalidation.dart';
import 'core/providers/main_shell_nav_bar_visibility.dart';
import 'core/services/native_navigation_bridge.dart';
import 'core/services/access_gate_service.dart';
import 'core/services/push_service.dart';
import 'features/arrival/arrival_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/account_geblokkeerd_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/registreer_screen.dart';
import 'features/auth/verificatie_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/wachtwoord_vergeten_screen.dart';
import 'features/auth/wachtwoord_reset_code_screen.dart';
import 'features/koppelcode/koppelcode_screen.dart';
import 'features/koppelcode/koppel_keuze_screen.dart';
import 'features/koppelcode/qr_scan_screen.dart';
import 'features/profiel/profiel_afronden_screen.dart';
import 'features/home/home_screen.dart';
import 'features/planning/planning_screen.dart';
import 'features/planning/les_detail_screen.dart';
import 'features/les_logboek/les_logboek_screen.dart';
import 'features/examenadvies/examenadvies_screen.dart';
import 'features/help/support_chat_screen.dart';
import 'features/help/support_inbox_screen.dart';
import 'features/legal/content/privacy_policy_nl.dart';
import 'features/legal/content/terms_conditions_nl.dart';
import 'features/legal/legal_document_screen.dart';
import 'features/examens/examens_screen.dart';
import 'features/lesvoorbereiding/lesvoorbereiding_screen.dart';
import 'features/voortgang/lespakket_detail_screen.dart';
import 'features/voortgang/voortgang_screen.dart';
import 'features/voortgang/voortgang_tijdlijn_screen.dart';
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
import 'features/profiel/privacy_juridisch_screen.dart';
import 'features/profiel/profiel_screen.dart';
import 'shared/widgets/main_scaffold.dart';
import 'shared/widgets/student_profile_gate.dart';

// Push notificaties (Fase 5): nodig om vanuit een achtergrond-/cold-start-
// tik te kunnen navigeren zonder een widget-BuildContext bij de hand te
// hebben. Dit bestond nog niet in deze app (anders dan de Instructeur-app).
final rootNavigatorKey = GlobalKey<NavigatorState>();

String? _laatsteAuthCode;

/// Google- en e-mailbevestiging komen terug als
/// `leerlingplanner://auth/...`. GoRouter kent dat adres niet als pagina.
/// De code wordt hier omgewisseld voor een sessie, daarna gaat de app
/// naar splash of wachtwoord-reset.
Future<void> _rondAuthCallbackAf(Uri uri) async {
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) return;
  if (code == _laatsteAuthCode) return;
  if (Supabase.instance.client.auth.currentSession != null) {
    _laatsteAuthCode = code;
    return;
  }
  _laatsteAuthCode = code;
  try {
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
  } catch (e) {
    debugPrint('[auth] callback mislukt: ${e.runtimeType}');
  }
}

/// Centrale GoRouter-referentie voor push-deeplinks (zelfde patroon als
/// factuur deep link via ref.read(_routerProvider).push in _LeerlingAppState).
GoRouter? globalLeerlingGoRouter;

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _event = data.event;
      // Live Aankomst (Fase 2C): bij logout/auth-verlies geen sessie- of
      // locatiedata van de vorige gebruiker laten staan voor een eventuele
      // volgende gebruiker op hetzelfde toestel.
      if (data.event == AuthChangeEvent.signedOut) {
        scheduleAccountScopedProviderInvalidation(() {
          _ref.read(arrivalControllerProvider.notifier).onAuthLost();
        });
        blockedAccessStatus = null;
        _ref.read(mainShellMountedProvider.notifier).state = false;
        _ref
            .read(nativeNavigationProvider.notifier)
            .setBarVisible(false, force: true);
      }
      // Klantio Intern Beheerplatform — accountblokkade (Optie B,
      // 2026-09-01). Losstaande, aanvullende check naast alle bestaande
      // logica hierboven/hieronder — raakt geen bestaande state. Draait bij
      // zowel signedIn als een herstelde sessie (initialSession), fail-open
      // bij netwerkfouten (zie AccessGateService). Zet enkel een vlag +
      // notifyListeners() zodat de synchrone `redirect` hieronder alsnog
      // naar '/account-geblokkeerd' kan sturen.
      if (data.event == AuthChangeEvent.signedIn ||
          (data.event == AuthChangeEvent.initialSession &&
              data.session?.user != null)) {
        unawaited(_checkAccessStatus());
      }
      // `signedIn` vuurt NIET bij het herstellen van een bestaande sessie op
      // een koude start — dat is `initialSession`. Zonder die tak hangt de
      // pushregistratie voor een AL ingelogde gebruiker volledig af van de
      // post-frame-callback in main.dart, en die raced met het herstellen van
      // de sessie. Zelfde structurele gat als in de Instructeur-app (Klantio
      // iOS push-audit 2026-08-27). requestPermissionAndRegister is
      // idempotent, dus de mogelijke dubbele aanroep is veilig.
      if (data.event == AuthChangeEvent.signedIn ||
          (data.event == AuthChangeEvent.initialSession &&
              data.session?.user != null)) {
        PushService.requestPermissionAndRegister();
        // Sessie hersteld: pending push-tap opnieuw proberen (cold-start race).
        unawaited(PushService.flushPendingNavigation());
        PushService.schedulePendingFlush();
      }
      notifyListeners();
    });
  }

  final Ref _ref;
  late final StreamSubscription<AuthState> _sub;
  AuthChangeEvent? _event;
  AuthChangeEvent? get event => _event;

  /// null = niet geblokkeerd/nog niet gecontroleerd. 'blocked'/'suspended'
  /// zodra `_checkAccessStatus` dat vaststelt — de synchrone `redirect` in
  /// de GoRouter hieronder leest dit veld.
  String? blockedAccessStatus;

  Future<void> _checkAccessStatus() async {
    final status = await AccessGateService.currentAccessStatus();
    if (status == 'active') return;
    await Supabase.instance.client.auth.signOut();
    blockedAccessStatus = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      if (state.uri.scheme == 'leerlingplanner' && state.uri.host == 'auth') {
        await _rondAuthCallbackAf(state.uri);
        if (state.uri.path == '/reset-password') return '/reset-password';
        return '/splash';
      }

      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final loc = state.uri.path;

      if (loc == '/splash') return null;

      // Klantio Intern Beheerplatform — accountblokkade (Optie B,
      // 2026-09-01). Bewust vóór alle onderstaande routing-logica — een
      // geblokkeerde/opgeschorte gebruiker (al server-side uitgelogd, zie
      // _checkAccessStatus) mag nooit op een andere route belanden.
      if (authNotifier.blockedAccessStatus != null) {
        return loc == '/account-geblokkeerd' ? null : '/account-geblokkeerd';
      }

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
        path: '/account-geblokkeerd',
        builder: (_, __) => AccountGeblokkeerdScreen(
          accessStatus: authNotifier.blockedAccessStatus ?? 'blocked',
        ),
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
      // Koppel-flow. `/koppelcode` is de KEUZE-landing (QR of code); alle
      // bestaande redirects (login/verificatie/splash/StudentProfileGate)
      // blijven naar `/koppelcode` gaan en landen op de keuze. De
      // handmatige invoer is verplaatst naar `/koppelcode/handmatig` --
      // dezelfde canonical RPC, dezelfde vervolgnavigatie. De scanner
      // staat op `/koppelcode/scan`.
      GoRoute(
        path: '/koppelcode',
        builder: (_, __) => const KoppelKeuzeScreen(),
      ),
      GoRoute(
        path: '/koppelcode/handmatig',
        builder: (_, __) => const KoppelcodeInvoerenScreen(),
      ),
      GoRoute(
        path: '/koppelcode/scan',
        builder: (_, __) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/profiel-afronden',
        builder: (_, __) => const ProfielAfrondenScreen(),
      ),

      // Help & Support — full screen, outside bottom nav. Opent direct de
      // chat (redesign 2026-09-04): geen hub/FAQ-keuze en geen apart
      // onderwerp-/categorieformulier meer. '/help/support' blijft
      // geregistreerd voor bestaande notificatie-fallbacks
      // (routeVoorType('support_antwoord') in models/notificatie.dart) en
      // wijst naar hetzelfde directe-chatscherm als '/help'.
      GoRoute(
        path: '/help',
        // `?nieuw=1` (2026-09-10): door de "Nieuw ticket"-actie op
        // "Eerdere gesprekken" -- forceert direct de lege composer i.p.v.
        // een eventueel al actief gesprek te tonen. 1-op-1 poort van de
        // Instructeur-app (app.dart, `/profiel/support?nieuw=1`).
        builder: (_, state) => _DetailRoute(
          child: SupportChatScreen(
            forceNew: state.uri.queryParameters['nieuw'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/help/support',
        builder: (_, state) => _DetailRoute(
          child: SupportChatScreen(
            forceNew: state.uri.queryParameters['nieuw'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/help/support/:id',
        builder: (_, state) => _DetailRoute(
          child: SupportChatScreen(threadId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/help/gesprekken',
        builder: (_, __) => const _DetailRoute(
          child: SupportInboxScreen(),
        ),
      ),

      // Notificaties — full screen, outside bottom nav
      GoRoute(
        path: '/notificaties',
        builder: (_, __) => const _DetailRoute(
          child: NotificatiesScreen(),
        ),
      ),

      // Beschikbaarheid — full screen, outside bottom nav
      GoRoute(
        path: '/profiel/notificatie-instellingen',
        builder: (_, __) => const _DetailRoute(
          child: NotificatieInstellingenScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/app-instellingen',
        builder: (_, __) => const _DetailRoute(
          child: AppInstellingenScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/app-machtigingen',
        builder: (_, __) => const _DetailRoute(
          child: AppMachtigingenScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/beveiliging',
        builder: (_, __) => const _DetailRoute(
          child: BeveiligingScreen(),
        ),
      ),

      GoRoute(
        path: '/beschikbaarheid',
        builder: (_, __) => const _DetailRoute(
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
        builder: (_, state) => _DetailRoute(
          child: LesDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/les-logboek',
        builder: (_, __) => const _DetailRoute(
          child: LesLogboekScreen(),
        ),
      ),
      GoRoute(
        path: '/examenadvies',
        builder: (_, __) => const _DetailRoute(
          child: ExamenadviesScreen(),
        ),
      ),
      GoRoute(
        path: '/examens',
        builder: (_, state) => _DetailRoute(
          child: ExamensScreen(
            highlightExamId: state.uri.queryParameters['exam'],
          ),
        ),
      ),
      GoRoute(
        path: '/lesvoorbereiding',
        builder: (_, __) => const _DetailRoute(
          child: LesvoorbereidingScreen(),
        ),
      ),
      GoRoute(
        path: '/voortgang/lespakket',
        builder: (_, __) => const _DetailRoute(
          child: LespakketDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/voortgang/tijdlijn',
        builder: (_, __) => const _DetailRoute(
          child: VoortgangTijdlijnScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/lespakket',
        builder: (_, __) => const _DetailRoute(
          child: ProfielLespakketScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/persoonlijke-gegevens',
        builder: (_, __) => const _DetailRoute(
          child: ProfielPersoonlijkeGegevensScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/mijn-rijschool',
        builder: (_, __) => const _DetailRoute(
          child: MijnRijschoolScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/privacy',
        builder: (_, __) => const _DetailRoute(
          child: PrivacyJuridischScreen(),
        ),
      ),
      GoRoute(
        path: '/profiel/privacy-beleid',
        builder: (_, __) => const _DetailRoute(
          child: LegalDocumentScreen(document: privacyPolicyNl),
        ),
      ),
      GoRoute(
        path: '/profiel/algemene-voorwaarden',
        builder: (_, __) => const _DetailRoute(
          child: LegalDocumentScreen(document: termsConditionsNl),
        ),
      ),
      GoRoute(
        path: '/facturen/:id',
        builder: (_, state) => _DetailRoute(
          child: FactuurDetailScreen(
            id: state.pathParameters['id']!,
            // Hint (GEEN bewijs van betaling): gezet door de deep-link-
            // handler hieronder na terugkeer van de Mollie-betaalpagina.
            // FactuurDetailScreen haalt zelf de echte status uit Supabase op
            // en gebruikt dit alleen om kort "Betaling wordt verwerkt" te
            // tonen + een beperkt aantal keer opnieuw te verversen.
            verifyPayment: state.uri.queryParameters['verify'] == '1',
          ),
        ),
      ),

      // App routes with bottom nav shell -- alleen de vijf echte hoofdtabs.
      // NoTransitionPage: geen platform-paginatransitie tussen tabs; de
      // richtingsbewuste slide zit in TabSlideSwitcher (MainScaffold) --
      // zelfde aanpak als de Instructeur-app.
      ShellRoute(
        builder: (_, __, child) => StudentProfileGate(
          child: MainScaffold(child: child),
        ),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/planning',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PlanningScreen(),
            ),
          ),
          GoRoute(
            path: '/voortgang',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const VoortgangScreen(),
            ),
          ),
          GoRoute(
            path: '/facturen',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const FacturenScreen(),
            ),
          ),
          GoRoute(
            path: '/profiel',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfielScreen(),
            ),
          ),
        ],
      ),
    ],
  );
  globalLeerlingGoRouter = router;
  ref.onDispose(() {
    if (globalLeerlingGoRouter == router) {
      globalLeerlingGoRouter = null;
    }
  });
  return router;
});

/// Detail-/subscherm buiten de ShellRoute: profielpoort + de native iOS
/// glasbalk verbergen zolang dit scherm open is. Die balk is een overlay op
/// het hele venster en zou anders bovenop detailschermen blijven staan,
/// terwijl de Leerling-app daar bewust geen navbar toont.
class _DetailRoute extends StatelessWidget {
  final Widget child;
  const _DetailRoute({required this.child});

  @override
  Widget build(BuildContext context) =>
      KlantioNavAfdekker(child: StudentProfileGate(child: child));
}

class LeerlingApp extends ConsumerStatefulWidget {
  const LeerlingApp({super.key});

  @override
  ConsumerState<LeerlingApp> createState() => _LeerlingAppState();
}

class _LeerlingAppState extends ConsumerState<LeerlingApp>
    with WidgetsBindingObserver {
  // Mollie-factuurbetaling: return-pagina opent
  // leerlingplanner://factuur?id=<factuurId>. Zelfde, bewust hergebruikte
  // patroon als de Instructeur-app (rijschool-planner-flutter/lib/app.dart
  // _initDeepLinks/_handleDeepLink): AppLinks voor zowel cold start
  // (getInitialLink) als app-al-actief/achtergrond (uriLinkStream), met
  // dezelfde idempotentie-check (laatst verwerkte volledige URI nooit twee
  // keer verwerken binnen deze sessie).
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _laatstVerwerkteLink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PushService.onAppResumed();
      ref.read(arrivalControllerProvider.notifier).onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      ref.read(arrivalControllerProvider.notifier).onAppPaused();
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (e) {
      debugPrint('[DeepLink] initial link ophalen mislukt: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (e) => debugPrint('[DeepLink] stream fout: $e'),
    );
  }

  void _handleDeepLink(Uri uri) {
    final uriString = uri.toString();
    if (_laatstVerwerkteLink == uriString) return;
    _laatstVerwerkteLink = uriString;

    if (uri.host == 'factuur') {
      _handleFactuurDeepLink(uri);
    }
    // Overige hosts (auth) lopen al via Supabase Auth's eigen deep-link-
    // afhandeling -- niet in scope van deze fix.
  }

  void _handleFactuurDeepLink(Uri uri) {
    final factuurId = uri.queryParameters['id'];
    if (factuurId == null || factuurId.isEmpty) return;
    // `verify=1`: puur een UI-hint voor FactuurDetailScreen (kort "Betaling
    // wordt verwerkt" + beperkte refetch) -- nooit als bewijs van betaling
    // gebruikt. De echte status komt altijd uit een verse Supabase-fetch.
    ref.read(_routerProvider).push('/facturen/$factuurId?verify=1');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Mijn Rijschool',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Standaard donkere statusbalk-iconen op de lichte pagina's; de donkere
      // headerbalk (KlantioHeaderShell) zet daar zelf lichte iconen overheen.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),
      // Thema 1-op-1 uit de Instructeur-app (rijschool-planner-flutter/
      // lib/app.dart): zelfde knoppen (donkere pil), invoervelden,
      // kaarten, snackbars en datumkiezer.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.pageBg,
        iconTheme: const IconThemeData(color: AppColors.iconPrimary),
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
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.loadingAccent,
          circularTrackColor: AppColors.loadingPrimary,
          linearTrackColor: AppColors.loadingSecondary,
          refreshBackgroundColor: AppColors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFFF8FAFC),
          contentTextStyle: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          actionTextColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: AppColors.dark,
          headerForegroundColor: AppColors.white,
          yearForegroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.textPrimary;
            }
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textHint.withValues(alpha: 0.45);
            }
            return AppColors.textPrimary;
          }),
          yearBackgroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.neutralBg;
            }
            return Colors.transparent;
          }),
          dayForegroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.white;
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textHint.withValues(alpha: 0.45);
            }
            return AppColors.textPrimary;
          }),
          dayBackgroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return Colors.transparent;
          }),
          todayForegroundColor:
              const WidgetStatePropertyAll(AppColors.textPrimary),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
          ),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme.copyWith(
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
                labelLarge: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
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
          cursorColor: AppColors.dark,
          selectionColor: AppColors.dark.withValues(alpha: 0.18),
          selectionHandleColor: AppColors.dark,
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
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
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
            borderSide:
                const BorderSide(color: AppColors.textPrimary, width: 1.15),
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
              color: AppColors.dark, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C2938),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1C2938),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1C2938),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            side: const BorderSide(color: Color(0xFF1C2938)),
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
