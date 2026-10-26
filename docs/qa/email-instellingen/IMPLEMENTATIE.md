# E-mailmeldingen — leerlingenapp

Datum: 25 oktober 2026. Status: lokaal geïmplementeerd; geen productie-uitrol,
commits, pushes of apppublicatie. Scope: uitsluitend Leerling, Solo en Team.

## Instellingen

De bestaande route `/profiel/notificatie-instellingen` bevat onder de
pushinstellingen een sectie **E-mailmeldingen**. De bestaande Klantio-kaarten,
sectiekoppen, kleuren en FramerToggle worden hergebruikt. De volledige rij is
bedienbaar, met een schermlezerlabel en schakelstatus. Tijdens opslag zijn verdere
wijzigingen en verversen geblokkeerd. Mislukte opslag herstelt de vorige status en
toont een foutmelding.

De hoofdschakelaar staat standaard uit en selecteert geen onderwerpen bij
inschakelen. Alle dertien onderwerpkeuzes staan standaard uit. Globaal uitschakelen
bewaart de onderwerpkeuzes en schakelt hun bediening uit. Er staan geen technische
codes in de interface. Pushmeldingen blijven afzonderlijk instelbaar.

| Groep | Afzonderlijke e-mailkeuzes |
| --- | --- |
| Rijlessen | L07 ingepland; L08 verplaatst; L09 locatie gewijzigd; L10 geannuleerd; L13 andere instructeur; L14 afgerond |
| Lespakketten | L19 bijna op; L20 op |
| Voortgang | L16 nieuwe lesevaluatie |
| Examens | L22 ingepland; L23 gewijzigd; L25 resultaat beschikbaar; L26 geslaagd |

## Canonical contract en gegevensstroom

Gecontroleerd tegen het lokale definitieve contract van de centrale e-mailagent:
`Instrecteur/Klantio-emailbibliotheek/qa/master76-2026-10-25/AGENT2-VOORKEURENCONTRACT.md`.
De oude Batch20-voorbeeldpatch was alleen een globale schakelaar met gedeelde
pushonderwerpen. Het contract v2 vervangt dat voorbeeld voor de opslag.

- Bestaande tabel: `public.leerling_notificatie_voorkeuren`, eigen `user_id`.
- Laden: bestaande `StudentService.getMijnNotificatieVoorkeuren()` met SELECT op
  de huidige Auth-ID. Ontbrekende e-mailvelden geven `false` / `{}`.
- E-mailopslag: `StudentService.slaMijnEmailVoorkeurenOp()` roept uitsluitend
  `klantio_email_set_learner_preferences` aan. Hoofdschakelaar: alleen
  `p_enabled`. Onderwerpwijziging: alleen `p_topics: {Lxx: boolean}`. Dit zijn
  partiële wijzigingen; overige keuzes worden niet overschreven.
- De client stuurt geen gebruikers-ID, ontvanger, school of toestemmingsstempels
  mee. Auth-ID, MFA, canonical leerlingbinding en echte RLS worden door de
  centrale backend afgedwongen. De client controleert daarnaast de huidige
  account-ID en de account-ID in het retourantwoord.
- Het volledige RPC-retourobject is de opgeslagen waarheid. Geen directe
  e-mail-upsert, geen lokale opslagfallback bij een ontbrekende RPC of schemafout.
- Bestaande pushopslag blijft via `slaMijnNotificatieVoorkeurenOp()`. `toJson()`
  bevat uitsluitend de bestaande pushvelden; ook de eerste INSERT schrijft geen
  e-mailvelden of serverstempels. Een push-update kan e-mailtoestemming niet wissen.
- Accountwissels herladen de voorkeuren via de bestaande Auth-stream. Late
  opslagantwoorden van een eerdere providerlevenscyclus veranderen de nieuwe
  accountstate niet. Geen wijzigingen aan Auth zelf.

Geen SQL-, migratie-, worker-, outbox-, billing- of e-mailtemplatebestanden gewijzigd.

