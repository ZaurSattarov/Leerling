# Leerlingenapp — lokale releasevoorbereiding e-mailvoorkeuren v2

Datum: 25 oktober 2026. Status: lokale voorbereiding gereed; geen build, upload,
publicatie, deployment, commit of push uitgevoerd tijdens deze voorbereiding.

## Release-inhoud en varianten

De bestaande leerlingenapp krijgt de afgeronde sectie E-mailmeldingen met 13
onafhankelijke voorkeuren, standaard uit, onder Rijlessen, Lespakketten, Voortgang
en Examens. Geen herimplementatie. Push blijft afzonderlijk bedienbaar.

Android heeft geen productFlavors; iOS gebruikt de bestaande Runner-scheme.
Leerling bij Solo en Leerling bij Team gebruiken dezelfde app en dezelfde
eigen-account-RPC. Er zijn geen afzonderlijke Solo-/Team-builds of nieuwe
abonnementsafhankelijke UI-varianten nodig. Canonical account-/schoolbinding en
RLS blijven backendverantwoordelijkheid; product_mode wordt niet uit een
abonnement afgeleid.

## Bestaand bewijs hergebruikt

- Alle 11 SHA-256-waarden uit `../../qa/email-instellingen/SOURCE-HASHES.json`
  zijn opnieuw vergeleken en gelijk. Geen brede tests opnieuw uitgevoerd.
- Bestaande 54 geslaagde Flutter-tests, gerichte analyse zonder issues en de
  geslaagde visuele controle blijven het lokale codebewijs.
- Pushservice, pushregistry, AppDelegate, dependencies en native buildconfiguratie
  zijn byte-inhoudelijk gelijk aan HEAD. Pushopslag bevat geen e-mailvelden;
  de eerdere wire-level test bewijst deze scheiding.
- Android-signingproperties, keystore, Maps-configuratie en Firebasebestand zijn
  lokaal aanwezig. Alleen aanwezigheid en ingevulde verplichte properties zijn
  gecontroleerd: geen certificaatgeldigheid, releasebuild of upload geclaimd.
- iOS Bundle ID/Firebase Bundle ID: `com.klantio.leerling`; Team ID:
  `LLTU5D46PX`. Definitieve signingcontrole/archive vereist de bestaande Mac.

Zie `RELEASE-CHECK.json` voor de uitgevoerde lokale controles en
`../../qa/email-instellingen/IMPLEMENTATIE.md` voor testinhoud en schermbeelden.

## Versie en lokale buildinstructies

Voorgestelde releasekandidaat: **1.0.2+20**. Dit is een lokale kandidaat, geen
bevestiging dat buildnummer 20 nog vrij is in beide stores. Controleer het
eerst bij de normale storevoorbereiding; kies zo nodig een hoger vrij nummer.

`pubspec.yaml` bevat nu 1.0.1+19; de bestaande gegenereerde iOS-configuratie
bevat 1.0.2+19. Pas gegenereerde bestanden niet handmatig aan. Gebruik bij de
uiteindelijke lokale builds dezelfde expliciete versieparameters, zodat Flutter
de afgeleide platformconfiguratie opnieuw consistent maakt:

```powershell
flutter build appbundle --release --build-name=1.0.2 --build-number=20
```

Op de bestaande signing-Mac:

```sh
./tooling/ios_release_preflight.sh
flutter build ipa --release --build-name=1.0.2 --build-number=20
```

Deze opdrachten zijn voorbereid, niet uitgevoerd. Gebruik daarnaast ongewijzigd
de bestaande release-omgevingsconfiguratie/dart-defines voor de huidige
loginproviders en overige integraties. Geen credentials opnemen in dit dossier.
Het bestaande iOS-preflightscript controleert signing en maakt zelf geen archive
of upload. Voer de signingcontrole opnieuw uit na versieconfiguratie als de
release-Mac daar aanvullende controles voor heeft.

## Exacte GO-volgorde

