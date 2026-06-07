import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/examen.dart';
import '../../shared/providers/auth_provider.dart';

final examensProvider = FutureProvider.autoDispose<List<Examen>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];
  return StudentService.getMijnExamens(profiel.id);
});
