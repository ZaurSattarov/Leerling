-- Review only. Do not apply until approved.
-- Restores the function definition that was live before this migration.

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
