-- Goedgekeurd 2026-08-07. Toepassen NA
-- 20260804115352_lesson_vehicle_snapshot_review.sql en
-- 20260804150948_lesson_vehicle_snapshot_clear_contract.sql (vereist
-- lessen.voertuig_id + de validatie/snapshot-trigger).
--
-- Veilige backfill: koppelt voertuig_id ALLEEN aan bestaande GEPLANDE lessen
-- die nog geen koppeling hebben, en ALLEEN wanneer er voor de instructeur
-- van die les exact één actief voertuig bestaat dat past bij de
-- rijbewijscategorie + transmissie van de leerling -- dezelfde regels als
-- de validatietrigger validate_and_snapshot_lesson_vehicle() hieronder
-- opnieuw zal controleren (transmissie is alleen relevant wanneer de
-- leerling niet 'none' heeft, exact zoals de trigger dat toetst). Bij 0 of
-- meer dan 1 kandidaat blijft voertuig_id NULL: nooit gokken.
--
-- Afgeronde/historische lessen worden BEWUST NOOIT backfilled (ook niet bij
-- een ondubbelzinnige match): er bestaat geen betrouwbare bron om achteraf
-- vast te stellen welk voertuig destijds daadwerkelijk gebruikt is -- alleen
-- een live, vooruitkijkende koppeling door de instructeur zelf (of, voor
-- toekomstige lessen, deze zelfde ondubbelzinnige auto-koppeling in de
-- Instructeur-app) is betrouwbaar genoeg.
--
-- Idempotent: filtert al op "voertuig_id is null", dus een herhaalde
-- uitvoering raakt nooit een les die al gekoppeld is (handmatig of door
-- een eerdere run van dit script).

with kandidaten as (
  select
    l.id as les_id,
    v.id as voertuig_id,
    count(*) over (partition by l.id) as aantal_kandidaten
  from public.lessen l
  join public.leerlingen leerling on leerling.id = l.leerling_id
  join public.vehicles v
    on v.instructeur_id = l.instructeur_id
   and v.actief = true
   and v.categorie_id = leerling.rijbewijs_soort
   and (
     coalesce(leerling.transmissie, 'none') = 'none'
     or v.transmissie_type = leerling.transmissie
   )
  where l.status = 'gepland'
    and l.voertuig_id is null
)
update public.lessen l
set voertuig_id = k.voertuig_id
from kandidaten k
where l.id = k.les_id
  and k.aantal_kandidaten = 1;
