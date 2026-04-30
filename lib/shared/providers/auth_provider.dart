import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/student_service.dart';
import '../../models/leerling_profiel.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return StudentService.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return StudentService.client.auth.currentUser;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return StudentService.client.auth.currentUser != null;
});

// Own student profile — loaded once after login
final mijnProfielProvider = FutureProvider.autoDispose<LeerlingProfiel?>((ref) {
  return StudentService.getMijnProfiel();
});
