import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';
import 'examenadvies_calculator.dart';
import 'examenadvies_data.dart';

export 'examenadvies_data.dart';

final examenadviesProvider =
    FutureProvider.autoDispose<ExamenadviesData>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return emptyExamenadvies;

  try {
    // Probeer eerst de gecachte examenreadiness (bijgewerkt door instructeur)
    final cached = await StudentService.getExamReadiness(profiel.id);
    if (cached != null) {
      final score = (cached['readiness_score'] as num? ?? 0).toInt();
      final statusLabel =
          (cached['status_label'] as String?) ?? 'Nog onvoldoende data';
      final strengths =
          List<String>.from((cached['strengths'] as List?) ?? []);
      final weaknesses =
          List<String>.from((cached['weaknesses'] as List?) ?? []);
      final recommendation =
          (cached['recommendation'] as String?) ?? '';
      final lastFeedback = (cached['last_feedback'] as String?) ?? '';

      if (score > 0) {
        return ExamenadviesData(
          score: score,
          status: statusLabel,
          uitleg: lastFeedback.isNotEmpty
              ? lastFeedback
              : _uitlegVoorScore(score),
          sterkePunten: strengths.isNotEmpty
              ? strengths
              : _sterkePuntenVoorScore(score),
          nogOefenen: weaknesses.isNotEmpty
              ? weaknesses
              : _nogOefenenVoorScore(score),
          resterendeLessen: recommendation.isNotEmpty
              ? recommendation
              : _resterendeVoorScore(score),
          gebaseerdOp: const [
            'Gevolgde lessen',
            'Vaardigheidsscores',
            'Beoordelingen',
            'Ingrepen',
          ],
          scoreOnderdelen: _scoreOnderdelenVoorScore(score),
        );
      }
    }

    // Fallback: berekening uit afgeronde lessen via student_lessen_view
    final lessen = await StudentService.getMijnVorigeLessen(
      profiel.id,
      alleenZichtbaarLogboek: true,
    );
    return ExamenadviesCalculator.bereken(
      profiel: profiel,
      zichtbareAfgerondeLessen: lessen,
    );
  } catch (_) {
    return emptyExamenadvies;
  }
});

String _uitlegVoorScore(int score) {
  if (score >= 80) {
    return 'Je rijdt op meerdere onderdelen stabiel genoeg voor het examen.';
  }
  if (score >= 65) {
    return 'Je bent goed op weg, maar een paar onderdelen moeten nog consistenter worden.';
  }
  if (score >= 40) {
    return 'De basis wordt opgebouwd. Focus op vaste routines en controle.';
  }
  return 'Meer lessen en gerichte oefening zijn nodig voor examenadvies.';
}

List<String> _sterkePuntenVoorScore(int score) {
  if (score >= 65) {
    return [
      'Je voertuigbeheersing verbetert duidelijk.',
      'Je past je rijgedrag aan de situatie aan.',
    ];
  }
  return [];
}

List<String> _nogOefenenVoorScore(int score) {
  if (score < 65) {
    return [
      'Blijf oefenen op zelfstandig rijden.',
      'Werk aan kijkgedrag en dode hoek.',
    ];
  }
  return [];
}

String _resterendeVoorScore(int score) {
  if (score >= 85) return 'Waarschijnlijk nog enkele lessen tot examenadvies';
  if (score >= 65) return 'Nog ongeveer 4–6 lessen tot examenadvies';
  if (score >= 40) return 'Nog ongeveer 8–12 lessen tot examenadvies';
  return 'Volg meer lessen voor een nauwkeurige schatting';
}

List<ScoreOnderdeel> _scoreOnderdelenVoorScore(int score) {
  return [
    ScoreOnderdeel(
      naam: 'Totaalscore',
      score: score.toDouble(),
      gewicht: 1.0,
      teltMee: true,
      scoreLabel: '$score% gemiddeld',
      uitleg:
          'Gewogen gemiddelde van lesvoortgang, vaardigheidsscores en beoordelingen.',
    ),
  ];
}
