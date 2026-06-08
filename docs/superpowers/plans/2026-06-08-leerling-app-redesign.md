# Leerling App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Volledig visueel redesign van de Leerling app naar Clean & Minimal stijl met rood (#D63060) + dark navy (#0F1629) als brand kleuren.

**Architecture:** Wijzigingen zijn puur UI/visueel — geen providers, geen logica, geen routing aanraken. Shared widgets (app_card, coach_widgets) worden eerst aangepast zodat alle schermen automatisch profiteren. Daarna per scherm van boven naar beneden.

**Tech Stack:** Flutter, Dart, Material 3, AppColors constants

---

## Bestanden die worden gewijzigd

| Bestand | Wat verandert |
|---------|--------------|
| `lib/shared/widgets/app_card.dart` | Radius 16, betere schaduw, SectionHeader actielink zwart |
| `lib/shared/widgets/coach_widgets.dart` | InlineCtaLink kleur zwart |
| `lib/core/constants/app_colors.dart` | Semantische icoonkleuren toevoegen als constants |
| `lib/features/home/home_screen.dart` | Semantische iconkleuren, cleaner cards |
| `lib/features/planning/planning_screen.dart` | Cleaner les cards, "Nieuwe les" knop solid |
| `lib/features/voortgang/voortgang_screen.dart` | Competentie kleuren, trend cards verbeteren |
| `lib/features/facturen/facturen_screen.dart` | Header patroon aligned, cleaner summary |
| `lib/features/profiel/profiel_screen.dart` | Semantische iconkleuren per actie |

---

## Task 1: Shared Widgets — AppCard & SectionHeader

**Files:**
- Modify: `lib/shared/widgets/app_card.dart`

- [ ] **Stap 1: AppCard radius en schaduw updaten**

```dart
// In AppCard.build() — vervang BoxDecoration:
decoration: BoxDecoration(
  color: backgroundColor ?? AppColors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.border, width: 0.75),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ],
),
```

En de InkWell borderRadius ook naar 16:
```dart
borderRadius: BorderRadius.circular(16),
```

- [ ] **Stap 2: SectionHeader actielink zwart maken**

```dart
// Vervang de GestureDetector child in SectionHeader:
GestureDetector(
  onTap: onAction,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        action!,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 2),
      const Icon(Icons.arrow_forward_rounded,
          size: 14, color: AppColors.textPrimary),
    ],
  ),
),
```

- [ ] **Stap 3: IconBadge radius proportioneel**

```dart
// In IconBadge.build():
decoration: BoxDecoration(
  color: const Color(0xFFF0F2F5),
  borderRadius: BorderRadius.circular(size * 0.28),
),
```

- [ ] **Stap 4: Commit**
```
git add lib/shared/widgets/app_card.dart
git commit -m "redesign: AppCard radius 16, schaduw, SectionHeader zwarte actielink"
```

---

## Task 2: Coach Widgets — InlineCtaLink

**Files:**
- Modify: `lib/shared/widgets/coach_widgets.dart`

- [ ] **Stap 1: InlineCtaLink foregroundColor zwart**

```dart
// In InlineCtaLink.build() — vervang styleFrom:
style: TextButton.styleFrom(
  foregroundColor: AppColors.textPrimary,
  padding: EdgeInsets.zero,
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  textStyle: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
),
```

- [ ] **Stap 2: Commit**
```
git add lib/shared/widgets/coach_widgets.dart
git commit -m "redesign: InlineCtaLink kleur zwart per design regels"
```

---

## Task 3: AppColors — Semantische Icoonkleuren

**Files:**
- Modify: `lib/core/constants/app_colors.dart`

- [ ] **Stap 1: Semantische icoonkleuren toevoegen**

Voeg onderaan de `AppColors` class toe (vóór de sluitende `}`):

