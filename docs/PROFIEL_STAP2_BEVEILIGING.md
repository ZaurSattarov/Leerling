# Fase 1 / Stap 2 — Databasebeveiliging en data-eigenaarschap `leerlingen`

> Uitgevoerd tegen het live Supabase-project `fbgjksxrehqyphaidgck` via de Management API.
> Geen Flutter-code, geen UI, geen andere tab aangepast. Geen bestaande data gewijzigd.

## 1. Welke brede rechten het probleem veroorzaakten

- RLS-policy `student_leerling_update` op `public.leerlingen`: `USING`/`WITH CHECK` controleerden
  alleen **welke rij** (`user_id = auth.uid()`), nooit **welke kolommen**.
- Column-grants: de rol `authenticated` had `UPDATE` op **alle 47 kolommen** van `leerlingen`
  (bevestigd via `information_schema.column_privileges` vóór de migratie) — inclusief `instructeur_id`,
  `school_id`, `pakket`, `lessen_gevolgd`, `status`, `user_id` zelf.
- Gevolg: een gekoppelde leerling kon met een gewone `.update()`-aanroep (buiten de Flutter-UI om, bv.
  rechtstreeks via de Supabase REST-API) elk veld van zijn eigen rij herschrijven. Empirisch bevestigd
  vóór de migratie: een gesimuleerde leerling-sessie wijzigde `pakket` in 1 rij, zonder enige blokkade.

## 2. Kolommen die de leerling nu wél mag wijzigen

| Kolom | Toelichting |
|---|---|
| `avatar_url` | Enige kolom in de whitelist — exact wat `student_service.dart` (`uploadMijnProfielfoto`) vandaag al schrijft. |

Verder niets. `avatar_id`, `telefoon`, `adres`, `geboortedatum` zijn **bewust niet** toegevoegd: er
bestaat momenteel geen leerling-UI en geen expliciete productbeslissing om die zelf te laten wijzigen
(zie `docs/PROFIEL_AUDIT.md`, actiepunt 3). Uitbreiden is later een kwestie van de `toegestane_kolommen`-
array in de trigger-functie aanvullen, in een aparte, goedgekeurde migratie.

## 3. Kolommen die nu expliciet beschermd zijn

Alle overige kolommen van `leerlingen` — inclusief maar niet beperkt tot: `id`, `user_id`,
`instructeur_id`, `school_id`, `pakket` (+ alle `pakket_*`-detailkolommen), `lessen_totaal`,
`lessen_gevolgd`, `lessen_gehad`, `lessen_tegoed`, `losse_lessen`, `losse_minuten`, `status`, `actief`,
`voornaam`, `achternaam`, `email`, `telefoon`, `adres`, `geboortedatum`, `geslacht`, `rijbewijs_soort`,
`transmissie`, `regio`, `examen_datum`, `startdatum`, `koppel_code`, `koppel_code_verloopt_op`,
`gekoppeld_op`, `notities`, `vaardigheden`, `aangemaakt_op`.

De implementatie gebruikt bewust géén opsomming van deze ~40 kolommen (fragiel bij toekomstige
`ALTER TABLE ADD COLUMN`), maar een `to_jsonb(OLD) - toegestane_kolommen` vs.
`to_jsonb(NEW) - toegestane_kolommen`-vergelijking: **alles wat niet expliciet is toegestaan is
automatisch geblokkeerd**, inclusief kolommen die in de toekomst worden toegevoegd (fail-closed).

`bijgewerkt_op` staat apart vermeld als genegeerd (niet "toegestaan om te wijzigen", maar genegeerd bij
de vergelijking) omdat een reeds bestaande trigger (`trg_leerlingen_bijgewerkt`) die kolom sowieso op elke
update overschrijft, ongeacht wat de client instuurt.

## 4. Gewijzigde RLS-policies en grants

**Geen enkele.** Bevestigd door de exacte policy- en grant-listing vóór en ná de migratie te vergelijken:
identieke 8 policies op `leerlingen`, identieke policies op `instructeur_profielen`,
`leerling_beschikbaarheid`, `leerling_notificaties`, `facturen`; identieke grant-telling
(47 kolommen × SELECT/INSERT/UPDATE/REFERENCES voor `authenticated`).

De beveiliging is uitsluitend toegevoegd via een nieuwe trigger — precies omdat een pure column-level
`REVOKE`/`GRANT` de rol `authenticated` in zijn geheel zou raken (die rol wordt door **zowel** instructeurs
**als** leerlingen gebruikt; Supabase kent geen aparte Postgres-rol per app), en dat had de instructeur-app
gebroken. Zie de uitgebreide toelichting in de migratie zelf.

## 5. Toegevoegde migratie

`supabase/migrations/20260803134500_leerling_kolombeveiliging_leerlingen.sql`

