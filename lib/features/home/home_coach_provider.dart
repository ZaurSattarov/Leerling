import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../examenadvies/examenadvies_ontwikkeling.dart';
import '../examenadvies/examenadvies_provider.dart';
import '../les_logboek/les_logboek_provider.dart';

class HomeCoachData {
  final int? readinessScore;
  final String status;
  final String advies;
  final String feedback;
  final List<String> laatstGeoefend;
  final bool heeftData;
  final bool heeftBetrouwbareScore;
  final ExamenadviesSparklineData? ontwikkeling;

  const HomeCoachData({
    required this.readinessScore,
    required this.status,
    required this.advies,
    required this.feedback,
    required this.laatstGeoefend,
    this.heeftData = true,
    this.heeftBetrouwbareScore = false,
    this.ontwikkeling,
  });
}

const _emptyCoach = HomeCoachData(
  readinessScore: null,
  status: 'Nog onvoldoende data',
  advies: 'Volg meer lessen voor een betrouwbaar examenadvies.',
  feedback: '',
  laatstGeoefend: [],
  heeftData: false,
  heeftBetrouwbareScore: false,
);

final homeCoachProvider =
    FutureProvider.autoDispose<HomeCoachData>((ref) async {
  final examenadviesAsync = ref.watch(examenadviesProvider);
  final laatsteLesAsync = ref.watch(laatsteLesLogboekItemProvider);

  final examenadvies = examenadviesAsync.valueOrNull;
  final laatsteLes = laatsteLesAsync.valueOrNull;

  if (examenadvies == null && laatsteLes == null) return _emptyCoach;

  final aandachtspunt = examenadvies == null
      ? 'Volg meer lessen voor een betrouwbaar examenadvies.'
      : examenadvies.nogOefenen.isNotEmpty
          ? examenadvies.nogOefenen.first
          : examenadvies.volgendeStap;

  return HomeCoachData(
    readinessScore: examenadvies?.score,
    status: examenadvies?.statusLabel ?? 'Nog onvoldoende data',
    advies: aandachtspunt,
    feedback: laatsteLes?.feedback ?? '',
    laatstGeoefend: laatsteLes?.onderwerpen ?? const [],
    heeftData: (examenadvies?.heeftBetrouwbareScore ?? false) ||
        (examenadvies?.categorieen.any((c) => c.heeftData) ?? false) ||
        (laatsteLes?.feedback.isNotEmpty ?? false),
    heeftBetrouwbareScore: examenadvies?.heeftBetrouwbareScore ?? false,
    ontwikkeling: examenadvies == null
        ? null
        : bouwOntwikkelingSparkline(examenadvies),
  );
});