```dart
// Semantische icoonkleuren (voor IconBadge color parameter)
static const Color iconPurple = Color(0xFF5645D4);   // planning, focus, voorbereiding
static const Color iconBlue = Color(0xFF2563EB);     // logboek, info, agenda
static const Color iconGreen = Color(0xFF16A34A);    // voortgang, succes, betaald
static const Color iconAmber = Color(0xFFD97706);    // waarschuwingen, examens
static const Color iconRed = Color(0xFFE11D48);      // openstaand, annulering
static const Color iconSlate = Color(0xFF64748B);    // neutraal, systeem
```

- [ ] **Stap 2: Commit**
```
git add lib/core/constants/app_colors.dart
git commit -m "redesign: semantische icoonkleur constants toegevoegd"
```

---

## Task 4: Home Screen Redesign

**Files:**
- Modify: `lib/features/home/home_screen.dart`

- [ ] **Stap 1: _LaatsteLesLogboekCard icoon blauw**

```dart
// In _LaatsteLesLogboekCard.build():
const IconBadge(
  icon: Icons.history_edu_rounded,
  color: AppColors.iconBlue,
  size: 40,
),
```

- [ ] **Stap 2: _LesvoorbereidingCard icoon paars**

```dart
// In _LesvoorbereidingCard.build():
const IconBadge(
  icon: Icons.center_focus_strong_rounded,
  color: AppColors.iconPurple,
  size: 40,
),
```

- [ ] **Stap 3: Voortgang kaart icoon groen**

```dart
// In HomeScreen.build() — zoek de voortgang IconBadge:
const IconBadge(
  icon: Icons.bar_chart_rounded,
  color: AppColors.iconGreen,
),
```

- [ ] **Stap 4: _VolgendeLesCard — date block cleaner**

```dart
// In _VolgendeLesCard.build() — vervang de leading Container (52x52):
Container(
  width: 54,
  height: 54,
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  ),
  child: const Icon(Icons.directions_car_rounded,
      color: Colors.white, size: 26),
),
```

- [ ] **Stap 5: _NotificatieCard — sluit aan op semantische kleuren**

```dart
// _color getter in _NotificatieCard — voortgang/examenadvies:
case 'voortgang':
case 'examenadvies':
  return AppColors.iconGreen;
// les/planning:
case 'les':
case 'les_reminder':
case 'lesson_planned':
case 'lesson_changed':
  return AppColors.iconBlue;
// voorbereiding:
case 'voorbereiding':
  return AppColors.iconPurple;
// factuur:
case 'factuur':
case 'invoice_created':
case 'package_almost_empty':
  return AppColors.iconAmber;
// feedback/betaald:
case 'feedback':
case 'lesson_feedback':
case 'invoice_paid':
  return AppColors.iconGreen;
```

- [ ] **Stap 6: _CoachReadinessCard — subtiele verbetering padding/spacing**

```dart
// In _CoachReadinessCard — vervang de outer Container decoration:
decoration: BoxDecoration(
  color: AppColors.dark,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ],
),
```

- [ ] **Stap 7: Commit**
```
git add lib/features/home/home_screen.dart
git commit -m "redesign: home screen semantische iconkleuren en card verbeteringen"
```

---

## Task 5: Planning Screen Redesign

**Files:**
- Modify: `lib/features/planning/planning_screen.dart`

- [ ] **Stap 1: _NieuweLesButton — solid primary knop**

```dart
// Vervang de volledige _NieuweLesButton.build():
@override
Widget build(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => context.go('/beschikbaarheid'),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Nieuwe les aanvragen'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
```

- [ ] **Stap 2: _LesCard date blok cleaner styling**

```dart
// In _LesCard.build() — vervang de datum Container (62x80):
Container(
  width: 60,
  height: 76,
  decoration: BoxDecoration(
    color: isNext ? AppColors.primary : AppColors.dark,
    borderRadius: BorderRadius.circular(14),
    boxShadow: isNext
        ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
        : null,
  ),
  child: Column( /* zelfde inhoud */ ),
),
```

- [ ] **Stap 3: Commit**
```
git add lib/features/planning/planning_screen.dart
git commit -m "redesign: planning screen nieuwe les knop solid, datum blok cleaner"
```

---

