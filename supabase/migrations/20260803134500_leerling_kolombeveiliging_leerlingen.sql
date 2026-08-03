-- ============================================================================
-- Fase 1 / Stap 2 -- kolombeveiliging op public.leerlingen
-- ============================================================================
-- Aanleiding: docs/PROFIEL_AUDIT.md constateerde dat een gekoppelde leerling
-- (auth.uid() = leerlingen.user_id) via de bestaande RLS-policy
-- "student_leerling_update" (USING/WITH CHECK: user_id = auth.uid()) elke
-- kolom van zijn eigen rij kan wijzigen -- ook instructeur_id, school_id,
-- pakket, lessen_gevolgd, status, user_id zelf, etc. RLS beperkt alleen
-- WELKE RIJ een rol mag aanraken, niet welke KOLOMMEN.
--
-- Waarom geen pure column-level GRANT (de eerst voor de hand liggende optie):
-- in dit schema is er maar één Postgres-rol voor alle ingelogde gebruikers
-- ("authenticated") -- zowel instructeurs als leerlingen zijn "authenticated".
-- GRANT/REVOKE UPDATE (kolom) ON leerlingen TO authenticated geldt voor de
-- HELE rol, ongeacht welke rij. Een leerling-only kolombeperking via GRANT
-- zou dus automatisch OOK de instructeur blokkeren om leerlinggegevens te
-- beheren (pakket koppelen, status wijzigen, voortgang verwerken) -- dat is
-- expliciet verboden ("bestaande instructeur-app niet breken"). Een RPC-only
-- aanpak voor de leerling zou daarnaast vereisen dat de Instructeur-app
-- óók wordt omgebouwd naar een RPC (rechtstreekse update() moet dan verboden
-- worden voor iedereen) -- dat raakt een andere app/repository en valt
-- buiten deze stap.
--
-- Gekozen aanpak: een BEFORE UPDATE-trigger die ALLEEN ingrijpt wanneer de
-- aanroeper zelf de aan de rij gekoppelde leerling is (auth.uid() =
-- OLD.user_id). In dat exacte geval wordt elke kolomwijziging buiten de
-- expliciete whitelist geblokkeerd. Instructeur-updates (auth.uid() =
-- OLD.instructeur_id, of via de school-relatie) EN vertrouwde
-- SECURITY DEFINER-RPC's zoals koppel_leerling_met_code (die user_id zet
-- terwijl OLD.user_id nog NULL is) lopen hier nooit tegenaan, omdat
-- auth.uid() dan niet gelijk is aan OLD.user_id. RLS-policies, bestaande
-- triggers (trg_leerlingen_bijgewerkt, leerling_auto_koppel_code,
-- leerlingen_auto_school_id) en grants blijven ongewijzigd.
--
-- Whitelist (kolommen die de leerling zelf mag wijzigen): uitsluitend
-- avatar_url -- dit is het enige veld dat de huidige Leerling-app-code
-- (student_service.dart -> uploadMijnProfielfoto) daadwerkelijk schrijft.
-- avatar_id, telefoon, adres en geboortedatum zijn BEWUST nog niet
-- toegevoegd: er bestaat vandaag geen UI en geen expliciete productbeslissing
-- om leerlingen die velden zelf te laten wijzigen (zie docs/PROFIEL_AUDIT.md,
-- actiepunt 3). Uitbreiden van de whitelist is een kwestie van deze array
-- aanvullen in een latere, apart goedgekeurde migratie -- geen architectuur-
-- wijziging.
--
-- Idempotent: CREATE OR REPLACE FUNCTION en DROP TRIGGER IF EXISTS + CREATE
-- TRIGGER zijn veilig herhaalbaar. Wijzigt geen bestaande rijen, verwijdert
-- niets.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_leerling_zelf_update_kolommen()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  -- Kolommen die de leerling zelf mag wijzigen op zijn eigen rij.
  toegestane_kolommen text[] := ARRAY['avatar_url'];
  -- Kolommen die genegeerd worden bij de vergelijking omdat ze al door een
  -- ANDERE, eerder in alfabetische volgorde vurende trigger deterministisch
  -- worden overschreven (trg_leerlingen_bijgewerkt -> bijgewerkt_op = now()),
  -- ongeacht wat de client instuurt. Dit zijn geen "leerling mag wijzigen"
  -- kolommen -- puur ruis die anders elke legitieme avatar-update ten
  -- onrechte zou blokkeren.
  genegeerde_kolommen text[] := ARRAY['bijgewerkt_op'];
  te_negeren_kolommen text[] := toegestane_kolommen || genegeerde_kolommen;
BEGIN
  -- Grijp alleen in wanneer de aanroeper de aan DEZE rij gekoppelde leerling
  -- zelf is. Instructeur-updates en SECURITY DEFINER-RPC's (bv. koppelen,
  -- waarbij OLD.user_id nog NULL is) vallen hier buiten.
  IF OLD.user_id IS NOT NULL AND auth.uid() = OLD.user_id THEN
    IF (to_jsonb(OLD) - te_negeren_kolommen) IS DISTINCT FROM (to_jsonb(NEW) - te_negeren_kolommen) THEN
      RAISE EXCEPTION
        'Leerling mag alleen % van het eigen profiel wijzigen', array_to_string(toegestane_kolommen, ', ')
        USING ERRCODE = '42501'; -- insufficient_privilege
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION public.enforce_leerling_zelf_update_kolommen() IS
  'Blokkeert wijzigingen buiten de whitelist wanneer een leerling zijn eigen leerlingen-rij update (auth.uid() = OLD.user_id). Zie docs/PROFIEL_AUDIT.md.';

DROP TRIGGER IF EXISTS trg_leerlingen_zelf_update_kolommen ON public.leerlingen;

CREATE TRIGGER trg_leerlingen_zelf_update_kolommen
  BEFORE UPDATE ON public.leerlingen
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_leerling_zelf_update_kolommen();

-- Volgorde t.o.v. de bestaande trg_leerlingen_bijgewerkt-trigger: Postgres
-- voert BEFORE-triggers op dezelfde tabel/event uit in alfabetische volgorde
-- op triggernaam, dus "trg_leerlingen_bijgewerkt" (b < z) vuurt vóór
-- "trg_leerlingen_zelf_update_kolommen" en zet NEW.bijgewerkt_op al naar
-- now() vóórdat deze trigger OLD/NEW vergelijkt. Daarom staat bijgewerkt_op
-- in genegeerde_kolommen hierboven -- anders zou elke legitieme
-- avatar-update alsnog onterecht geblokkeerd worden.
