import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
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

    runApp(
      const ProviderScope(
        child: LeerlingApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('[FATAL] Uncaught error: $error');
    debugPrint('[FATAL] Stack: $stack');
  });
}
