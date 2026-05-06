import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';
import 'examenadvies_calculator.dart';
import 'examenadvies_data.dart';

export 'examenadvies_data.dart';

final examenadviesProvider =
    FutureProvider.autoDispose<ExamenadviesData>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return mockExamenadvies;

  try {
    final lessen = await StudentService.getMijnVorigeLessen(
      profiel.id,
      alleenZichtbaarLogboek: true,
    );
    return ExamenadviesCalculator.bereken(
      profiel: profiel,
      zichtbareAfgerondeLessen: lessen,
    );
  } catch (_) {
    return mockExamenadvies;
  }
});
