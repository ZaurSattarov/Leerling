import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../core/utils/lespakket_detail.dart';
import '../../shared/providers/auth_provider.dart';

/// Profiel -> Rijopleiding -> Lespakket (Fase 4). Aparte provider van
/// [lespakketVoortgangProvider] (in lespakket_voortgang_provider.dart) --
/// die voedt het bestaande Voortgang-tabblad en blijft in deze fase
/// ongewijzigd. `autoDispose`: geen handmatige refresh-knop nodig om
/// wijzigingen vanuit de Instructeur-app te zien -- elke keer dat dit
/// scherm opnieuw wordt geopend (of via pull-to-refresh op Profiel, die
/// mijnProfielProvider al invalideert) haalt Riverpod een verse rij op.
final lespakketDetailProvider =
    FutureProvider.autoDispose<LespakketDetail?>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return null;

  final lessen = await StudentService.getMijnLessenVoorPakket(profiel.id);

  // Legacy-catalogusfallback: uitsluitend opvragen wanneer er nog geen
  // volledige snapshot is EN er daadwerkelijk een pakket_id is. Zodra de
  // instructeur dit pakket opnieuw opslaat (en dus een snapshot vastlegt)
  // wordt deze call vanzelf overbodig.
  final pakketId = profiel.pakketId;
  final catalogusFallback = (!profiel.heeftPakketSnapshot &&
          pakketId != null &&
          pakketId.trim().isNotEmpty)
      ? await StudentService.getMijnPakketCatalogusItem(pakketId)
      : null;

  return LespakketDetail.resolve(
    profiel: profiel,
    lessen: lessen,
    catalogusFallback: catalogusFallback,
  );
});
