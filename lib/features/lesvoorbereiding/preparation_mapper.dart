// Centrale, zuivere presentatielogica voor Lesvoorbereiding.
//
//   Les (komend) + Les-lijst (vorige) → PreparationMapper → PreparationViewModel → UI
//
// Leest UITSLUITEND bestaande, al leerling-veilige velden op het bestaande
// `Les`-model (via `student_lessen_view`, RLS al gecontroleerd):
// `beoordeling`, `competentieScores`, `focusPunten`, `instructeurFeedback`,
// `volgendeLesAdvies`. Deze kolommen worden 1-op-1 gespiegeld door de
// instructeur-RPC `rpc_les_afronden` vanuit `lesson_evaluations`/
// `lesson_skill_scores` -- dus GEEN parallel evaluatiemodel, gewoon dezelfde
// bron als "Mijn lessen"/Lesdetails al gebruiken. Verandert de instructeur
// de evaluatie, dan verandert deze data automatisch mee (zelfde provider-
// keten, zie lesvoorbereiding_provider.dart).
//
// 100% deterministisch: geen AI, geen verzonnen tekst -- alleen data die
// letterlijk is opgeslagen, plus vaste (score → label) templates.
// `notities` (interne instructeursnotitie) wordt bewust NERGENS gelezen --
// dat veld bestaat structureel niet in `student_lessen_view` en dus ook
// niet betrouwbaar op een leerling-gelezen `Les`; deze mapper raakt het
// veld ook niet aan, zelfs niet als het toevallig gezet zou zijn.

import '../../models/les.dart';

/// Vaste, canonieke vaardigheden-set + Nederlandse labels -- identiek aan
/// `_vaardigheden` in de Instructeur-app se Les Evaluatie-sheet
/// (rijschool-planner-flutter/lib/features/agenda/les_evaluatie_sheet.dart).
/// Gebruikt als (a) label-opzoeking voor score-keys en (b) stabiele
/// tiebreak-volgorde bij gelijke scores.
const List<(String key, String label)> kVaardighedenOrder = [
  ('voertuigbeheersing', 'Voertuigbeheersing'),
  ('kijkgedrag', 'Kijkgedrag'),
  ('spiegelen', 'Spiegelen'),
  ('rotondes', 'Rotondes'),
  ('parkeren', 'Parkeren'),
  ('invoegen', 'Invoegen'),
  ('verkeer', 'Verkeer'),
  ('zelfstandig_rijden', 'Zelfstandig rijden'),
];

/// Centraal, testbaar scoremodel — 1x gedefinieerd, nergens losse
/// if-statements. Puur een label per score, geen interpretatie/advies.
const Map<int, String> kScoreLabels = {
  1: 'Veel extra aandacht nodig',
  2: 'Extra aandacht',
  3: 'Verder oefenen',
  4: 'Goed',
  5: 'Sterk',
};

String scoreLabel(int score) => kScoreLabels[score] ?? '';

String skillLabel(String skillKey) {
  for (final (key, label) in kVaardighedenOrder) {
    if (key == skillKey) return label;
  }
  // Onbekende/toekomstige skill_key: toon de ruwe key leesbaar (spaties
  // i.p.v. underscores) i.p.v.'m stil te laten verdwijnen.
  return skillKey.replaceAll('_', ' ');
}

String ratingLabel(String? rating) => switch (rating) {
      'moeizaam' => 'Moeizaam',
      'voldoende' => 'Voldoende',
      'goed' => 'Goed',
      'uitstekend' => 'Uitstekend',
      _ => '',
    };

enum PreparationEmptyState {
  /// Alles beschikbaar (of gedeeltelijk) -- normale weergave.
  none,

  /// Er is een komende les, maar geen (relevante) evaluatie gevonden.
  geenEvaluatie,

  /// Geen komende les gepland -- toon dit NOOIT alsof er wél een concrete
  /// volgende afspraak is.
  geenVolgendeLes,
}

