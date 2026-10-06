# Klantio Leerling — logo en app-iconen

Logo: concept "Behaald". Drie witte blokken (de basis: instructeur, lessen, oefening), één roze
blok (de leerling) en een wit hoekje in dat roze blok (het doel: het rijbewijs).
Kleuren: achtergrond `#1C2636`, wit `#FFFFFF`, Klantio-roze `#D72F62`.

Deze map wordt NIET in de app gebundeld (staat niet in `pubspec.yaml`); het zijn de bronbestanden.

## Inhoud
- `svg/` — vector-masters: app-icoon, logo op donker, logo op licht, volledig wit
- `master/` — 1024 px app-icoon, transparant logo, wit logo
- `ios/AppIcon.appiconset/` — alle iPhone-, iPad- en App Store-maten (staat al in
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- `android/res/` — legacy, rond, adaptive (voorgrond) en monochroom (Android 13+) in alle
  dichtheden (staat al in `android/app/src/main/res/mipmap-*`). In het project gebruikt de
  adaptive icon `@color/launcher_icon_background` (`#1C2636`) uit `values/colors.xml`; het
  bestand `android/res/values/ic_launcher_background.xml` hier is alleen voor losse export.
- `android/play-store-icon-512.png` — voor de Google Play Console
- `splash-preview.html` — bewegend ontwerpvoorbeeld van het splash screen

De losse delen van het merkteken voor de splash-animatie staan in `assets/Splash Screen/`
(`leerling_mark_*.svg`, allemaal op hetzelfde 256x256-canvas).

## Opnieuw genereren
`python3 build_assets.py` vanuit deze map (vereist Pillow). Schrijft `ios/`, `android/` en `master/`.
