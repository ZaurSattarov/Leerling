import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/notificatie.dart';
import '../../shared/providers/auth_provider.dart';

final notificatiesProvider =
    FutureProvider.autoDispose<List<Notificatie>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];
  return StudentService.getMijnNotificaties(profiel.id);
});
