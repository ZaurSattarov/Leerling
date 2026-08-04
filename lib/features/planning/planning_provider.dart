import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/les.dart';
import '../../models/les_evaluatie.dart';
import '../../shared/providers/auth_provider.dart';

final komendeLessenProvider =
    FutureProvider.autoDispose<List<Les>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];

  final channel = StudentService.subscribeLessen(profiel.id, () {
    ref.invalidateSelf();
  }, channelKey: '${profiel.id}_komende');
  final notificationChannel =
      StudentService.subscribeNotificaties(profiel.id, () {
    ref.invalidateSelf();
  }, channelKey: '${profiel.id}_komende_planning');
  ref.onDispose(() => StudentService.removeChannel(channel));
  ref.onDispose(() => StudentService.removeChannel(notificationChannel));

  return StudentService.getMijnKomendeLessen(profiel.id);
});

final vorigeLessenProvider = FutureProvider.autoDispose<List<Les>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return [];

  final channel = StudentService.subscribeLessen(profiel.id, () {
    ref.invalidateSelf();
  }, channelKey: '${profiel.id}_vorige');
  final notificationChannel =
      StudentService.subscribeNotificaties(profiel.id, () {
    ref.invalidateSelf();
  }, channelKey: '${profiel.id}_vorige_planning');
  ref.onDispose(() => StudentService.removeChannel(channel));
  ref.onDispose(() => StudentService.removeChannel(notificationChannel));

  return StudentService.getMijnVorigeLessen(profiel.id);
});

final lesDetailProvider =
    FutureProvider.autoDispose.family<Les?, String>((ref, id) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel != null) {
    final channel = StudentService.subscribeLessen(profiel.id, () {
      ref.invalidateSelf();
    }, channelKey: '${profiel.id}_detail_$id');
    final notificationChannel =
        StudentService.subscribeNotificaties(profiel.id, () {
      ref.invalidateSelf();
    }, channelKey: '${profiel.id}_detail_notificaties_$id');
    ref.onDispose(() => StudentService.removeChannel(channel));
    ref.onDispose(() => StudentService.removeChannel(notificationChannel));
  }

  return StudentService.getLes(id);
});

final lesEvaluatieProvider = FutureProvider.autoDispose
    .family<LesEvaluatie?, ({String lesId, String leerlingId})>(
        (ref, args) async {
  final channel = StudentService.subscribeLessen(args.leerlingId, () {
    ref.invalidateSelf();
  }, channelKey: '${args.leerlingId}_evaluatie_${args.lesId}');
  final notificationChannel =
      StudentService.subscribeNotificaties(args.leerlingId, () {
    ref.invalidateSelf();
  }, channelKey: '${args.leerlingId}_evaluatie_notificaties_${args.lesId}');
  ref.onDispose(() => StudentService.removeChannel(channel));
  ref.onDispose(() => StudentService.removeChannel(notificationChannel));

  final raw = await StudentService.getLesEvaluatie(args.lesId, args.leerlingId);
  if (raw == null) return null;
  return LesEvaluatie.fromJson(raw);
});
