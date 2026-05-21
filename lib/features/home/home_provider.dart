import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';
import '../../models/notificatie.dart';
import '../../shared/providers/auth_provider.dart';
import '../notificaties/notificaties_provider.dart';

class HomeData {
  final Les? volgendeLes;
  final List<Factuur> openFacturen;
  final int ongelezenNotificaties;
  final List<Notificatie> recenteNotificaties;

  const HomeData({
    this.volgendeLes,
    required this.openFacturen,
    required this.ongelezenNotificaties,
    required this.recenteNotificaties,
  });

  int get openFacturenBedragCents =>
      openFacturen.fold(0, (sum, f) => sum + f.bedragCents);

  bool get heeftOpenFacturen => openFacturen.isNotEmpty;
  bool get heeftVolgendeLes => volgendeLes != null;
}

final homeProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) throw StateError('Leerlingprofiel ontbreekt');

  final data =
      await StudentService.getHomeDashboard(profiel.id, profiel.instructeurId);

  final recenteNotificaties = data['recenteNotificaties'] as List<Notificatie>;
  final fallbackNotificaties = mockNotificaties();
  final zichtbareNotificaties = recenteNotificaties.isEmpty
      ? fallbackNotificaties.take(3).toList()
      : recenteNotificaties;

  return HomeData(
    volgendeLes: data['volgendeLes'] as Les?,
    openFacturen: data['openFacturen'] as List<Factuur>,
    ongelezenNotificaties: recenteNotificaties.isEmpty
        ? fallbackNotificaties.where((n) => !n.gelezen).length
        : data['ongelezenNotificaties'] as int,
    recenteNotificaties: zichtbareNotificaties,
  );
});
