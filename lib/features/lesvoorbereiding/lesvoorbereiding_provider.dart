import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';

class LesvoorbereidingData {
  final String focus;
  final String voorbereiding;
  final List<String> tips;
  final List<String> oefenen;
  final String motivatie;
  final bool isEchteData;

  const LesvoorbereidingData({
    required this.focus,
    required this.voorbereiding,
    required this.tips,
    required this.oefenen,
    required this.motivatie,
    this.isEchteData = false,
  });
}

const _leegState = LesvoorbereidingData(
  focus: 'Nog geen advies beschikbaar',
  voorbereiding:
      'Na je eerste les met evaluatie toont je instructeur hier de voorbereiding voor de volgende les.',
  tips: [],
  oefenen: [],
  motivatie: 'Je instructeur vult dit in na elke les.',
  isEchteData: false,
);

final lesvoorbereidingProvider =
    FutureProvider.autoDispose<LesvoorbereidingData>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return _leegState;

  try {
    final eval = await StudentService.getLaatsteEvaluatie(profiel.id);
    if (eval == null) return _leegState;

    final advies = (eval['next_lesson_advice'] as String?)?.trim() ?? '';
    final focusPoints =
        List<String>.from((eval['focus_points'] as List?) ?? []);
    final feedback = (eval['feedback'] as String?)?.trim() ?? '';

    if (advies.isEmpty && focusPoints.isEmpty) return _leegState;

    final focusLabel = focusPoints.isNotEmpty
        ? focusPoints.take(2).join(', ')
        : 'Vorige les aandachtspunten';

    return LesvoorbereidingData(
      focus: focusLabel,
      voorbereiding: advies.isNotEmpty
          ? advies
          : 'Je instructeur heeft aandachtspunten ingevuld voor de volgende les.',
      tips: focusPoints,
      oefenen: focusPoints,
      motivatie: feedback.isNotEmpty
          ? feedback
          : 'Oefen de aandachtspunten van je laatste les.',
      isEchteData: true,
    );
  } catch (_) {
    return _leegState;
  }
});
