import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/debug/release_log_guard.dart';
import 'core/services/push_service.dart';
import 'core/services/secure_supabase_local_storage.dart';
import 'core/services/student_service.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Security/AVG: onderdruk alle debug-logging (mogelijke PII) in release —
    // moet vóór de eerste log-aanroep staan. Zie release_log_guard.dart.
    installReleaseLogGuard();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      // Geen exception-message loggen: kan PII bevatten (bv. server-response
      // met e-mailadres). Alleen exception-type + stack-trace-locatie.
      debugPrint('[FATAL] FlutterError: ${details.exception.runtimeType}');
      debugPrint('[FATAL] Stack: ${details.stack}');
    };

    GoogleFonts.config.allowRuntimeFetching = false;

    await initializeDateFormatting('nl_NL', null);

    await Supabase.initialize(
      url: StudentService.supabaseUrl,
      anonKey: StudentService.supabaseAnonKey,
      // Security (2026-09-24): sessie (access/refresh-JWT) versleuteld
      // opslaan in Keystore/Keychain i.p.v. plaintext SharedPreferences.
      // Zie secure_supabase_local_storage.dart. PKCE-flow + deep-link-
      // detectie blijven op de supabase_flutter-defaults.
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSupabaseLocalStorage(),
      ),
    );

    // Push notificaties (Fase 5) — alleen Firebase-init hier. Luisteraars,
    // permissie-aanvraag en token-registratie gebeuren pas na login (zie
    // app.dart's _AuthNotifier), niet bij eerste frame.
    try {
      await Firebase.initializeApp();
      await PushService.ensureInitialized();
    } catch (e) {
      debugPrint('[main] Firebase.initializeApp fout: $e');
    }

    runApp(
      const ProviderScope(
        child: LeerlingApp(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Supabase.instance.client.auth.currentUser != null) {
        PushService.requestPermissionAndRegister();
      }
      unawaited(PushService.handleInitialMessageIfAny());
    });
  }, (error, stack) {
    // Geen `$error` loggen: kan PII bevatten (bv. e-mailadres in
    // exception-message). Alleen runtime-type + stack (locatie, geen data).
    debugPrint('[FATAL] Uncaught error: ${error.runtimeType}');
    debugPrint('[FATAL] Stack: $stack');
  });
}
