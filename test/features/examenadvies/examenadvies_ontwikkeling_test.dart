import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/examenadvies/examenadvies_data.dart';
import 'package:leerling_app/features/examenadvies/examenadvies_ontwikkeling.dart';
import 'package:leerling_app/features/examenadvies/examenadvies_sparkline.dart';

CategorieScore _cat({
  required String naam,
  required VaardigheidTrend trend,
  List<double> geschiedenis = const [],
  double? huidig,
}) {
  return CategorieScore(
    naam: naam,
    huidigOpVijf: huidig ?? (geschiedenis.isEmpty ? null : geschiedenis.last),
    trend: trend,
    geschiedenis: geschiedenis,
  );
}

ExamenadviesData _advies({
  required String ontwikkeling,
  required List<CategorieScore> categorieen,
}) {
  return ExamenadviesData(
    status: ExamenadviesStatus.nogOefenen,
    score: 50,
    heeftBetrouwbareScore: true,
    uitleg: 'test',
    sterkePunten: const [],
    nogOefenen: const [],
    ontwikkeling: ontwikkeling,
    volgendeStap: 'test',
    categorieen: categorieen,
    aantalBeoordelingen: 4,
    resterendeLessen: '',
    gebaseerdOp: const [],
  );
}

void main() {
  test('voldoende historische scores bouwen chart-data', () {
    final data = bouwOntwikkelingSparkline(_advies(
      ontwikkeling: 'Observatie is de afgelopen lessen verbeterd.',
      categorieen: [
        _cat(
          naam: 'Observatie',
          trend: VaardigheidTrend.stijgt,
          geschiedenis: const [2.1, 2.8, 3.4, 5.0],
        ),
      ],
    ));

    expect(data, isNotNull);
    expect(data!.punten, [2.1, 2.8, 3.4, 5.0]);
    expect(data.trend, VaardigheidTrend.stijgt);
    expect(data.categorie, 'Observatie');
  });

  test('geschiedenis blijft in RPC-volgorde (chronologisch)', () {
    final mapped = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 50,
      'heeftBetrouwbareScore': true,
      'uitleg': '',
      'sterkePunten': <String>[],
      'nogOefenen': <String>[],
      'ontwikkeling': 'Verkeer is de afgelopen lessen verbeterd.',
      'volgendeStap': '',
      'categorieen': [
        {
          'naam': 'Verkeer',
          'huidigOpVijf': 4.0,
          'trend': 'stijgt',
          'geschiedenis': [1, 2, 3, 4],
        },
      ],
      'aantalBeoordelingen': 4,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });

    expect(mapped.categorieen.single.geschiedenis, [1.0, 2.0, 3.0, 4.0]);
    expect(
      bouwOntwikkelingSparkline(mapped)!.punten,
      [1.0, 2.0, 3.0, 4.0],
    );
  });

  test('ontbrekende en 0-scores worden genegeerd', () {
    final mapped = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 40,
      'heeftBetrouwbareScore': true,
      'uitleg': '',
      'sterkePunten': <String>[],
      'nogOefenen': <String>[],
      'ontwikkeling': '',
      'volgendeStap': '',
      'categorieen': [
        {
          'naam': 'Gedrag',
          'huidigOpVijf': 3,
          'trend': 'stabiel',
          'geschiedenis': [0, 2, null, 3, 6],
        },
      ],
      'aantalBeoordelingen': 2,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });

    expect(mapped.categorieen.single.geschiedenis, [2.0, 3.0]);
  });

  test('onvoldoende data geeft geen fictieve chart', () {
    expect(
      bouwOntwikkelingSparkline(_advies(
        ontwikkeling: 'Nog te weinig opeenvolgende scores om een duidelijke ontwikkeling te tonen.',
        categorieen: [
          _cat(naam: 'Verkeer', trend: VaardigheidTrend.onbekend, geschiedenis: const [3.0]),
        ],
      )),
      isNull,
    );
  });

  test('stijgende trend volgt de RPC-trend, geen herberekening', () {
    final data = bouwOntwikkelingSparkline(_advies(
      ontwikkeling: 'Observatie is de afgelopen lessen verbeterd.',
      categorieen: [
        _cat(
          naam: 'Observatie',
          trend: VaardigheidTrend.stijgt,
          geschiedenis: const [2.0, 3.0, 4.0],
        ),
      ],
    ));
    expect(data!.trend, VaardigheidTrend.stijgt);
  });

  test('stabiele trend blijft stabiel', () {
    final data = bouwOntwikkelingSparkline(_advies(
      ontwikkeling: 'Nog te weinig opeenvolgende scores om een duidelijke ontwikkeling te tonen.',
      categorieen: [
        _cat(
          naam: 'Manoeuvres',
          trend: VaardigheidTrend.stabiel,
          geschiedenis: const [3.0, 3.1, 3.0],
        ),
      ],
    ));
    expect(data!.trend, VaardigheidTrend.stabiel);
  });

  test('dalende trend volgt de RPC-trend', () {
    final data = bouwOntwikkelingSparkline(_advies(
      ontwikkeling: 'Verkeer is recent gedaald. Recente lessen wegen zwaarder dan oudere hoge scores.',
      categorieen: [
        _cat(
          naam: 'Verkeer',
          trend: VaardigheidTrend.daalt,
          geschiedenis: const [5.0, 4.0, 2.0],
        ),
      ],
    ));
    expect(data!.trend, VaardigheidTrend.daalt);
    expect(data.categorie, 'Verkeer');
  });

  test('meerdere categorieën: geen gemiddelde, eerste matching trend wint', () {
    final data = bouwOntwikkelingSparkline(_advies(
      ontwikkeling:
          'Observatie, Verkeer en Wegpositie zijn de afgelopen lessen verbeterd.',
      categorieen: [
        _cat(
          naam: 'Voertuigbeheersing',
          trend: VaardigheidTrend.stabiel,
          geschiedenis: const [5.0, 5.0, 5.0],
        ),
        _cat(
          naam: 'Observatie',
          trend: VaardigheidTrend.stijgt,
          geschiedenis: const [2.0, 3.0, 4.0],
        ),
        _cat(
          naam: 'Verkeer',
          trend: VaardigheidTrend.stijgt,
          geschiedenis: const [1.0, 2.0, 3.0],
        ),
      ],
    ));

    expect(data!.categorie, 'Observatie');
    expect(data.punten, [2.0, 3.0, 4.0]);
    expect(data.punten, isNot([2.67]));
  });

  test('fromRpc isoleert alleen de payload van deze leerling', () {
    final a = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 40,
      'heeftBetrouwbareScore': true,
      'uitleg': '',
      'sterkePunten': <String>[],
      'nogOefenen': <String>[],
      'ontwikkeling': '',
      'volgendeStap': '',
      'categorieen': [
        {
          'naam': 'Observatie',
          'huidigOpVijf': 2,
          'trend': 'stijgt',
          'geschiedenis': [1, 2],
        },
      ],
      'aantalBeoordelingen': 2,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });
    final b = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 80,
      'heeftBetrouwbareScore': true,
      'uitleg': '',
      'sterkePunten': <String>[],
      'nogOefenen': <String>[],
      'ontwikkeling': '',
      'volgendeStap': '',
      'categorieen': [
        {
          'naam': 'Observatie',
          'huidigOpVijf': 5,
          'trend': 'stijgt',
          'geschiedenis': [4, 5],
        },
      ],
      'aantalBeoordelingen': 2,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });

    expect(a.categorieen.single.geschiedenis, [1.0, 2.0]);
    expect(b.categorieen.single.geschiedenis, [4.0, 5.0]);
  });

  test('refresh-mapping leest actuele geschiedenis uit een nieuwe payload', () {
    final oud = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 40,
      'heeftBetrouwbareScore': true,
      'uitleg': '',
      'sterkePunten': <String>[],
      'nogOefenen': <String>[],
      'ontwikkeling': 'Observatie is de afgelopen lessen verbeterd.',
      'volgendeStap': '',
      'categorieen': [
        {
          'naam': 'Observatie',
          'huidigOpVijf': 3,
          'trend': 'stijgt',
          'geschiedenis': [1, 2, 3],
        },
      ],
      'aantalBeoordelingen': 3,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });
    final nieuw = ExamenadviesData.fromRpc({
      'status': 'nogOefenen',
      'score': 50,
      'heeftBetrouwbareScore': true,
      'uitleg': '',
      'sterkePunten': <String>[],
      'nogOefenen': <String>[],
      'ontwikkeling': 'Observatie is de afgelopen lessen verbeterd.',
      'volgendeStap': '',
      'categorieen': [
        {
          'naam': 'Observatie',
          'huidigOpVijf': 4,
          'trend': 'stijgt',
          'geschiedenis': [2, 3, 4],
        },
      ],
      'aantalBeoordelingen': 4,
      'resterendeLessen': '',
      'gebaseerdOp': <String>[],
    });

    expect(bouwOntwikkelingSparkline(oud)!.punten, [1.0, 2.0, 3.0]);
    expect(bouwOntwikkelingSparkline(nieuw)!.punten, [2.0, 3.0, 4.0]);
  });

  testWidgets('sparkline past binnen 320px en toont categorie', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = bouwOntwikkelingSparkline(_advies(
      ontwikkeling: 'Observatie is de afgelopen lessen verbeterd.',
      categorieen: [
        _cat(
          naam: 'Observatie',
          trend: VaardigheidTrend.stijgt,
          geschiedenis: const [2.0, 3.0, 4.0],
        ),
      ],
    ));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ExamenadviesSparkline(data: data),
        ),
      ),
    ));

    expect(find.text('Observatie'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.getSize(find.byType(ExamenadviesSparkline)).width,
        lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty sparkline toont geen verzonnen grafiek', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ExamenadviesSparkline(data: null),
      ),
    ));

    expect(
      find.text('Na meerdere beoordelingen zie je hier je ontwikkeling.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('examenadvies-scherm behoudt sectievolgorde en Ontwikkeling-kaart', () {
    final bron = File('lib/features/examenadvies/examenadvies_screen.dart')
        .readAsStringSync();
    expect(bron.indexOf('_ScoreCard'), greaterThan(-1));
    expect(bron.indexOf('Waarom dit advies?'), greaterThan(bron.indexOf('_ScoreCard')));
    expect(bron.indexOf('_VaardighedenCard'),
        greaterThan(bron.indexOf('Waarom dit advies?')));
    expect(bron.indexOf('Sterkste punten'),
        greaterThan(bron.indexOf('_VaardighedenCard')));
    expect(bron.indexOf('Aandachtspunten'),
        greaterThan(bron.indexOf('Sterkste punten')));
    expect(bron.indexOf('_OntwikkelingCard'),
        greaterThan(bron.indexOf('Aandachtspunten')));
    expect(bron.indexOf('Volgende stap'),
        greaterThan(bron.indexOf('_OntwikkelingCard')));
    expect(bron.indexOf('_BasedOnCard'), greaterThan(bron.indexOf('Volgende stap')));
    expect(bron, contains('ExamenadviesSparkline'));
    expect(bron, isNot(contains('examenadvies_calculator')));
  });
}
