import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/komende_les_filter.dart';
import '../planning/planning_provider.dart';
import 'preparation_mapper.dart';

export 'preparation_mapper.dart'
    show PreparationViewModel, PreparationEmptyState, PreparationSkillItem;

/// Leest de eerstvolgende geplande les (komendeLessenProvider) en de
/// afgeronde lessen (vorigeLessenProvider) -- BEIDE al bestaande,
/// gecentraliseerde providers (zie planning_provider.dart /
/// student_service.dart) -- en vertaalt ze via de zuivere
/// [buildPreparationViewModel] naar het viewmodel voor dit scherm.
///
/// Bewust GEEN eigen Supabase-query: dit garandeert (a) altijd dezelfde
/// "volgende les" als Home/Planning tonen (zie de Problem-1-fix in
/// student_service.dart) en (b) dat een instructeur die een evaluatie
/// aanpast automatisch doorwerkt hier, via dezelfde realtime-subscriptie
/// die vorigeLessenProvider al heeft.
final lesvoorbereidingProvider =
    FutureProvider.autoDispose<PreparationViewModel>((ref) async {
  final komendeLessen = await ref.watch(komendeLessenProvider.future);
  final vorigeLessen = await ref.watch(vorigeLessenProvider.future);

  return buildPreparationViewModel(
    nextLesson: selecteerVolgendeLes(komendeLessen, DateTime.now()),
    previousLessons: vorigeLessen,
  );
});
