import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  group('Planning premium sync guards', () {
    test('planning gebruikt een gedeelde leskaart en statusbadge', () {
      final source = read('lib/features/planning/planning_screen.dart');

      expect(source, contains('class _LessonCard'));
      final badge =
          read('lib/features/planning/widgets/lesson_status_badge.dart');

      expect(source, contains('LessonStatusBadge'));
      expect(badge, contains('class LessonStatusBadge'));
      expect(source, isNot(contains('class _VolgendeBadge')));
      expect(source, isNot(contains('StatusPill.les')));
    });

    test(
        'lijstkaart gebruikt lestype als titel en toont duur alleen in metadata',
        () {
      final source = read('lib/features/planning/planning_screen.dart');

      expect(source, contains('String get titelLabel'));
      expect(source, contains('return \'Rijles\';'));
      expect(source, contains('DatumUtils.duurLabel(les.duurMinuten)'));
      expect(source, contains('tekst: DatumUtils.duurLabel(les.duurMinuten)'));
      expect(source, isNot(contains('Text(DatumUtils.duurLabel')));
      expect(source, isNot(contains('geoefendeOnderwerpen.join(\' · \')')));
    });

    test('nieuwe les blijft een beschikbaarheidsaanvraag', () {
      final source = read('lib/features/planning/planning_screen.dart');

      expect(source, contains('Nieuwe les aanvragen'));
      expect(source, contains("context.push('/beschikbaarheid')"));
      expect(source, isNot(contains(".from('lessen').insert")));
      expect(source, isNot(contains(".from('lessen').update")));
    });

    test('komende vorige detail en evaluatie verversen via bestaande realtime',
        () {
      final provider = read('lib/features/planning/planning_provider.dart');
      final service = read('lib/core/services/student_service.dart');

      expect(provider, contains('komende_planning'));
      expect(provider, contains('vorige_planning'));
      expect(provider, contains('detail_notificaties'));
      expect(provider, contains('evaluatie_notificaties'));
      expect(service, contains('channelKey'));
      expect(service, contains("table: 'lessen'"));
      expect(service, contains("table: 'leerling_notificaties'"));
    });

    test('planning houdt ruimte vrij voor bottom nav en safe area', () {
      final source = read('lib/features/planning/planning_screen.dart');

      expect(source, contains('MediaQuery.paddingOf(context).bottom'));
      expect(source, contains('96 + safeBottom'));
    });

    test('detail gebruikt centrale badge en echte leerlingstatussen', () {
      final detail = read('lib/features/planning/les_detail_screen.dart');
      final badge =
          read('lib/features/planning/widgets/lesson_status_badge.dart');

      expect(detail, contains('LessonStatusBadge(status: les.status)'));
      expect(detail, isNot(contains('StatusPill.les')));
      expect(detail, isNot(contains("'Onderweg'")));
      expect(detail, isNot(contains("'Gestart'")));
      expect(badge, contains("label: 'Gepland'"));
      expect(badge, contains("label: 'Afgerond'"));
      expect(badge, contains("label: 'Volgende'"));
      expect(badge, contains('forceStrutHeight: true'));
      expect(badge, isNot(contains('toUpperCase()')));
    });

    test('detail toont duur compact en niet als tweede losse regel', () {
      final detail = read('lib/features/planning/les_detail_screen.dart');
      final datum = read('lib/core/utils/datum_utils.dart');

      expect(detail, contains(r'${les.starttijd} - ${les.eindtijd}'));
      expect(detail, isNot(contains('color: AppColors.textHint')));
      expect(datum, contains(r'$uren uur'));
      expect(datum, isNot(contains(r'$uren u ')));
    });

    test('locatie en contact blijven leerlingvriendelijk en brongetrouw', () {
      final detail = read('lib/features/planning/les_detail_screen.dart');

      expect(detail, contains("label: 'Ophaallocatie'"));
      expect(detail, contains(r"locatie.replaceAll(RegExp(r',\s*'), '\n')"));
      expect(detail, contains("Uri.encodeComponent(locatie)"));
      expect(detail, isNot(contains('Exact ophaaladres')));
      expect(detail, contains("label: 'Bellen'"));
      expect(detail, contains("label: 'WhatsApp'"));
      expect(detail, contains("label: 'E-mail'"));
      expect(detail, contains('class _ContactActiesCard'));
      expect(detail, contains("Uri(scheme: 'tel'"));
      expect(detail, contains("Uri.https('wa.me'"));
      expect(detail, contains("scheme: 'mailto'"));
      expect(detail, contains('Vraag over mijn rijles'));
      expect(detail, contains('_isValidEmail'));
      expect(detail, contains('constraints.maxWidth >= 320'));
    });

    test('voertuigdetail toont alleen bestaande snapshot/viewvelden', () {
      final detail = read('lib/features/planning/les_detail_screen.dart');
      final model = read('lib/models/les.dart');

      expect(detail, contains("'Lesvoertuig'"));
      expect(detail, contains('les.voertuigNaam'));
      expect(detail, contains('les.voertuigMerk'));
      expect(detail, contains('les.voertuigModel'));
      expect(detail, contains('les.voertuigKenteken'));
      expect(detail, contains('les.voertuigTransmissie'));
      expect(detail, contains('les.voertuigCategorie'));
      expect(detail, isNot(contains('Geen voertuig gekozen')));
      expect(detail, isNot(contains("from('vehicles')")));
      expect(detail, isNot(contains('matchVoertuigVoorLes')));
      expect(model, contains('voertuig_naam'));
      expect(model, contains('voertuig_categorie'));
      expect(model, isNot(contains('voertuig_kleur')));
    });

    test('geplande lesdetail toont geen losse volgende-les-cta', () {
      final detail = read('lib/features/planning/les_detail_screen.dart');

      expect(detail, contains('les.status == LesStatus.afgerond'));
      expect(detail, contains("context.push('/beschikbaarheid')"));
      expect(detail, contains('Nieuwe les aanvragen'));
      expect(detail, contains('Evaluatie nog niet beschikbaar'));
      expect(detail, isNot(contains('les.status == LesStatus.gepland) ...[')));
      expect(detail, isNot(contains('Volgende les aanvragen')));
    });
  });
}
