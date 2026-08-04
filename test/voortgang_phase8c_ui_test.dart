import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final screen = File('lib/features/voortgang/voortgang_screen.dart');
  final trendsProvider =
      File('lib/features/voortgang/voortgang_trends_provider.dart');

  String screenSource() => screen.readAsStringSync();
  String providerSource() => trendsProvider.readAsStringSync();

  group('Voortgang Fase 8C UI guards', () {
    test(
        'pakketkaart gebruikt officiele pakketvelden zonder geplande lessen op te tellen',
        () {
      final source = screenSource();

      expect(source, contains('final totaal = data.totaalLessen;'));
      expect(source, contains('data.percentageLabel'));
      expect(source,
          isNot(contains('data.afgerondeLessen + data.geplandeLessen')));
      expect(source, contains('data.nogInTePlannen'));
    });

    test('examenadvieskaart heeft titel en toont geen lokale motivatiecopy',
        () {
      final source = screenSource();

      expect(source, contains("'Examenadvies'"));
      expect(source, isNot(contains('trends.motivatieTekst')));
      expect(source, isNot(contains('Mooi! Je')));
    });

    test('competentiechips zijn vervangen door vaste progressierijen', () {
      final source = screenSource();

      expect(source, contains('class _CompetentieProgressRow'));
      expect(source, isNot(contains('class _CompetentieLegendaItem')));
      expect(source, isNot(contains('_kortLabel')));
      expect(source, isNot(contains('substring')));
      expect(source, contains("SizedBox(\n          width: 44,"));
    });

    test(
        'wat verandert er bevat geen dubbele examenadvies- of generieke adviesrij',
        () {
      final source = screenSource();
      final provider = providerSource();

      expect(source, isNot(contains('trends.lesAdvies')));
      expect(source, isNot(contains('trends.uitleg')));
      expect(provider, isNot(contains('Blijf consistent oefenen')));
      expect(provider, contains('oudeWaarde'));
      expect(provider, contains('nieuweWaarde'));
    });

    test('nederlandse datum en lesgemiddelde formatteren zonder 3.0 lessen',
        () {
      final provider = providerSource();

      expect(provider, contains('juni'));
      expect(provider, contains("replaceAll('.', ',')"));
      expect(provider, contains('lessen per week'));
      expect(provider, isNot(contains('toStringAsFixed(1)} lessen')));
    });

    test('trendkaart heeft geen misleidende lijn bij een enkel meetpunt', () {
      final source = screenSource();

      expect(source, contains('trends.scoreHistorie.length >= 2'));
      expect(source, contains('Eén meetpunt beschikbaar'));
      expect(source, isNot(contains('trends.uitleg')));
    });

    test('tijdlijn gebruikt vaste labels en opmerkingen ogen niet als knop',
        () {
      final source = screenSource();

      expect(source, contains("'Geoefend'"));
      expect(source, contains("'Opmerking'"));
      expect(source, contains('class _TijdlijnScoreRij'));
      expect(source, isNot(contains('Geoefend:')));
      expect(source, isNot(contains('FontStyle.italic')));
    });

    test('onderste content krijgt navbar en safe-area scrollruimte', () {
      final source = screenSource();

      expect(source, contains('MediaQuery.paddingOf(context).bottom + 96'));
    });
  });
}