class PreparationSkillItem {
  final String skillKey;
  final String label;
  final int score;

  const PreparationSkillItem({
    required this.skillKey,
    required this.label,
    required this.score,
  });

  @override
  String toString() => 'PreparationSkillItem($label: $score)';
}

class PreparationViewModel {
  final PreparationEmptyState emptyState;
  final Les? nextLesson;

  /// Expliciet door de instructeur gekozen focuspunten (verbatim labels,
  /// geen scores) -- hoogste prioriteit, nooit gedupliceerd met scores.
  final List<String> focusItems;

  /// Zwakkere vaardigheden (score 1-2), of -- alleen als er geen enkele
  /// score ≤2 is -- score-3 als expliciete fallback (nooit verzonnen).
  /// Max. 3, laagste score eerst, deterministische tiebreak.
  final List<PreparationSkillItem> attentionItems;

  /// Label voor de attentionItems-sectie: verschilt tussen "Extra aandacht"
  /// (score ≤2) en "Verder oefenen" (score-3-fallback) zodat de kop de
  /// werkelijke score-betekenis dekt i.p.v. altijd hetzelfde te zeggen.
  final String attentionSectionLabel;

  /// Sterke vaardigheden (score 4-5). Max. 2, hoogste score eerst.
  final List<PreparationSkillItem> strongItems;

  /// "Feedback voor leerling" -- LETTERLIJK, ongewijzigd.
  final String? studentFeedback;

  /// "Voorbereiding volgende les" (volgende_les_advies) -- eveneens
  /// letterlijk door de instructeur getypt, apart van Feedback.
  final String? preparationNote;

  /// Laatste beoordeling (Moeizaam/Voldoende/Goed/Uitstekend), indien
  /// aanwezig op de brondata.
  final String? overallRating;

  /// Datum van de les waarvan deze voorbereiding is afgeleid (voor
  /// eventuele context/debug -- niet per se getoond in de UI).
  final String? sourceLessonDate;

  const PreparationViewModel({
    required this.emptyState,
    this.nextLesson,
    this.focusItems = const [],
    this.attentionItems = const [],
    this.attentionSectionLabel = 'Extra aandacht',
    this.strongItems = const [],
    this.studentFeedback,
    this.preparationNote,
    this.overallRating,
    this.sourceLessonDate,
  });

  bool get heeftInhoud =>
      focusItems.isNotEmpty ||
      attentionItems.isNotEmpty ||
      strongItems.isNotEmpty ||
      (studentFeedback?.isNotEmpty ?? false) ||
      (preparationNote?.isNotEmpty ?? false) ||
      (overallRating?.isNotEmpty ?? false);
}

