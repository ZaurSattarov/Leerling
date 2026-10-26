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
    rethrow;
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

/// Id's van meldingen waarvan de les niet meer bestaat. Alleen gevuld als de
/// controle zeker is: bij een offline- of laadfout blijft de set leeg, zodat
/// er nooit ten onrechte 'Les verwijderd' wordt getoond.
final verwijderdeLesMeldingenProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final meldingen = await ref.watch(notificatiesProvider.future);
  final perLes = <String, List<String>>{};
  for (final n in meldingen) {
    final lesId = n.lesId;
    if (lesId != null) (perLes[lesId] ??= []).add(n.id);
  }
  if (perLes.isEmpty) return const <String>{};
  try {
    final bestaand = await StudentService.bestaandeLesIds(perLes.keys.toSet());
    return {
      for (final e in perLes.entries)
        if (!bestaand.contains(e.key)) ...e.value,
    };
  } catch (e) {
    debugPrint('[student.notificaties.provider] lescontrole mislukt: $e');
    return const <String>{};
  }
});
