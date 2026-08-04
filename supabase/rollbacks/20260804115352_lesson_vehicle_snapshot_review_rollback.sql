-- Rollback for 20260804115352_lesson_vehicle_snapshot_review.sql.
-- Review only. Do not apply until approved.

drop view if exists public.student_lessen_view;

create view public.student_lessen_view
with (security_barrier = true, security_invoker = true)
as
select
  l.id,
  l.instructeur_id,
  l.leerling_id,
  l.datum,
  l.starttijd,
  l.eindtijd,
  l.duur_minuten,
  l.status,
  l.les_type,
  leerling.rijbewijs_soort,
  case
    when l.status = 'gepland'::text
      or l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.locatie
    else null::text
  end as locatie,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.geoefende_onderwerpen
    else null::text[]
  end as geoefende_onderwerpen,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.instructeur_feedback
    else null::text
  end as instructeur_feedback,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.leerling_notitie
    else null::text
  end as leerling_notitie,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.competentie_scores
    else null::jsonb
  end as competentie_scores,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.beoordeling
    else null::text
  end as beoordeling,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.focus_punten
    else null::text[]
  end as focus_punten,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.ingrepen_count
    else null::text
  end as ingrepen_count,
  case
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.volgende_les_advies
    else null::text
  end as volgende_les_advies,
  l.zichtbaar_voor_leerling,
  l.aangemaakt_op,
  l.bijgewerkt_op,
  i.naam as instructeur_naam,
  i.telefoon as instructeur_telefoon,
  i.email as instructeur_email,
  i.logo_url as instructeur_logo_url
from public.lessen l
join public.leerlingen leerling on leerling.id = l.leerling_id
left join public.instructeur_profielen i on i.id = l.instructeur_id
where leerling.user_id = (select auth.uid())
  and (
    l.status = 'gepland'::text
    or l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    or l.status = any (array[
      'geannuleerd'::text,
      'verzet'::text,
      'geen_toon'::text
    ])
  );

revoke all on public.student_lessen_view from anon, authenticated, service_role;
grant select on public.student_lessen_view to anon, authenticated, service_role;

drop trigger if exists trg_validate_and_snapshot_lesson_vehicle on public.lessen;
drop function if exists public.validate_and_snapshot_lesson_vehicle();
drop policy if exists "Leerlingen lezen gekoppelde lesvoertuigen"
on public.vehicles;

alter table public.lessen
  drop constraint if exists lessen_voertuig_id_fkey;

drop index if exists public.idx_lessen_instructeur_voertuig;
drop index if exists public.idx_lessen_voertuig_id;

alter table public.lessen
  drop column if exists voertuig_snapshot_op,
  drop column if exists voertuig_categorie_snapshot,
  drop column if exists voertuig_transmissie_snapshot,
  drop column if exists voertuig_kenteken_snapshot,
  drop column if exists voertuig_model_snapshot,
  drop column if exists voertuig_merk_snapshot,
  drop column if exists voertuig_naam_snapshot,
  drop column if exists voertuig_id;
