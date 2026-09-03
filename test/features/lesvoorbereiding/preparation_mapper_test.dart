// Unit tests voor PreparationMapper -- de centrale, deterministische
// vertaling van bestaande evaluatiedata (op Les, via student_lessen_view)
// naar de Lesvoorbereiding-viewmodel. Dekt exact de 13 verplichte
// testcases uit de opdracht.

import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/lesvoorbereiding/preparation_mapper.dart';
import 'package:leerling_app/models/les.dart';

Les _nextLesson({String datum = '2026-08-27'}) => Les(
      id: 'komend-1',
      instructeurId: 'instr-1',
      leerlingId: 'leerling-1',
      datum: datum,
      starttijd: '21:00',
      eindtijd: '22:00',
      duurMinuten: 60,
      status: LesStatus.gepland,
      aangemaaktOp: '2026-01-01T00:00:00Z',
      bijgewerktOp: '2026-01-01T00:00:00Z',
    );

Les _afgerondeLes({
  String id = 'vorige-1',
  String datum = '2026-08-20',
  String starttijd = '20:00',
  String eindtijd = '21:00',
  String leerlingId = 'leerling-1',
  bool zichtbaar = true,
  Map<String, dynamic>? competentieScores,
  List<String> focusPunten = const [],
  String? feedback,
  String? advies,
  String? beoordeling,
  String? notities, // interne instructeursnotitie -- mag NOOIT in de output
}) =>
    Les(
      id: id,
      instructeurId: 'instr-1',
      leerlingId: leerlingId,
      datum: datum,
      starttijd: starttijd,
      eindtijd: eindtijd,
      duurMinuten: 60,
      status: LesStatus.afgerond,
      zichtbaarVoorLeerling: zichtbaar,
      competentieScores: competentieScores,
      focusPunten: focusPunten,
      instructeurFeedback: feedback,
      volgendeLesAdvies: advies,
      beoordeling: beoordeling,
      notities: notities,
      aangemaaktOp: '2026-01-01T00:00:00Z',
      bijgewerktOp: '2026-01-01T00:00:00Z',
    );