- 1 nieuwe functie: `public.enforce_leerling_zelf_update_kolommen()`
- 1 nieuwe trigger: `trg_leerlingen_zelf_update_kolommen` (BEFORE UPDATE, FOR EACH ROW, op `public.leerlingen`)
- Geen `ALTER TABLE`, geen `GRANT`/`REVOKE`, geen `DROP`/wijziging van bestaande policies, geen
  datamutaties. Idempotent (`CREATE OR REPLACE FUNCTION` + `DROP TRIGGER IF EXISTS` vóór `CREATE TRIGGER`).
- Toegepast op het live project via de Management API. Bevestigd aanwezig en correct na toepassing
  (zie testtabel).

## 6. Hoe de instructeur-app blijft werken

De trigger grijpt uitsluitend in wanneer `auth.uid() = OLD.user_id` — d.w.z. wanneer de aanroeper zelf de
aan de rij gekoppelde leerling is. Een instructeur die zijn eigen leerling beheert doet dat via
`auth.uid() = OLD.instructeur_id` (de bestaande policy `Eigen leerlingen updaten`), wat een andere
identiteit is dan `OLD.user_id` — de trigger's `IF` is dan simpelweg `false` en de update passeert
volledig ongemoeid, zoals vóór deze migratie. Empirisch bevestigd in test 10 hieronder: een instructeur
kon in één statement `pakket`, `status` én `lessen_gevolgd` van zijn eigen leerling wijzigen — precies de
combinatie die voorheen ook al werkte.

## 7. Uitgevoerde tests

Eén transactie tegen de live database, `BEGIN; ... ROLLBACK;` — niets van onderstaande is blijvend
opgeslagen. Rollen/identiteit gesimuleerd zoals PostgREST dat voor een echte request zou doen
(`SET LOCAL ROLE authenticated` + `request.jwt.claim.sub`, de exacte GUC die `auth.uid()` leest). Gebruikte
testsubjecten: twee bestaande leerlingen bij twee verschillende, bestaande instructeurs (tijdelijk
gekoppeld aan bestaande, niet eerder gekoppelde `auth.users`-accounts, uitsluitend binnen de transactie),
plus voor de koppelcode-test een throwaway `auth.users`-rij (want alle bestaande accounts in dit project
bleken al gekoppeld) — ook die is met de transactie teruggedraaid.

## 8. Resultaten

| # | Testnaam | Resultaat | Bewijs | Toelichting |
|---|---|---|---|---|
| 1 | Leerling leest eigen profiel | **GESLAAGD** | 1 rij gevonden via `SELECT ... WHERE id = leerling A` met `auth.uid()` = leerling A | Bestaande RLS-SELECT-policy, ongewijzigd — bevestigd nog correct |
| 2 | Leerling wijzigt `avatar_url` | **GESLAAGD** | 1 rij gewijzigd, `avatar_url` = `https://test.invalid/foto.jpg` | Enige toegestane kolom werkt zoals bedoeld |
| 3 | Leerling wijzigt `pakket` | **GEBLOKKEERD** | `Leerling mag alleen avatar_url van het eigen profiel wijzigen` | Trigger vangt de wijziging af, hele statement faalt |
| 4 | Leerling wijzigt `lessen_gevolgd` | **GEBLOKKEERD** | idem foutmelding | idem |
| 5 | Leerling wijzigt `status` | **GEBLOKKEERD** | idem foutmelding | idem |
| 6 | Leerling wijzigt `school_id` | **GEBLOKKEERD** | idem foutmelding | idem |
| 7 | Leerling wijzigt `instructeur_id` | **GEBLOKKEERD** | idem foutmelding | idem |
| 8 | Leerling A leest profiel leerling B | **GEBLOKKEERD** | 0 rijen zichtbaar (verwacht 0) | Bestaande RLS-SELECT-scoping, ongewijzigd — bevestigd nog correct |
| 9 | Leerling A wijzigt profiel leerling B | **GEBLOKKEERD** | 0 rijen geraakt (verwacht 0) | RLS filtert de rij al weg vóór de trigger iets ziet |
| 10 | Instructeur beheert eigen leerling volledig (pakket + status + lessen_gevolgd in 1 statement) | **GESLAAGD** | 1 rij gewijzigd, pakket → `intensief` | Bevestigt: instructeur-pad volledig ongewijzigd |
| 11 | Instructeur B beheert leerling van instructeur A (andere rijschool) | **GEBLOKKEERD** | 0 rijen geraakt (verwacht 0) | Bestaande policy `Eigen leerlingen updaten`, ongewijzigd — bevestigd nog correct |
| 12 | Koppelcode-RPC (`koppel_leerling_met_code`) blijft werken | **GESLAAGD** | `{"succes": true, "leerling_id": "..."}`, `user_id` na koppelen = het test-account | `OLD.user_id` is `NULL` op het moment van koppelen → trigger grijpt terecht niet in |
| 13 (extra) | `school_id`/`instructeur_id` van leerling A écht ongewijzigd gebleven na de blokkades 3–7 | **GESLAAGD** | voor/na identiek | Extra rigor bovenop "er kwam een foutmelding": ook de data zelf bleek intact |

