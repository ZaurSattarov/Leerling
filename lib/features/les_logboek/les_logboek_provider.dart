import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';
import 'les_logboek_item.dart';
import 'les_logboek_mapper.dart';

final lesLogboekProvider =
    FutureProvider.autoDispose<List<LesLogboekItem>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return const [];

  try {
    final lessen = await StudentService.getMijnVorigeLessen(
      profiel.id,
      alleenZichtbaarLogboek: true,
    );
    return lessen
        .where(
            (les) => les.status.name == 'afgerond' && les.zichtbaarVoorLeerling)
        .map(LesLogboekMapper.fromLes)
        .toList();
  } catch (_) {
    return const [];
  }
});

final laatsteLesLogboekItemProvider =
    FutureProvider.autoDispose<LesLogboekItem?>((ref) async {
  final items = await ref.watch(lesLogboekProvider.future);
  return items.isNotEmpty ? items.first : null;
});