void main() {
  group('1. Kijkgedrag=5, Spiegelen=2', () {
    test('Spiegelen -> attention, Kijkgedrag -> strong', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(
            competentieScores: {'kijkgedrag': 5, 'spiegelen': 2},
          ),
        ],
      );
      expect(vm.attentionItems.map((s) => s.skillKey), ['spiegelen']);
      expect(vm.strongItems.map((s) => s.skillKey), ['kijkgedrag']);
    });
  });

  group('2. Spiegelen als focuspunt + score 2', () {
    test('Spiegelen alleen bij focus, geen duplicaat bij attention', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(
            focusPunten: const ['spiegelen'],
            competentieScores: {'spiegelen': 2},
          ),
        ],
      );
      expect(vm.focusItems, ['spiegelen']);
      expect(vm.attentionItems, isEmpty);
    });
  });

  group('3. Parkeren=1, Spiegelen=2, Rotondes=2, Invoegen=2, Kijkgedrag=5', () {
    test('maximaal 3 attention-items, score 1 eerst, deterministisch', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(competentieScores: {
            'parkeren': 1,
            'spiegelen': 2,
            'rotondes': 2,
            'invoegen': 2,
            'kijkgedrag': 5,
          }),
        ],
      );
      expect(vm.attentionItems.length, 3);
      expect(vm.attentionItems.first.skillKey, 'parkeren');
      expect(vm.attentionItems.first.score, 1);
      // Score-2 items volgen in de vaste _vaardigheden-volgorde: spiegelen
      // (index 2) vóór rotondes (index 3) vóór invoegen (index 5).
      expect(vm.attentionItems.map((s) => s.skillKey).toList(),
          ['parkeren', 'spiegelen', 'rotondes']);
    });
  });

  group('4. Alle vaardigheden = 5', () {
    test('geen extra aandacht, maximaal 2 sterke punten', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(competentieScores: {
            for (final v in kVaardighedenOrder) v.$1: 5,
          }),
        ],
      );
      expect(vm.attentionItems, isEmpty);
      expect(vm.strongItems.length, 2);
      expect(vm.strongItems.every((s) => s.score == 5), isTrue);
    });
  });

  group('5. Alle vaardigheden = 3', () {
    test('geen verzonnen conclusies, score-3-fallback gebruikt', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(competentieScores: {
            'kijkgedrag': 3,
            'spiegelen': 3,
          }),
        ],
      );
      expect(vm.strongItems, isEmpty);
      expect(vm.attentionSectionLabel, 'Verder oefenen');
      expect(vm.attentionItems, isNotEmpty);
      expect(vm.attentionItems.every((s) => s.score == 3), isTrue);
    });
  });

  group('6. Geen scores, wel focuspunten', () {
    test('focus wordt gewoon getoond', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(focusPunten: const ['rotondes', 'parkeren']),
        ],
      );
      expect(vm.focusItems, ['rotondes', 'parkeren']);
      expect(vm.attentionItems, isEmpty);
      expect(vm.strongItems, isEmpty);
    });
  });

  group('7. Geen focus, wel feedback', () {
    test('feedback wordt getoond', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(feedback: 'Kijk eerder in je spiegels.'),
        ],
      );
      expect(vm.studentFeedback, 'Kijk eerder in je spiegels.');
      expect(vm.focusItems, isEmpty);
    });
  });

  group('8. Geen feedback', () {
    test('geen lege feedback -- studentFeedback is null', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(focusPunten: const ['rotondes']),
        ],
      );
      expect(vm.studentFeedback, isNull);
    });
  });

  group('9. Geen evaluatie', () {
    test('correcte empty state', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: const [],
      );
      expect(vm.emptyState, PreparationEmptyState.geenEvaluatie);
      expect(vm.heeftInhoud, isFalse);
    });
  });

  group('10. Geen volgende les', () {
    test('correcte no-next-lesson state, geen les-context', () {
      final vm = buildPreparationViewModel(
        nextLesson: null,
        previousLessons: [_afgerondeLes(feedback: 'Prima gedaan!')],
      );
      expect(vm.emptyState, PreparationEmptyState.geenVolgendeLes);
      expect(vm.nextLesson, isNull);
      expect(vm.studentFeedback, isNull);
    });
  });

  group('11. Interne instructeursnotitie', () {
    test('verschijnt nooit in het viewmodel', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(
            feedback: 'Openbare feedback.',
            notities: 'GEHEIME INTERNE NOTITIE -- niet voor leerling',
          ),
        ],
      );
      final serialized = [
        vm.studentFeedback,
        vm.preparationNote,
        vm.overallRating,
        vm.focusItems.join(),
        vm.attentionItems.map((s) => s.toString()).join(),
        vm.strongItems.map((s) => s.toString()).join(),
      ].join();
      expect(serialized, isNot(contains('GEHEIME')));
      expect(serialized, isNot(contains('INTERNE NOTITIE')));
    });
  });

  group('12. Twee evaluaties aanwezig', () {
    test(
        'meest recente geldige afgeronde evaluatie vóór de komende les '
        'wordt gebruikt', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(datum: '2026-08-27'),
        previousLessons: [
          // Al gesorteerd datum/starttijd aflopend, zoals
          // getMijnVorigeLessen() teruggeeft.
          _afgerondeLes(
            id: 'meest-recent',
            datum: '2026-08-20',
            feedback: 'Nieuwste feedback.',
          ),
          _afgerondeLes(
            id: 'ouder',
            datum: '2026-08-13',
            feedback: 'Oudere feedback.',
          ),
        ],
      );
      expect(vm.studentFeedback, 'Nieuwste feedback.');
      expect(vm.sourceLessonDate, '2026-08-20');
      expect(vm.sourceLesson?.id, 'meest-recent');
      expect(vm.sourceLesson?.starttijd, '20:00');
      expect(vm.sourceLesson?.eindtijd, '21:00');
      expect(vm.nextLesson?.id, 'komend-1');
    });

    test('wanorde in de lijst gebruikt nog steeds de nieuwste geldige les', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(datum: '2026-08-27'),
        previousLessons: [
          _afgerondeLes(
            id: 'ouder',
            datum: '2026-08-13',
            advies: 'Oude voorbereiding',
          ),
          _afgerondeLes(
            id: 'meest-recent',
            datum: '2026-08-20',
            advies: 'Oefenen met fileparkeren',
          ),
        ],
      );
      expect(vm.preparationNote, 'Oefenen met fileparkeren');
      expect(vm.sourceLessonDate, '2026-08-20');
    });

    test(
        'een les NA de komende les wordt genegeerd (zou niet moeten '
        'voorkomen, maar mapper is defensief)', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(datum: '2026-08-10'),
        previousLessons: [
          _afgerondeLes(datum: '2026-08-15', feedback: 'Te laat.'),
          _afgerondeLes(datum: '2026-08-05', feedback: 'Op tijd.'),
        ],
      );
      expect(vm.studentFeedback, 'Op tijd.');
    });
  });

  group('13. Datum/timezone (komende les)', () {
    test(
        'nextLesson wordt ongewijzigd doorgegeven aan het viewmodel '
        '(zelfde bron als Home/Planning, zie komende_les_filter_test.dart)',
        () {
      final les = _nextLesson(datum: '2026-08-27');
      final vm = buildPreparationViewModel(
        nextLesson: les,
        previousLessons: const [],
      );
      expect(vm.nextLesson, same(les));
      expect(vm.nextLesson!.datum, '2026-08-27');
      expect(vm.nextLesson!.starttijd, '21:00');
    });
  });

  group('Extra: niet-zichtbare / niet-afgeronde lessen worden overgeslagen',
      () {
    test('een gepland-status-les in de "vorige" lijst wordt genegeerd', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          Les(
            id: 'raar-gepland',
            instructeurId: 'instr-1',
            leerlingId: 'leerling-1',
            datum: '2026-08-24',
            starttijd: '10:00',
            eindtijd: '11:00',
            duurMinuten: 60,
            status: LesStatus.gepland,
            instructeurFeedback: 'zou niet moeten tellen',
            aangemaaktOp: '2026-01-01T00:00:00Z',
            bijgewerktOp: '2026-01-01T00:00:00Z',
          ),
          _afgerondeLes(feedback: 'echte feedback'),
        ],
      );
      expect(vm.studentFeedback, 'echte feedback');
    });

    test(
        'een afgeronde les die niet zichtbaarVoorLeerling is, wordt '
        'genegeerd', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(
              zichtbaar: false, feedback: 'niet zichtbaar dus niet tonen'),
          _afgerondeLes(feedback: 'wel zichtbaar'),
        ],
      );
      expect(vm.studentFeedback, 'wel zichtbaar');
    });
  });

  group('Rating / algemene beoordeling', () {
    test('overallRating vertaalt de opgeslagen rating-code naar het label', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [_afgerondeLes(beoordeling: 'goed')],
      );
      expect(vm.overallRating, 'Goed');
    });

    test('overallRating is de les-rating, niet een vaardigheidsscore', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(
            beoordeling: 'goed',
            competentieScores: {'kijkgedrag': 1, 'spiegelen': 1},
          ),
        ],
      );
      expect(vm.overallRating, 'Goed');
      expect(vm.attentionItems.every((s) => s.score != 5), isTrue);
      expect(vm.attentionItems.map((s) => s.score), everyElement(1));
    });
  });

  group('Leerling-scope', () {
    test('evaluatie van een andere leerling wordt genegeerd', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(),
        previousLessons: [
          _afgerondeLes(
            id: 'andere-leerling',
            leerlingId: 'leerling-ANDERS',
            feedback: 'Hoort niet bij deze leerling.',
            beoordeling: 'uitstekend',
          ),
          _afgerondeLes(
            id: 'eigen-les',
            feedback: 'Wel van deze leerling.',
          ),
        ],
      );
      expect(vm.studentFeedback, 'Wel van deze leerling.');
      expect(vm.sourceLesson?.id, 'eigen-les');
      expect(vm.sourceLesson?.leerlingId, 'leerling-1');
    });
  });

  group('Zelfde dag, latere starttijd wint', () {
    test('selectie gebruikt datum + starttijd, niet lijstvolgorde', () {
      final vm = buildPreparationViewModel(
        nextLesson: _nextLesson(datum: '2026-08-27'),
        previousLessons: [
          _afgerondeLes(
            id: 'ochtend',
            datum: '2026-08-20',
            starttijd: '09:00',
            eindtijd: '10:00',
            feedback: 'Ochtendles',
          ),
          _afgerondeLes(
            id: 'avond',
            datum: '2026-08-20',
            starttijd: '22:30',
            eindtijd: '23:15',
            feedback: 'Avondles',
          ),
        ],
      );
      expect(vm.sourceLesson?.id, 'avond');
      expect(vm.sourceLesson?.starttijd, '22:30');
      expect(vm.studentFeedback, 'Avondles');
    });
  });
}