**13/13 geslaagd** (12 gevraagde scenario's + 1 extra controle). Geen enkele MISLUKT.

Eén kanttekening over het testproces zelf (geen bug in de migratie): de eerste poging voor test 12 gebruikte
een willekeurig bestaand `auth.users`-account, dat toevallig al aan een andere, echte leerling gekoppeld
bleek — de RPC weigerde terecht ("account al gekoppeld"). Na het gebruik van een echt ongebruikt
(throwaway, binnen dezelfde rollback-transactie) account slaagde de test alsnog. Dit zegt niets over de
migratie, alleen over de keuze van testdata in de eerste poging.

## 9. Verificatie migratie-integriteit

| Controle | Resultaat |
|---|---|
| Trigger `trg_leerlingen_zelf_update_kolommen` aanwezig op `public.leerlingen`, BEFORE UPDATE | ✅ bevestigd |
| Functie `enforce_leerling_zelf_update_kolommen()` aanwezig, definitie exact zoals in de migratie | ✅ bevestigd |
| Overige bestaande triggers (`trg_leerlingen_bijgewerkt`, `leerling_auto_koppel_code`, `leerlingen_auto_school_id`) ongewijzigd aanwezig | ✅ bevestigd |
| RLS-policies op `leerlingen`, `instructeur_profielen`, `leerling_beschikbaarheid`, `leerling_notificaties`, `facturen` | ✅ 100% identiek aan vóór de migratie |
| Column-grants op `leerlingen` voor `authenticated` | ✅ ongewijzigd: 47 kolommen × SELECT/INSERT/UPDATE/REFERENCES |
| Bestaande data (leerling A/B/C, testdata) | ✅ 100% ongewijzigd — onafhankelijk na afloop opnieuw gecontroleerd (buiten de testtransactie) |
| Throwaway test-account (auth.users) | ✅ bevestigd niet meer aanwezig na ROLLBACK |
| Migratie succesvol uitgevoerd | ✅ HTTP 201, geen fouten |

## 10. Risico's en aandachtspunten

- **Whitelist is bewust minimaal.** Zodra er een leerling-UI komt voor bv. telefoon/adres, moet de
  `toegestane_kolommen`-array in de trigger-functie worden uitgebreid via een nieuwe, aparte migratie —
  dat gebeurt niet automatisch.
- **`fail-closed`-ontwerp**: nieuwe kolommen die later aan `leerlingen` worden toegevoegd zijn automatisch
  geblokkeerd voor leerling-zelf-update totdat ze bewust aan de whitelist worden toegevoegd. Dat is de
  bedoeling, maar betekent ook dat een toekomstige, legitieme leerling-schrijfbare kolom niet vanzelf gaat
  werken — de migratie moet er dan bewust bij.
- **`leerlingen.user_id` heeft geen UNIQUE-constraint** (alleen een FOREIGN KEY naar `auth.users`) —
  theoretisch zouden twee `leerlingen`-rijen aan hetzelfde account gekoppeld kunnen worden buiten de
  `koppel_leerling_met_code`-RPC om (die RPC controleert dat zelf wel). Dit is geen regressie van deze
  migratie en niet in scope van deze stap, maar wel het vermelden waard als apart datamodel-aandachtspunt.
- **Geen wijziging aan `anon`-rol nodig geweest** — alle bestaande policies stonden al op `roles: public`
  en zijn ongewijzigd; er is dus ook geen nieuw risico voor niet-ingelogde toegang ontstaan.

## Eindconclusie

- ✅ **Het beveiligingslek is gedicht.** Een leerling kan via geen enkel kanaal (Flutter-app, rechtstreekse
  REST-call, of anderszins) meer dan `avatar_url` van het eigen profiel wijzigen — empirisch bevestigd
  tegen de live database, niet alleen door code te lezen.
- ✅ **De Instructeur-app blijft ongewijzigd functioneren.** Leerlingbeheer, pakket koppelen, status
  wijzigen en voortgang verwerken werken exact zoals voorheen (test 10), en cross-rijschool-toegang blijft
  correct geblokkeerd (test 11) — geen van beide is aangeraakt door deze migratie.
- ✅ **De Leerlingen-app kan nu uitsluitend `avatar_url` zelf wijzigen** op het eigen profiel.
- ✅ **Alle overige officiële opleidings- en koppelgegevens** (`pakket`, `lessen_gevolgd`, `status`,
  `instructeur_id`, `school_id`, `user_id`, en alle overige kolommen) **kunnen uitsluitend nog door de
  Instructeur-app of een beveiligde `SECURITY DEFINER`-RPC gewijzigd worden.**

Bevestiging: geen UI, geen Flutter-code en geen andere tab is in deze stap aangeraakt — alleen
`supabase/migrations/20260803134500_leerling_kolombeveiliging_leerlingen.sql` is toegevoegd (nieuw
bestand) en toegepast op de live database.

Klaar voor akkoord om verder te gaan met de volgende fase van de Profiel-tab.