/// Bouwt de [PreparationViewModel] uit de eerstvolgende geplande les
/// [nextLesson] en de (al aflopend op datum/starttijd gesorteerde) lijst
/// [previousLessons] -- exact dezelfde bron/volgorde als
/// `vorigeLessenProvider` (StudentService.getMijnVorigeLessen).
PreparationViewModel buildPreparationViewModel({
  required Les? nextLesson,
  required List<Les> previousLessons,
}) {
  if (nextLesson == null) {
    return const PreparationViewModel(
        emptyState: PreparationEmptyState.geenVolgendeLes);
  }

  final bron = _vindBronLes(nextLesson: nextLesson, previous: previousLessons);
  if (bron == null) {
    return PreparationViewModel(
      emptyState: PreparationEmptyState.geenEvaluatie,
      nextLesson: nextLesson,
    );
  }

  // Focuspunten: verbatim labels, getrimd, leeg verwijderd (Les.fromJson
  // doet dit al via _stringList), lowercased key voor dedup-vergelijking
  // met skill_keys (zelfde schrijfwijze in beide bronnen, zie
  // _focusOpties/_vaardigheden in de Instructeur-sheet).
  final focusKeys =
      bron.focusPunten.map((f) => f.trim().toLowerCase()).toSet();

  final scores = <PreparationSkillItem>[];
  bron.competentieScores?.forEach((key, waarde) {
    final score = (waarde is num) ? waarde.toInt() : null;
    if (score == null || score < 1 || score > 5) return;
    if (focusKeys.contains(key.trim().toLowerCase())) {
      return; // al als focuspunt getoond -- geen duplicaat.
    }
    scores.add(PreparationSkillItem(
      skillKey: key,
      label: skillLabel(key),
      score: score,
    ));
  });

  int stabieleVolgorde(String skillKey) {
    final index = kVaardighedenOrder.indexWhere((v) => v.$1 == skillKey);
    return index == -1 ? kVaardighedenOrder.length : index;
  }

  final zwak = scores.where((s) => s.score <= 2).toList()
    ..sort((a, b) {
      final scoreVergelijking = a.score.compareTo(b.score);
      if (scoreVergelijking != 0) return scoreVergelijking;
      return stabieleVolgorde(a.skillKey).compareTo(stabieleVolgorde(b.skillKey));
    });

  List<PreparationSkillItem> attentionItems;
  String attentionLabel;
  if (zwak.isNotEmpty) {
    attentionItems = zwak.take(3).toList();
    attentionLabel = 'Extra aandacht';
  } else {
    // Score-3-fallback: alleen wanneer er GEEN zwakke (≤2) scores zijn --
    // nooit een zwakte verzinnen, puur de bestaande "verder oefenen"-
    // score tonen.
    final middel = scores.where((s) => s.score == 3).toList()
      ..sort((a, b) =>
          stabieleVolgorde(a.skillKey).compareTo(stabieleVolgorde(b.skillKey)));
    attentionItems = middel.take(3).toList();
    attentionLabel = 'Verder oefenen';
  }

  final sterk = scores.where((s) => s.score >= 4).toList()
    ..sort((a, b) {
      final scoreVergelijking = b.score.compareTo(a.score);
      if (scoreVergelijking != 0) return scoreVergelijking;
      return stabieleVolgorde(a.skillKey).compareTo(stabieleVolgorde(b.skillKey));
    });
  final strongItems = sterk.take(2).toList();

  final feedback = bron.instructeurFeedback?.trim();
  final advies = bron.volgendeLesAdvies?.trim();
  final rating = bron.beoordeling;

  return PreparationViewModel(
    emptyState: PreparationEmptyState.none,
    nextLesson: nextLesson,
    focusItems: bron.focusPunten,
    attentionItems: attentionItems,
    attentionSectionLabel: attentionLabel,
    strongItems: strongItems,
    studentFeedback: (feedback?.isNotEmpty ?? false) ? feedback : null,
    preparationNote: (advies?.isNotEmpty ?? false) ? advies : null,
    overallRating: (rating != null && rating.isNotEmpty)
        ? ratingLabel(rating)
        : null,
    sourceLessonDate: bron.datum,
  );
}

/// Meest recente afgeronde, voor de leerling zichtbare les mét
/// evaluatie-inhoud, op of vóór de datum van [nextLesson]. [previous] is
/// al gesorteerd op datum/starttijd aflopend (nieuwste eerst), dus de
/// eerste match is per definitie de meest recente.
Les? _vindBronLes({required Les nextLesson, required List<Les> previous}) {
  for (final les in previous) {
    if (les.status != LesStatus.afgerond) continue;
    if (!les.zichtbaarVoorLeerling) continue;
    if (les.datum.compareTo(nextLesson.datum) > 0) continue;
    final heeftData = (les.beoordeling?.isNotEmpty ?? false) ||
        (les.competentieScores?.isNotEmpty ?? false) ||
        les.focusPunten.isNotEmpty ||
        (les.instructeurFeedback?.isNotEmpty ?? false) ||
        (les.volgendeLesAdvies?.isNotEmpty ?? false);
    if (!heeftData) continue;
    return les;
  }
  return null;
}
