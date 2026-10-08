import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/home/cbr_voorbereiding_data.dart';
import 'package:leerling_app/features/home/home_voorbereiding_carousel.dart';

Widget _bouw(String? rijbewijs) => MaterialApp(
      home:
          Scaffold(body: HomeVoorbereidingCarousel(rijbewijsSoort: rijbewijs)),
    );

void main() {
  test('A/A1/A2 = motor, AM = scooter, B en overige = auto', () {
    for (final c in ['A', 'a1', ' A2 ']) {
      expect(cbrCategorieenVoor(c), same(cbrMotorCategorieen));
    }
    for (final c in ['D', 'd1', 'DE', 'D1E']) {
      expect(cbrCategorieenVoor(c), same(cbrBusCategorieen));
    }
    expect(cbrCategorieenVoor('am'), same(cbrScooterCategorieen));
    for (final c in ['C', 'c1', 'CE', 'C1E']) {
      expect(cbrCategorieenVoor(c), same(cbrVrachtwagenCategorieen));
    }
    expect(cbrCategorieenVoor('be'), same(cbrBeCategorieen));
    expect(cbrCategorieenVoor('t'), same(cbrTrekkerCategorieen));
    for (final c in ['B', null, '']) {
      expect(cbrCategorieenVoor(c), same(cbrCategorieen));
    }
  });

  test('elke categorie heeft vragen en een bestaand fotobestand', () {
    for (final cat in [
      ...cbrCategorieen,
      ...cbrMotorCategorieen,
      ...cbrScooterCategorieen
    ]) {
      expect(cat.vragen, isNotEmpty, reason: cat.titel);
    }
  });

  test('elke set gebruikt alleen foto\'s van de eigen categorie', () {
    String naam(CbrCategorie c) => c.foto.split('/').last;
    final sets = <String, (List<CbrCategorie>, bool Function(String))>{
      'auto': (cbrCategorieen, (n) => !RegExp(r'^(m|s|v|b|be|t)_').hasMatch(n)),
      'motor': (cbrMotorCategorieen, (n) => n.startsWith('m_')),
      'scooter': (cbrScooterCategorieen, (n) => n.startsWith('s_')),
      'vrachtwagen': (cbrVrachtwagenCategorieen, (n) => n.startsWith('v_')),
      'bus': (cbrBusCategorieen, (n) => n.startsWith('b_')),
      'be': (cbrBeCategorieen, (n) => n.startsWith('be_')),
      'trekker': (cbrTrekkerCategorieen, (n) => n.startsWith('t_')),
    };
    sets.forEach((set, v) {
      for (final c in v.$1) {
        expect(v.$2(naam(c)), isTrue, reason: '$set gebruikt ${naam(c)}');
      }
    });
  });

  testWidgets('carousel toont auto- of motorcategorie op rijbewijs',
      (tester) async {
    await tester.pumpWidget(_bouw('B'));
    expect(find.text('BANDEN EN WIELEN'), findsOneWidget);
    await tester.pumpWidget(_bouw('A2'));
    expect(find.text('BANDEN'), findsOneWidget);
    expect(find.text('BANDEN EN WIELEN'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