## Task 6: Voortgang Screen Redesign (body — header/footer/radar ongewijzigd)

**Files:**
- Modify: `lib/features/voortgang/voortgang_screen.dart`

- [ ] **Stap 1: _CompetentieCard — semantische iconkleur per competentie index**

```dart
// Voeg bovenaan voortgang_screen.dart toe (na de imports):
const List<Color> _competentieKleuren = [
  Color(0xFF2563EB),  // Voertuig — blauw
  Color(0xFF5645D4),  // Kijkgedrag — paars
  Color(0xFF16A34A),  // Verkeer — groen
  Color(0xFFD97706),  // Bijzonder — amber
  Color(0xFFE11D48),  // Zelfstandig — rood
  Color(0xFF0891B2),  // Examen — cyaan
];
```

Dan in `_CompetentieCard.build()`, vervang `IconBadge`:
```dart
// Voeg index toe als parameter aan _CompetentieCard:
// class _CompetentieCard extends StatelessWidget {
//   final _CompetentieScore score;
//   final int index;  // NIEUW
//   const _CompetentieCard({required this.score, required this.index});

IconBadge(
  icon: Icons.adjust_rounded,
  color: _competentieKleuren[index % _competentieKleuren.length],
  size: 38,
),
```

En in de SliverList waar competentie kaarten worden gebouwd, voeg index toe:
```dart
...competentieScores.asMap().entries.map(
  (entry) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: _CompetentieCard(score: entry.value, index: entry.key),
  ),
),
```

- [ ] **Stap 2: _DezeWeekCard — icoon paars i.p.v. primary**

```dart
// In _DezeWeekCard.build() — vervang de leading Container (42x42):
Container(
  width: 42,
  height: 42,
  decoration: BoxDecoration(
    color: const Color(0xFFF0F2F5),
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Icon(Icons.auto_awesome_rounded,
      color: Color(0xFF5645D4), size: 20),
),
```

- [ ] **Stap 3: _TrendSamenvattingCard — betere mini-stats styling**

```dart
// In _MiniStat.build() — verbeter achtergrond:
decoration: BoxDecoration(
  color: const Color(0xFFF8F9FA),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.border),
),
```

- [ ] **Stap 4: Commit**
```
git add lib/features/voortgang/voortgang_screen.dart
git commit -m "redesign: voortgang screen semantische kleuren competenties, betere cards"
```

---

## Task 7: Facturen Screen Redesign

**Files:**
- Modify: `lib/features/facturen/facturen_screen.dart`

- [ ] **Stap 1: Header aligned met andere schermen (FACTUREN label + titel)**

```dart
// Vervang de SliverAppBar flexibleSpace:
flexibleSpace: const FlexibleSpaceBar(
  titlePadding: EdgeInsets.fromLTRB(20, 0, 64, 16),
  title: _ScreenHeader(label: 'FACTUREN', title: 'Mijn facturen'),
),
```

