import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';
import 'examenadvies_data.dart';

export 'examenadvies_data.dart';

final examenadviesProvider =
    FutureProvider.autoDispose<ExamenadviesData>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return emptyExamenadvies;

  try {
    return await StudentService.getExamenadvies(profiel.id);
  } catch (_) {
    return emptyExamenadvies;
  }
});
