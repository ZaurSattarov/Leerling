# Leerlingen App - UI Regels

Visuele en code-stijl regels voor de leerlingen-app. Houd alle schermen consistent met de instructeur-app.

## Permanente UI-regels

- Roze/pink kleuren zijn verboden in knoppen, labels, borders, focus states, tekstselectie en e-mailaccenten.
- Pastelkleuren zijn verboden.
- Tekstselectie mag niet roze zijn; gebruik `AppColors.primary`.
- Primaire acties gebruiken altijd een solid SaaS-achtergrond met witte tekst.
- Focus borders, cursor, checkbox, radio en toggle active states gebruiken `AppColors.primary`.
- Alle HTML-mails moeten UTF-8 correct renderen.
- Geen gebroken tekens of mojibake in mails.
- Mailtemplates altijd testen op iPhone/Gmail.
- Gebruik geen hardgecodeerde hex-waarden in widgets; gebruik `AppColors.*`.
- SaaS-stijl aanhouden zoals de instructeur-app.

## Kleurenpalet (`AppColors`)

| Token | Hex | Gebruik |
| --- | --- | --- |
| `primary` | `#1A2332` | Knoppen, accenten, actieve states, links |
| `primaryDark` | `#111827` | Pressed/selection handle |
| `accent` | `#2563EB` | Secundair zakelijk accent |
| `surface` | `#F6F7FB` | Pagina-achtergrond |
| `white` | `#FFFFFF` | Kaarten, modals, buttontekst |
| `border` | `#E9EBF0` | Input- en kaartranden |
| `textPrimary` | `#111827` | Primaire tekst |
| `textSecondary` | `#6B7280` | Labels en subtekst |
| `textHint` | `#9CA3AF` | Placeholder tekst |
| `dangerText` | `#B91C1C` | Foutmeldingstekst |

## Knoppen

Primaire buttons:

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
  ),
  onPressed: ...,
  child: const Text('Opslaan'),
)
```

- Achtergrond: `AppColors.primary`
- Tekst: `AppColors.white`
- Loading in knoppen: `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` in `SizedBox(20x20)`

## Invoervelden en selectie

```dart
TextSelectionThemeData(
  cursorColor: AppColors.primary,
  selectionColor: AppColors.primary.withValues(alpha: 0.18),
  selectionHandleColor: AppColors.primaryDark,
)
```

- Focused border: `AppColors.primary`
- Cursor: `AppColors.primary`
- Checkbox/radio/toggle active: `AppColors.primary`
- Web `::selection`: navy achtergrond met witte tekst

## HTML-mails

- Elk HTML-bestand bevat `<meta charset="UTF-8">`.
- Mailresponses gebruiken `charset=utf-8` in headers waar van toepassing.
- Gebruik normale UTF-8 tekens of HTML entities zoals `&mdash;`, `&ndash;`, `&euro;`, `&nbsp;`.
- Controleer templates voor verzending op iPhone en Gmail.
- E-mailaccenten gebruiken `#1A2332`; geen roze of pastel accentvlakken.

## Do's and Don'ts

**DO:**
- Gebruik `AppColors.*` tokens.
- Gebruik `GoogleFonts.poppins(...)` voor tekst.
- Houd knoppen solid en zakelijk.
- Check `context.mounted` na `await`.

**DON'T:**
- Geen roze/pink/fuchsia/rose/magenta kleuren.
- Geen pastel status- of accentvlakken.
- Geen hardgecodeerde roze hexwaarden.
- Geen standaard Material primaire kleuren als accent.
- Geen gebroken encoding in mails of documentatie.
