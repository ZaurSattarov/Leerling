import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/notificatie.dart';
import '../../shared/providers/auth_provider.dart';

final notificatiesProvider =
    FutureProvider.autoDispose<List<Notificatie>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return const [];

  final channel = StudentService.subscribeNotificaties(profiel.id, () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => StudentService.removeChannel(channel));

  try {
    final meldingen = await StudentService.getMijnNotificaties(profiel.id);
    debugPrint(
        '[student.notificaties.provider] backend count=${meldingen.length}');
    return meldingen;
  } catch (e) {
    debugPrint('[student.notificaties.provider] backend fout: $e');
    return const [];
  }
});

final ongelezenNotificatiesProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return 0;
  try {
    return await StudentService.getOngelezenNotificatiesAantal(profiel.id);
  } catch (_) {
    return 0;
  }
});