Voeg `_ScreenHeader` widget toe onderaan het bestand:
```dart
class _ScreenHeader extends StatelessWidget {
  final String label;
  final String title;
  const _ScreenHeader({required this.label, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Stap 2: _SummaryCard — bedrag prominenter, cleaner layout**

```dart
// Vervang de volledige _SummaryCard.build():
@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.dark,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$openAantal openstaande factuur${openAantal > 1 ? 'en' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _bedragEuro,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'Betalen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Stap 3: _FactuurCard icoonkleur op status**

```dart
// In _FactuurCard.build() — IconBadge color verbeteren:
IconBadge(
  icon: Icons.receipt_long_rounded,
  color: factuur.status == FactuurStatus.betaald
      ? AppColors.iconGreen
      : factuur.isVerlopen
          ? AppColors.iconRed
          : factuur.status == FactuurStatus.geannuleerd
              ? AppColors.iconSlate
              : AppColors.iconAmber,
),
```

- [ ] **Stap 4: Commit**
```
git add lib/features/facturen/facturen_screen.dart
git commit -m "redesign: facturen screen header aligned, summary card donker, semantische icoonkleuren"
```

---

## Task 8: Profiel Screen Redesign

**Files:**
- Modify: `lib/features/profiel/profiel_screen.dart`

- [ ] **Stap 1: _ActionTile icoonkleuren semantisch**

```dart
// In ProfielScreen.build() — vervang alle _ActionTile iconColor:

// Beschikbaarheid → paars
_ActionTile(
  icon: Icons.schedule_outlined,
  iconColor: AppColors.iconPurple,
  label: 'Mijn beschikbaarheid',
  onTap: () => context.push('/beschikbaarheid'),
),

// Meldingen → primary rood
_ActionTile(
  icon: Icons.notifications_outlined,
  iconColor: AppColors.primary,
  label: 'Meldingen',
  onTap: () => context.go('/notificaties'),
),

// Examens → amber
_ActionTile(
  icon: Icons.quiz_outlined,
  iconColor: AppColors.iconAmber,
  label: 'Mijn examens',
  onTap: () => context.push('/examens'),
),

// Help → blauw
_ActionTile(
  icon: Icons.help_outline_rounded,
  iconColor: AppColors.iconBlue,
  label: 'Help & ondersteuning',
  onTap: () => context.push('/help'),
),

// Uitloggen → rood (ongewijzigd)
_ActionTile(
  icon: Icons.logout_rounded,
  iconColor: AppColors.dangerSolid,
  label: 'Uitloggen',
  labelColor: AppColors.dangerText,
  onTap: () => _uitloggen(context, ref),
),
```

- [ ] **Stap 2: _InfoTile icoonkleuren semantisch**

```dart
// Telefoon → blauw
_InfoTile(
  icon: Icons.phone_outlined,
  iconColor: AppColors.iconBlue,
  label: 'Telefoon',
  value: profiel.telefoon!,
),

// Geboortedatum → paars
_InfoTile(
  icon: Icons.cake_outlined,
  iconColor: AppColors.iconPurple,
  label: 'Geboortedatum',
  value: profiel.geboortedatum!,
),

// Status → groen
_InfoTile(
  icon: Icons.school_outlined,
  iconColor: AppColors.iconGreen,
  label: 'Status',
  value: profiel.status.label,
),
```

- [ ] **Stap 3: Rijschool kaart icoonkleuren**

```dart
// Instructeur/rijschool icoon → primary
const IconBadge(
  icon: Icons.directions_car_rounded,
  color: AppColors.primary,
),

// Adres → slate
_InfoTile(
  icon: Icons.location_on_outlined,
  iconColor: AppColors.iconSlate,
  label: 'Adres',
  value: instructeur.volledigAdres!,
),

// Email → blauw (ongewijzigd — was al infoSolid)
_InfoTile(
  icon: Icons.email_outlined,
  iconColor: AppColors.iconBlue,
  label: 'E-mail',
  value: instructeur.email!,
),
```

- [ ] **Stap 4: App versieregel onderaan verbeteren**

```dart
// Vervang de laatste Center Text:
const Center(
  child: Text(
    'Instrecteur Leerling · v1.0',
    style: TextStyle(fontSize: 11, color: AppColors.textHint),
  ),
),
```

- [ ] **Stap 5: Commit**
```
git add lib/features/profiel/profiel_screen.dart
git commit -m "redesign: profiel screen semantische iconkleuren per actie"
```

---

## Verificatie Checklist

Na alle taken:

- [ ] `flutter analyze` — geen nieuwe warnings
- [ ] `flutter build apk --debug` — compileert zonder fouten
- [ ] Controleer visueel op device/emulator:
  - Home: semantische icoonkleuren zichtbaar
  - Planning: "Nieuwe les aanvragen" knop is solid rood
  - Voortgang: elke competentie heeft andere kleur
  - Facturen: dark summary card + FACTUREN label in header
  - Profiel: elke actie tile heeft eigen icoonkleur
- [ ] Geen Engelse tekst zichtbaar in UI
- [ ] Actielinks zijn zwart (niet roze)
- [ ] Header/footer/radar chart ongewijzigd
