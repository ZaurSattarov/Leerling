-- Goedgekeurd 2026-08-07: Optie B uit docs/lesson_vehicle_architecture_review.md.
-- Purpose: exact lesson -> vehicle relation plus historical snapshot fields.
-- Alle wijzigingen zijn additief/idempotent (if not exists / create or replace /
-- drop ... if exists) en veilig herhaald uit te voeren. Rollback:
-- supabase/rollbacks/20260804115352_lesson_vehicle_snapshot_review_rollback.sql

begin;

alter table public.lessen
  add column if not exists voertuig_id uuid,
  add column if not exists voertuig_naam_snapshot text,
  add column if not exists voertuig_merk_snapshot text,
  add column if not exists voertuig_model_snapshot text,
  add column if not exists voertuig_kenteken_snapshot text,
  add column if not exists voertuig_transmissie_snapshot text,
  add column if not exists voertuig_categorie_snapshot text,
  add column if not exists voertuig_snapshot_op timestamptz;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conname = 'lessen_voertuig_id_fkey'
       and conrelid = 'public.lessen'::regclass
  ) then
    alter table public.lessen
      add constraint lessen_voertuig_id_fkey
      foreign key (voertuig_id)
      references public.vehicles(id)
      on delete set null;
  end if;
end;
$$;

create index if not exists idx_lessen_voertuig_id
  on public.lessen(voertuig_id)
  where voertuig_id is not null;

create index if not exists idx_lessen_instructeur_voertuig
  on public.lessen(instructeur_id, voertuig_id)
  where voertuig_id is not null;

create or replace function public.validate_and_snapshot_lesson_vehicle()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  vehicle_row public.vehicles%rowtype;
  leerling_row record;
  selecting_vehicle boolean;
  completing_lesson boolean;
begin
  if tg_op = 'INSERT' then
    selecting_vehicle := new.voertuig_id is not null;
    completing_lesson :=
      new.voertuig_id is not null
      and new.status = 'afgerond';
  else
    selecting_vehicle :=
      new.voertuig_id is not null
      and old.voertuig_id is distinct from new.voertuig_id;
    completing_lesson :=
      new.voertuig_id is not null
      and new.status = 'afgerond'
      and (
        old.status is distinct from new.status
        or old.voertuig_id is distinct from new.voertuig_id
      );
  end if;

  if new.voertuig_id is null then
    return new;
  end if;

  select *
    into vehicle_row
    from public.vehicles
   where id = new.voertuig_id;

  if not found then
    raise exception 'Voertuig % bestaat niet', new.voertuig_id
      using errcode = '23503';
  end if;

  if vehicle_row.instructeur_id is distinct from new.instructeur_id then
    raise exception 'Voertuig hoort niet bij deze instructeur'
      using errcode = '23514';
  end if;

  if selecting_vehicle and vehicle_row.actief is not true then
    raise exception 'Voertuig is niet actief'
      using errcode = '23514';
  end if;

  select rijbewijs_soort, transmissie
    into leerling_row
    from public.leerlingen
   where id = new.leerling_id;

  if not found then
    raise exception 'Leerling % bestaat niet', new.leerling_id
      using errcode = '23503';
  end if;

  if vehicle_row.categorie_id is distinct from leerling_row.rijbewijs_soort then
    raise exception 'Voertuigcategorie past niet bij rijbewijscategorie'
      using errcode = '23514';
  end if;

  if coalesce(leerling_row.transmissie, 'none') <> 'none'
     and vehicle_row.transmissie_type is distinct from leerling_row.transmissie then
    raise exception 'Voertuigtransmissie past niet bij leerlingtransmissie'
      using errcode = '23514';
  end if;

  if selecting_vehicle or completing_lesson then
    new.voertuig_naam_snapshot := vehicle_row.naam;
    new.voertuig_merk_snapshot := vehicle_row.merk;
    new.voertuig_model_snapshot := vehicle_row.model;
    new.voertuig_kenteken_snapshot := vehicle_row.kenteken;
    new.voertuig_transmissie_snapshot := vehicle_row.transmissie_type;
    new.voertuig_categorie_snapshot := vehicle_row.categorie_id;
    new.voertuig_snapshot_op := now();
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_and_snapshot_lesson_vehicle on public.lessen;

create trigger trg_validate_and_snapshot_lesson_vehicle
before insert or update of
  voertuig_id,
  leerling_id,
  instructeur_id,
  status
on public.lessen
for each row
execute function public.validate_and_snapshot_lesson_vehicle();

drop policy if exists "Leerlingen lezen gekoppelde lesvoertuigen"
on public.vehicles;

create policy "Leerlingen lezen gekoppelde lesvoertuigen"
on public.vehicles
for select
to authenticated
using (
  exists (
    select 1
      from public.lessen l
      join public.leerlingen leerling on leerling.id = l.leerling_id
     where l.voertuig_id = vehicles.id
       and leerling.user_id = (select auth.uid())
       and (
         l.status = 'gepland'::text
         or l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
         or l.status = any (array[
           'geannuleerd'::text,
           'verzet'::text,
           'geen_toon'::text
         ])
       )
  )
);

create or replace view public.student_lessen_view
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
  i.logo_url as instructeur_logo_url,
  case
    when l.status = 'gepland'::text then v.naam
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.voertuig_naam_snapshot
    else null::text
  end as voertuig_naam,
  case
    when l.status = 'gepland'::text then v.merk
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.voertuig_merk_snapshot
    else null::text
  end as voertuig_merk,
  case
    when l.status = 'gepland'::text then v.model
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.voertuig_model_snapshot
    else null::text
  end as voertuig_model,
  case
    when l.status = 'gepland'::text then v.kenteken
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.voertuig_kenteken_snapshot
    else null::text
  end as voertuig_kenteken,
  case
    when l.status = 'gepland'::text then v.transmissie_type
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.voertuig_transmissie_snapshot
    else null::text
  end as voertuig_transmissie,
  case
    when l.status = 'gepland'::text then v.categorie_id
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.voertuig_categorie_snapshot
    else null::text
  end as voertuig_categorie,
  case
    when l.status = 'gepland'::text then l.voertuig_id
    when l.status = 'afgerond'::text and l.zichtbaar_voor_leerling
    then l.voertuig_id
    else null::uuid
  end as voertuig_id
from public.lessen l
join public.leerlingen leerling on leerling.id = l.leerling_id
left join public.instructeur_profielen i on i.id = l.instructeur_id
left join public.vehicles v
  on v.id = l.voertuig_id
 and v.instructeur_id = l.instructeur_id
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

commit;