1. **Eerstvolgende GO: backend v2 installeren.** MAIL levert het definitieve
   installatievoorstel en rollback; gebruiker geeft afzonderlijk toestemming.
   De 13 optionele leerlingketens blijven UIT. De 15 actieve ketens, bestaande
   pushvoorkeuren en oudere appversies moeten behouden blijven. De client kan niet
   veilig gepubliceerd worden op basis van uitsluitend lokale SQL-tests.
2. **Gezamenlijke integratiecontrole, zonder optionele verzending.** Na de
   toegestane installatie bevestigt MAIL dat schema, RPC-grants, RLS/MFA en
   verzendcontrole op de doelomgeving gereed zijn. Controleer gericht met eigen
   accounts volgens onderstaande matrix. Geen service-role in de app. Behoud
   alle runtime-sendgates voor de 13 ketens op UIT.
3. **Afzonderlijk GO voor apppublicatie.** Alleen na geslaagde integratie,
   definitieve versienummercontrole en de normale Android/iOS-build/signing- en
   toestelcontroles. Lokale releasevoorbereiding is nu al klaar; publiceren nog
   niet vrijgegeven. TestFlight/Play-testtrack-upload is eveneens een upload en
   vereist toestemming. Commits en pushes blijven afzonderlijk niet toegestaan.
4. **Later afzonderlijk GO voor activering van de 13 ketens.** MAIL beheert dit.
   Apppublicatie of een ingeschakelde leerlingvoorkeur is op zichzelf geen
   toestemming om de serverketens te activeren.

## Gezamenlijke controle — uitsluitend nieuw integratiebewijs

| Eigen testaccount / situatie | Gerichte controle | Verwacht |
| --- | --- | --- |
| Leerling bij Solo | Laden, globale schakelaar, elk van de 13 onderwerpen aan/uit, herladen en opnieuw inloggen | Eigen opgeslagen keuzes blijven behouden; ontbrekend is uit |
| Leerling bij Team | Dezelfde handelingen binnen bestaande schoolbinding | Identieke UX; uitsluitend eigen voorkeuren |
| Accountwissel / ander account | Wissel A → B; probeer afwijkende identiteit; laat oud verzoek afronden | Geen inzage/wijziging van A via B; geen oude UI-state |
| Auth/MFA/RLS | Niet ingelogd, onvoldoende MFA waar vereist en ongeldige binding | Backend weigert; geen lokale successtatus of fallback-write |
| Globaal uit/aan | Laat enkele onderwerpen aanstaan en schakel de hoofdschakelaar uit/aan | Keuzes blijven; serverstempels worden ingetrokken/vernieuwd; geen oude mail wordt geldig |
| Nieuwe én vorige appversie | Wijzig bestaande pushkeuze; laad e-mailkeuzes opnieuw | Push werkt en e-mailtoestemming blijft behouden |
| Foutafhandeling | Gecontroleerde netwerkfout en RPC-fout met testfixture/proxy; geen productie-RPC verwijderen | Vorige UI-stand hersteld en duidelijke fout; geen directe e-mail-upsert |
| Runtime-sendgates | MAIL controleert status van de 13 en de 15 ketens | 13 UIT; 15 bestaande actief ongewijzigd; geen echte testmail zonder toestemming |

Dit zijn nog niet uitgevoerde gezamenlijke doelomgevingcontroles. Geen brede
herhaling van de geslaagde lokale suites nodig zolang hun bronhashes gelijk zijn.
Normale toestelcontrole omvat push apart van e-mail; iOS APNs/Firebase-code blijft
ongewijzigd en behoudt de bestaande guard.

## Terugval en verantwoordelijkheden

Bij een integratiefout: apppublicatie stoppen en de vorige gepubliceerde app laten
staan. MAIL houdt de 13 ketens uit en beheert zo nodig zijn goedgekeurde
backendrollback. Geen voorkeuren, serverstempels of gedeelde databasevelden vanuit
de app wissen. Bestaande 15 ketens blijven buiten de wijzigingsscope.

Backendcontract, installatie en servergates: MAIL. App-build/signing/publicatie:
normale leerlingenappreleaseprocedure, pas binnen de expliciete GO. De
backendafhankelijkheid en bovenstaande volgorde zijn aan MAIL doorgegeven.
