import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/student_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
}
