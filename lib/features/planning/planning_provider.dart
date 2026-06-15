import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/les.dart';
import '../../models/les_evaluatie.dart';
import '../../shared/providers/auth_provider.dart';

final komendeLessenProvider = FutureProvider.autoDispose<List<Les>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];

  final channel = StudentService.subscribeLessen(profiel.id, () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => StudentService.removeChannel(channel));

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

final lesEvaluatieProvider = FutureProvider.autoDispose
    .family<LesEvaluatie?, ({String lesId, String leerlingId})>(
        (ref, args) async {
  final raw = await StudentService.getLesEvaluatie(args.lesId, args.leerlingId);
  if (raw == null) return null;
  return LesEvaluatie.fromJson(raw);
});
