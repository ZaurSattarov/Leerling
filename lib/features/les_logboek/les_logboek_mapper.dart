import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import 'les_logboek_item.dart';

class LesLogboekMapper {
  const LesLogboekMapper._();

  static LesLogboekItem fromLes(Les les) {
    final feedback = _clean(les.instructeurFeedback);

    return LesLogboekItem(
      id: les.id,
      datumLabel: _datumLabel(les.datum),
      tijdLabel: '${les.starttijd} - ${les.eindtijd}',
      instructeur: _clean(les.instructeurNaam) ?? 'Je instructeur',
      onderwerpen: les.geoefendeOnderwerpen.isEmpty
          ? const ['Nog niet vastgelegd']
          : les.geoefendeOnderwerpen,
      feedback: feedback ?? 'Nog geen feedback vastgelegd.',
      beoordeling: _beoordelingLabel(les.beoordeling) ??
          _beoordelingVoorStatus(les.status),
      leerlingNotitie: _clean(les.leerlingNotitie),
      // TODO(backend): gebruik competentie_scores voor CBR-progressie per les.
    );
  }

  static String _beoordelingVoorStatus(LesStatus status) {
    return switch (status) {
      LesStatus.afgerond => 'Afgerond',
      LesStatus.geannuleerd => 'Geannuleerd',
      LesStatus.verzet => 'Verzet',
      LesStatus.geen_toon => 'Niet verschenen',
      LesStatus.gepland => 'Gepland',
    };
  }

  static String? _beoordelingLabel(String? beoordeling) {
    return switch (_clean(beoordeling)) {
      '1' => '1 van 5',
      '2' => '2 van 5',
      '3' => '3 van 5',
      '4' => '4 van 5',
      '5' => '5 van 5',
      'onvoldoende' => 'Onvoldoende',
      'voldoende' => 'Voldoende',
      'goed' => 'Goed',
      _ => null,
    };
  }

  static String _datumLabel(String datum) {
    try {
      return DatumUtils.langeDatum(datum);
    } catch (_) {
      return datum;
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
