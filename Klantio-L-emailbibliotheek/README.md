# Klantio L — 36 leerlingmails

Open **[index.html](index.html)** voor de volledige lokale catalogus met alle 36 typen. Alles staat in deze map; de voorbeelden werken zonder server of internet.

De vormgeving volgt de goedgekeurde instructeurbibliotheek: **navy #1E2635**, **accent #D72F62**, contact **info@klantio.com**, maximaal 600 px breed, duidelijke roze-rode CTA’s, rustige kaarten en de bestaande Klantio-typografie. De recentere expliciete kleurkeuzes uit de chat gaan vóór de oude kleurcodes in de mastertekst. De nieuwe leerlingillustraties hebben volledige personages met handen, benen en schoenen.

## Inhoud

| Bestand of map | Wat je vindt |
| --- | --- |
| `index.html` | 36 typen, zeven categorieën, zoekfunctie, desktop/mobiel, metadata en varianten |
| `mails/01-…` t/m `mails/36-…` | Eigen map voor elk type |
| `email.html` / `email.txt` | Herbruikbare HTML- en platteteksttemplate |
| `preview.html` / `preview.txt` | Voorbeeld met fictieve gegevens |
| `onderwerp.txt` | Nederlandse onderwerpregel |
| `voorbeeld.json` | De gebruikte voorbeeldwaarden |
| `metadata.json` | Ontvanger, variabelen, eventcontract en verificatiestatus |
| `assets/` | Tien nieuwe originele leerlingthema’s in SVG en PNG, plus bestaand Klantio-woordmerk |
| `src/email-design.mjs` | Hergebruikte gedeelde ontwerpcomponenten, aangepast voor leerlingen |
| `src/template-data.d.ts` | Getypeerd gegevenscontract voor alle 36 typen |
| `backend/` | Pure ontwikkelvoorbereiding voor policies, voorkeuren en veilig renderen |
| `voorkeuren.html` | Lokale voorkeurendemo met vijf groepen |
| `qa/` | Resultaten, screenshots, contactbladen en hashbewijs voor de ongewijzigde instructeurbibliotheek |
| `RAPPORT.md` | Compleet overzicht, bestaande bronnen en ontbrekende integratie |

Type 32 heeft afzonderlijke HTML- en tekstvarianten voor **creditnota** en **terugbetaling**. Een creditnota wordt nergens als bewijs van geldteruggave gepresenteerd. Bij type 26 feliciteren onderwerp en tekst de leerling met het geslaagde praktijkexamen; er wordt niet beweerd dat het rijbewijs al is afgegeven.

## Links, variabelen en brongegevens

Alle voorbeeldknoppen openen een lokale uitlegpagina. Dit zijn geen productieroutes. Vul de dynamische `action_url`, `website_url`, `preferences_url`, `logo_url` en `illustration_url` uitsluitend met gecontroleerde waarden. Het contactadres is vast `info@klantio.com`.

De productievoorbereiding weigert lokale links, onbekende HTTPS-hosts, ontbrekende verplichte velden en ongeldige contentvarianten. Optionele locaties/toelichtingen krijgen een heldere fallback. Alle persoonsgegevens worden voor HTML ontsnapt. De `.d.ts`-contracten beschrijven de presentatievelden; een serveradapter moet eerst de echte brondata valideren en formatteren. `formatEuro` vereist integer eurocenten en `formatMoment` vereist een ISO-tijdstip met expliciete tijdzone.

De bestaande deep link `leerlingplanner://factuur?id=…` en de bijbehorende iOS-/Android-schemaregistratie zijn lokaal aangetroffen. Dat is geen toesteltest. Andere interne routes bewijzen geen universele app-link. Er zijn daarom geen onbewezen productielinks ingevuld.

## Opnieuw bouwen en testen

```powershell
$env:KLANTIO_NODE_MODULES='C:\Users\Zaur\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
$nodeRuntime='C:\Users\Zaur\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe'
& $nodeRuntime scripts/build.mjs
& $nodeRuntime --test tests/library.test.mjs
& $nodeRuntime scripts/verify-previews.mjs
& $nodeRuntime scripts/report.mjs
```

Gebruikt: de bestaande Node.js-runtime, sharp, Playwright en Microsoft Edge. Er is geen pakket geïnstalleerd. De gebouwde catalogus kan zonder deze dependencies worden bekeken. Alle nieuwe illustraties worden uit de lokale SVG-bron gegenereerd; dit zijn getekende vectorassets, geen placeholders of stockbeelden.

## Status

**36 templatebundels en lokale preview gereed. Geen operationele nieuwe mailstroom.** Backendcode is een geteste voorbereiding, geen actieve Resend-dispatcher, duurzame outbox, scheduler of databasekoppeling. Voorkeuren worden alleen als demo in de browser bewaard, niet in het leerlingaccount. Echte stagingintegratie, inbox-tests en live-triggertests staan in het rapport als openstaand.

Geen productie-e-mails verzonden, geen databasewijzigingen, Auth-aanpassingen, Mollie-wijzigingen of wijzigingen aan push, support, Resend inbound of IMAP/SMTP. De 52 instructeurtemplates en alle andere bestaande bestanden in hun bibliotheek zijn gehasht en ongewijzigd bevonden. Alleen deze nieuwe map is toegevoegd in het Leerling-project.

Graphify/Obsidian zijn in deze sessie niet beschikbaar en conform de eerdere expliciete bypass overgeslagen; geen gebruik of synchronisatie geclaimd. Eventuele nieuwe databasewijzigingen horen uitsluitend in de canonical instructeurworkflow en vereisen vooraf expliciete goedkeuring. **Geen GO-LIVE zonder expliciete toestemming.**


## Gedeelde logo-uitlijning — 20 oktober 2026

Op expliciet gebruikersverzoek zijn het woordmerk en de rode streep in beide bibliotheken verticaal gecentreerd. De PNG heeft exact evenveel transparante ruimte boven en onder (16 bronpixels); de streep is 28 px hoog en de logoafbeelding 23 px. Gemeten visuele marge: 5,7 px boven én onder, op desktop en mobiel. Zie qa/logo-uitlijning.json. Alle bestaande basispreviews en variantscreenshots zijn vernieuwd.
