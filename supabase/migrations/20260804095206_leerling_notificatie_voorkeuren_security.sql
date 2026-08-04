begin;

create table if not exists public.leerling_notificatie_voorkeuren (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nieuwe_les boolean not null default true,
  les_verplaatst boolean not null default true,
  nieuwe_factuur boolean not null default true,
  betaling_ontvangen boolean not null default true,
  factuur_herinnering boolean not null default true,
  nieuwe_evaluatie boolean not null default true,
  lespakket_bijna_op boolean not null default true,
  examenadvies boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.leerling_notificatie_voorkeuren enable row level security;

drop trigger if exists leerling_notificatie_voorkeuren_set_updated_at
  on public.leerling_notificatie_voorkeuren;

create trigger leerling_notificatie_voorkeuren_set_updated_at
  before update on public.leerling_notificatie_voorkeuren
  for each row execute function public.set_updated_at();

drop policy if exists "leerling_voorkeuren_select_own"
  on public.leerling_notificatie_voorkeuren;
drop policy if exists "leerling_voorkeuren_insert_own"
  on public.leerling_notificatie_voorkeuren;
drop policy if exists "leerling_voorkeuren_update_own"
  on public.leerling_notificatie_voorkeuren;

create policy "leerling_voorkeuren_select_own"
  on public.leerling_notificatie_voorkeuren
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "leerling_voorkeuren_insert_own"
  on public.leerling_notificatie_voorkeuren
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.leerlingen l
      where l.user_id = (select auth.uid())
    )
  );

create policy "leerling_voorkeuren_update_own"
  on public.leerling_notificatie_voorkeuren
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on table public.leerling_notificatie_voorkeuren from anon;
revoke all on table public.leerling_notificatie_voorkeuren from authenticated;
grant select, insert, update on table public.leerling_notificatie_voorkeuren to authenticated;
grant all on table public.leerling_notificatie_voorkeuren to service_role;

alter table public.leerling_notificaties
  add column if not exists target_route text,
  add column if not exists scheduled_for timestamptz,
  add column if not exists metadata jsonb;

update public.leerling_notificaties
set metadata = '{}'::jsonb
where metadata is null;

alter table public.leerling_notificaties
  alter column metadata set default '{}'::jsonb,
  alter column metadata set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'leerling_notificaties_target_route_internal_chk'
      and conrelid = 'public.leerling_notificaties'::regclass
  ) then
    alter table public.leerling_notificaties
      add constraint leerling_notificaties_target_route_internal_chk
      check (
        target_route is null
        or (
          target_route ~ '^/[A-Za-z0-9/_?=&.%-]*$'
          and target_route !~ '^//'
          and target_route !~ ':'
        )
      );
  end if;
end $$;

create index if not exists idx_leerling_notificaties_scheduled
  on public.leerling_notificaties(scheduled_for)
  where scheduled_for is not null;

create index if not exists idx_leerling_notificaties_event_key
  on public.leerling_notificaties((metadata ->> 'event_key'))
  where metadata ? 'event_key';

create or replace function public.leerling_notificaties_guard_student_update()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_is_student boolean;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select exists (
    select 1
    from public.leerlingen l
    where l.id = old.leerling_id
      and l.user_id = v_uid
  )
  into v_is_student;

  if v_is_student then
    if (to_jsonb(new) - 'gelezen') is distinct from
       (to_jsonb(old) - 'gelezen') then
      raise exception 'Leerling mag alleen gelezen wijzigen';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists leerling_notificaties_guard_student_update
  on public.leerling_notificaties;

create trigger leerling_notificaties_guard_student_update
  before update on public.leerling_notificaties
  for each row execute function public.leerling_notificaties_guard_student_update();

alter table public.leerling_notificaties enable row level security;

drop policy if exists "student_notificaties_update"
  on public.leerling_notificaties;
drop policy if exists "instructeur_notificaties_all"
  on public.leerling_notificaties;
drop policy if exists "student_notificaties_select"
  on public.leerling_notificaties;
drop policy if exists "student_notificaties_update_gelezen_guarded"
  on public.leerling_notificaties;
drop policy if exists "instructeur_notificaties_select"
  on public.leerling_notificaties;
drop policy if exists "instructeur_notificaties_insert"
  on public.leerling_notificaties;

create policy "student_notificaties_select"
  on public.leerling_notificaties
  for select to authenticated
  using (
    leerling_id in (
      select l.id
      from public.leerlingen l
      where l.user_id = (select auth.uid())
    )
  );

create policy "student_notificaties_update_gelezen_guarded"
  on public.leerling_notificaties
  for update to authenticated
  using (
    leerling_id in (
      select l.id
      from public.leerlingen l
      where l.user_id = (select auth.uid())
    )
  )
  with check (
    leerling_id in (
      select l.id
      from public.leerlingen l
      where l.user_id = (select auth.uid())
    )
  );

create policy "instructeur_notificaties_select"
  on public.leerling_notificaties
  for select to authenticated
  using (
    instructeur_id = (select auth.uid())
    and exists (
      select 1
      from public.instructeur_profielen ip
      where ip.id = (select auth.uid())
    )
  );

create policy "instructeur_notificaties_insert"
  on public.leerling_notificaties
  for insert to authenticated
  with check (
    instructeur_id = (select auth.uid())
    and exists (
      select 1
      from public.instructeur_profielen ip
      where ip.id = (select auth.uid())
    )
    and exists (
      select 1
      from public.leerlingen l
      where l.id = leerling_id
        and l.instructeur_id = (select auth.uid())
    )
  );

revoke all on table public.leerling_notificaties from anon;
revoke all on table public.leerling_notificaties from authenticated;

grant select on table public.leerling_notificaties to authenticated;
grant insert on table public.leerling_notificaties to authenticated;
grant update (gelezen) on public.leerling_notificaties to authenticated;

grant all on table public.leerling_notificaties to service_role;

commit;
