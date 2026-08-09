-- Goedgekeurd 2026-08-07: verscherpt de trigger uit
-- 20260804115352_lesson_vehicle_snapshot_review.sql met een expliciete
-- historical_lesson-guard (voorkomt dat de voertuigkoppeling van een
-- afgeronde les wordt losgekoppeld of gewijzigd). Toepassen NA de migratie
-- hierboven. Scope: trigger function only. No data, view, policy, or grant
-- changes. Rollback:
-- supabase/rollbacks/20260804150948_lesson_vehicle_snapshot_clear_contract_rollback.sql

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
  historical_lesson boolean;
begin
  if tg_op = 'INSERT' then
    selecting_vehicle := new.voertuig_id is not null;
    completing_lesson :=
      new.voertuig_id is not null
      and new.status = 'afgerond';
    historical_lesson := new.status = 'afgerond';
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
    historical_lesson :=
      old.status = 'afgerond'
      or new.status = 'afgerond';
  end if;

  if new.voertuig_id is null then
    if tg_op = 'UPDATE'
       and old.voertuig_id is not null
       and historical_lesson then
      raise exception 'Voertuigkoppeling van een afgeronde les kan niet worden verwijderd'
        using errcode = '23514';
    end if;

    new.voertuig_naam_snapshot := null;
    new.voertuig_merk_snapshot := null;
    new.voertuig_model_snapshot := null;
    new.voertuig_kenteken_snapshot := null;
    new.voertuig_transmissie_snapshot := null;
    new.voertuig_categorie_snapshot := null;
    new.voertuig_snapshot_op := null;
    return new;
  end if;

  if tg_op = 'UPDATE'
     and old.status = 'afgerond'
     and old.voertuig_id is distinct from new.voertuig_id then
    raise exception 'Voertuigkoppeling van een afgeronde les kan niet worden gewijzigd'
      using errcode = '23514';
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
