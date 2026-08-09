// Widget tests voor LesvoorbereidingScreen -- de UI zelf bevat geen
// businessregels (die zitten in preparation_mapper.dart, apart getest);
// hier wordt uitsluitend geverifieerd dat elke PreparationViewModel-vorm
// correct en zonder crash wordt weergegeven, inclusief de empty states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leerling_app/features/lesvoorbereiding/lesvoorbereiding_provider.dart';
import 'package:leerling_app/features/lesvoorbereiding/lesvoorbereiding_screen.dart';
import 'package:leerling_app/models/les.dart';

Les _nextLesson() => const Les(
      id: 'komend-1',
      instructeurId: 'instr-1',
      leerlingId: 'leerling-1',
      datum: '2026-08-20',
      starttijd: '21:00',
      eindtijd: '22:00',
      duurMinuten: 60,
      status: LesStatus.gepland,
      aangemaaktOp: '2026-01-01T00:00:00Z',
      bijgewerktOp: '2026-01-01T00:00:00Z',
    );

Widget _bouwScherm(PreparationViewModel vm) {
  return ProviderScope(
    overrides: [
      lesvoorbereidingProvider.overrideWith((ref) async => vm),
    ],
    child: const MaterialApp(home: LesvoorbereidingScreen()),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Empty states', () {
    testWidgets('F: geen volgende les -> passende melding, geen crash',
        (tester) async {
      await tester.pumpWidget(_bouwScherm(
        const PreparationViewModel(
            emptyState: PreparationEmptyState.geenVolgendeLes),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nog geen volgende les gepland'), findsOneWidget);
    });

    testWidgets('A: wel volgende les, geen evaluatie -> juiste melding + '
        'les-context blijft zichtbaar', (tester) async {
      await tester.pumpWidget(_bouwScherm(
        PreparationViewModel(
          emptyState: PreparationEmptyState.geenEvaluatie,
          nextLesson: _nextLesson(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nog geen voorbereiding beschikbaar'), findsOneWidget);
      expect(find.text('21:00 – 22:00'), findsOneWidget);
    });
  });

  group('Volledige inhoud', () {
    testWidgets('toont focus, aandacht, sterk, feedback, advies en '
        'beoordeling, geen duplicatie', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_bouwScherm(
        PreparationViewModel(
          emptyState: PreparationEmptyState.none,
          nextLesson: _nextLesson(),
          focusItems: const ['spiegelen', 'rotondes'],
          attentionItems: const [
            PreparationSkillItem(
                skillKey: 'parkeren', label: 'Parkeren', score: 2),
          ],
          strongItems: const [
            PreparationSkillItem(
                skillKey: 'kijkgedrag', label: 'Kijkgedrag', score: 5),
          ],
          studentFeedback: 'Kijk eerder in je spiegels voordat je afslaat.',
          preparationNote: 'Oefen komende les vooral invoegen op de snelweg.',
          overallRating: 'Goed',
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Spiegelen'), findsOneWidget);
      expect(find.text('Rotondes'), findsOneWidget);
      expect(find.text('Parkeren'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
      expect(find.text('Kijkgedrag'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      expect(find.textContaining('Kijk eerder in je spiegels'), findsOneWidget);
      expect(find.textContaining('invoegen op de snelweg'), findsOneWidget);
      expect(find.text('Goed'), findsOneWidget);

      // Spiegelen staat als focuspunt maar NIET nogmaals als los
      // scorepunt/attention-item -- geen dubbele vermelding.
      expect(find.text('Spiegelen'), findsOneWidget);
    });

    testWidgets('gedeeltelijke data: alleen focuspunten -> geen lege '
        'feedback-/adviescard', (tester) async {
      await tester.pumpWidget(_bouwScherm(
        PreparationViewModel(
          emptyState: PreparationEmptyState.none,
          nextLesson: _nextLesson(),
          focusItems: const ['parkeren'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Parkeren'), findsOneWidget);
      expect(find.text('Feedback van je instructeur'), findsNothing);
      expect(find.text('Voorbereiding volgende les'), findsNothing);
      expect(find.text('LAATSTE BEOORDELING'), findsNothing);
    });
  });

  group('Responsief / geen overflow', () {
    testWidgets('geen RenderFlex-overflow op een klein scherm met volledige '
        'inhoud', (tester) async {
      tester.view.physicalSize = const Size(750, 1334); // 375x667 @2x
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_bouwScherm(
        PreparationViewModel(
          emptyState: PreparationEmptyState.none,
          nextLesson: _nextLesson(),
          focusItems: const ['spiegelen', 'rotondes', 'parkeren'],
          attentionItems: const [
            PreparationSkillItem(
                skillKey: 'invoegen', label: 'Invoegen', score: 2),
            PreparationSkillItem(
                skillKey: 'verkeer', label: 'Verkeer', score: 2),
          ],
          strongItems: const [
            PreparationSkillItem(
                skillKey: 'kijkgedrag', label: 'Kijkgedrag', score: 5),
            PreparationSkillItem(
                skillKey: 'voertuigbeheersing',
                label: 'Voertuigbeheersing',
                score: 4),
          ],
          studentFeedback:
              'Een lange stuk feedbacktekst om te controleren of dit netjes '
              'blijft passen zonder overflow op een klein scherm.',
          preparationNote: 'Voorbereiding voor de volgende les, ook lang.',
          overallRating: 'Uitstekend',
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
