import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../examenadvies/examenadvies_provider.dart';
import '../les_logboek/les_logboek_provider.dart';

class HomeCoachData {
  final int readinessScore;
  final String status;
  final String advies;
  final String feedback;
  final List<String> laatstGeoefend;
  final bool heeftData;

  const HomeCoachData({
    required this.readinessScore,
    required this.status,
    required this.advies,
    required this.feedback,
    required this.laatstGeoefend,
    this.heeftData = true,
  });
}

const _emptyCoach = HomeCoachData(
  readinessScore: 0,
  status: 'Nog onvoldoende data',
  advies: 'Volg meer lessen voor gepersonaliseerd advies.',
  feedback: '',
  laatstGeoefend: [],
  heeftData: false,
);

final homeCoachProvider =
    FutureProvider.autoDispose<HomeCoachData>((ref) async {
  final examenadviesAsync = ref.watch(examenadviesProvider);
  final laatsteLesAsync = ref.watch(laatsteLesLogboekItemProvider);

  final examenadvies = examenadviesAsync.valueOrNull;
  final laatsteLes = laatsteLesAsync.valueOrNull;

  if (examenadvies == null && laatsteLes == null) return _emptyCoach;

  final aandachtspunt =
      (examenadvies != null && examenadvies.nogOefenen.isNotEmpty)
          ? examenadvies.nogOefenen.first
          : 'Volg meer lessen voor gepersonaliseerd advies.';

  return HomeCoachData(
    readinessScore: examenadvies?.score ?? 0,
    status: examenadvies?.status ?? 'Nog onvoldoende data',
    advies: aandachtspunt,
    feedback: laatsteLes?.feedback ?? '',
    laatstGeoefend: laatsteLes?.onderwerpen ?? const [],
    heeftData: (examenadvies?.score ?? 0) > 0 ||
        (laatsteLes?.feedback.isNotEmpty ?? false),
  );
});
