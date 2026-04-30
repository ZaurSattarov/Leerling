import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/factuur.dart';
import '../../shared/providers/auth_provider.dart';

final facturenProvider = FutureProvider.autoDispose<List<Factuur>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];
  return StudentService.getMijnFacturen(profiel.id);
});

final factuurDetailProvider =
    FutureProvider.autoDispose.family<Factuur?, String>((ref, id) async {
  return StudentService.getFactuur(id);
});
