import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/models/factuur.dart';

void main() {
  group('Factuur.fromJson factuurregels/subtotaal/BTW', () {
    test('parseert factuurregels-JSONB met dezelfde canonical sleutels', () {
      final factuur = Factuur.fromJson({
        'id': 'f1',
        'instructeur_id': 'i1',
        'leerling_id': 'l1',
        'factuurnummer': 'KLT001',
        'beschrijving': 'Rijlessen',
        'bedrag_cents': 5000,
        'subtotaal_cents': 4132,
        'btw_cents': 868,
        'status': 'betaald',
        'aangemaakt_op': '2026-08-01T00:00:00Z',
        'bijgewerkt_op': '2026-08-01T00:00:00Z',
        'factuurregels': [
          {
            'omschrijving': '1x rijles',
            'aantal': 1,
            'prijs_per_stuk_cents': 5000,
            'btw_percentage': 21,
            'totaal_cents': 5000,
            'btw_cents': 868,
          },
        ],
      });

      expect(factuur.subtotaalCents, 4132);
      expect(factuur.btwCents, 868);
      expect(factuur.factuurregels, hasLength(1));
      expect(factuur.factuurregels!.first.omschrijving, '1x rijles');
      expect(factuur.factuurregels!.first.aantal, 1);
      expect(factuur.factuurregels!.first.prijsPerStukCents, 5000);
      expect(factuur.factuurregels!.first.totaalCents, 5000);
      expect(factuur.factuurregels!.first.btwCents, 868);
    });

    test('legacy-factuur zonder factuurregels/subtotaal/BTW blijft geldig (alle null)', () {
      final factuur = Factuur.fromJson({
        'id': 'f1',
        'instructeur_id': 'i1',
        'leerling_id': 'l1',
        'factuurnummer': 'KLT001',
        'beschrijving': 'Rijlessen',
        'bedrag_cents': 5000,
        'status': 'open',
        'aangemaakt_op': '2026-08-01T00:00:00Z',
        'bijgewerkt_op': '2026-08-01T00:00:00Z',
      });

      expect(factuur.subtotaalCents, isNull);
      expect(factuur.btwCents, isNull);
      expect(factuur.factuurregels, isNull);
    });
  });
}
