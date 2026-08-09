import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/push_service.dart';
import 'core/services/student_service.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FATAL] FlutterError: ${details.exceptionAsString()}');
      debugPrint('[FATAL] Stack: ${details.stack}');
    };

    GoogleFonts.config.allowRuntimeFetching = false;

    await initializeDateFormatting('nl_NL', null);

    await Supabase.initialize(
      url: StudentService.supabaseUrl,
      anonKey: StudentService.supabaseAnonKey,
    );

    // Push notificaties (Fase 5) — alleen Firebase-init hier. Luisteraars,
    // permissie-aanvraag en token-registratie gebeuren pas na login (zie
    // app.dart's _AuthNotifier), niet bij eerste frame.
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[main] Firebase.initializeApp fout: $e');
    }

    runApp(
      const ProviderScope(
        child: LeerlingApp(),
      ),
    );

    // Cold start: pas ná de eerste frame + router-opbouw (voorkomt de
    // race conditie waarbij de gebruiker alleen Home ziet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.ensureInitialized();
      if (Supabase.instance.client.auth.currentUser != null) {
        PushService.requestPermissionAndRegister();
      }
      PushService.handleInitialMessageIfAny();
    });
  }, (error, stack) {
    debugPrint('[FATAL] Uncaught error: $error');
    debugPrint('[FATAL] Stack: $stack');
  });
}
