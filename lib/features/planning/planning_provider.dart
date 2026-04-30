import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/les.dart';
import '../../shared/providers/auth_provider.dart';

final komendeLessenProvider = FutureProvider.autoDispose<List<Les>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];
  return StudentService.getMijnKomendeLessen(profiel.id);
});

final vorigeLessenProvider = FutureProvider.autoDispose<List<Les>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];
  return StudentService.getMijnVorigeLessen(profiel.id);
});

final lesDetailProvider =
    FutureProvider.autoDispose.family<Les?, String>((ref, id) async {
  return StudentService.getLes(id);
});