## Verificatie

Definitieve gerichte regressieset: **54 tests geslaagd**:

```powershell
flutter test --no-pub test/email_instellingen_test.dart test/email_voorkeuren_service_test.dart test/notificatie_instellingen_test.dart test/leerling_notification_preference_registry_test.dart test/profile_ui_safe_phase_test.dart
```

- Oude/missende velden geven geen toestemming; ongeldige topicwaarden activeren
  geen e-mail.
- Alle dertien onderwerpen afzonderlijk aan/uit, opslag en opnieuw ophalen.
- Globale opt-out behoudt onderwerpkeuzes, gereserveerde keys en pushinstellingen.
- Nieuwe providercontainer en logout/login/accountwissel laden de opgeslagen eigen
  voorkeuren opnieuw; late oude antwoorden worden verworpen.
- Wire-level controle van RPC-pad en partiële parameters; geen identiteit of
  serverstempels in e-mailparameters; geen e-mailvelden in push-upserts.
- Eerste record gebruikt alleen eigen pushdefaults; geen verzoek zonder ingelogde
  leerling of bij een afwijkend model-userId.
- Ontbrekende RPC (`PGRST202`), schemafout (`42703`), autorisatie/MFA-fout
  (`42501`) en ongeldige wijziging (`22023`) geven geen fallback-write.
- Zichtbare opslagfout met rollback; bediening geblokkeerd tijdens een verzoek.
- Alle labels/onderwerpen zichtbaar zonder technische codes; geen layoutoverloop
  bij 320 px en 130% tekstschaal.
- Bestaande pushregistry en profielregressies blijven slagen.

Gerichte Flutter-analyse: **No issues found**. `git diff --check` geslaagd.
Dependencies zijn uitsluitend offline uit de bestaande pub-cache hersteld;
`pubspec.yaml` en `pubspec.lock` zijn ongewijzigd.

De servicetests gebruiken synthetische accounts en een lokale HTTP-fixture met
het echte Supabase-clientpad. Deze bewijzen geen live RLS of productieopslag.
Er zijn geen echte e-mails verstuurd en geen productiegegevens gewijzigd.

De werkelijke Flutter-widgets zijn daarnaast op 390 × 844 gerenderd met lokaal
geladen Inter- en CoolIcons-lettertypen. Schermbeelden:

- [E-mail en rijlessen](email-rijlessen.png)
- [Lespakketten, voortgang en examens](email-overige-groepen.png)

## Release en overdracht

De lokale leerlingenappimplementatie is klaar voor de normale releaseprocedure.
Publicatie vereist eerst afgestemde backendinstallatie van contract v2 en een
gezamenlijke integratiecontrole met eigen leerlingaccounts, inclusief opnieuw
inloggen, autorisatie en opslagfouten. Zonder dat contract faalt opslag zichtbaar;
de UI claimt geen geslaagde opslag en activeert geen alternatieve opslagroute.
Voor deployment/publicatie/commits/pushes blijft expliciete toestemming nodig.

De officiële incrementele Graphify-update via `tools/update_graphify.cmd` is
uitgevoerd. `graph.json` is geldig en bevat de nieuwe e-mailregistrynode. De
lopende Graphify MCP-server houdt de oude index nog in het geheugen; herstart of
herlaad `graphify-leerling` om de nieuwe nodes via MCP op te vragen. De bestaande
HTML is behouden omdat de updater bij meer dan 5000 nodes geen nieuwe HTML maakt.

Obsidian-context is lokaal gelezen omdat Obsidian MCP niet beschikbaar is.
De vault is niet aangepast om binnen de opgedragen leerlingenappscope te blijven.
Te synchroniseren kennis voor de centrale agent: contract v2 is aangesloten in de
leerlingenapp, push/e-mail blijven gescheiden, lokale tests slagen, release wacht
op afgestemde backendinstallatie en integratiecontrole.
