import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../examenadvies/examenadvies_provider.dart';
import '../les_logboek/les_logboek_provider.dart';

class HomeCoachData {
  final int readinessScore;
  final String status;
  final String advies;
  final String feedback;
  final List<String> laatstGeoefend;

  const HomeCoachData({
    required this.readinessScore,
    required this.status,
    required this.advies,
    required this.feedback,
    required this.laatstGeoefend,
  });
}

final homeCoachProvider = Provider<HomeCoachData>((ref) {
  final examenadvies = ref.watch(examenadviesProvider).maybeWhen(
        data: (advies) => advies,
        orElse: () => mockExamenadvies,
      );
  final laatsteLes = ref.watch(laatsteLesLogboekItemProvider).maybeWhen(
        data: (item) => item,
        orElse: () => mockLesLogboek.first,
      );

  final aandachtspunt = examenadvies.nogOefenen.isNotEmpty
      ? examenadvies.nogOefenen.first
      : mockExamenadvies.nogOefenen.first;

  return HomeCoachData(
    readinessScore: examenadvies.score,
    status: examenadvies.status,
    advies: aandachtspunt,
    feedback: laatsteLes.feedback,
    laatstGeoefend: laatsteLes.onderwerpen,
  );
});
