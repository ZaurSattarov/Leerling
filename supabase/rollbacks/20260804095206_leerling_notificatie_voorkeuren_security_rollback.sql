begin;

drop trigger if exists leerling_notificaties_guard_student_update
  on public.leerling_notificaties;
drop function if exists public.leerling_notificaties_guard_student_update();

do $$
begin
  if to_regclass('public.leerling_notificatie_voorkeuren') is not null then
    drop trigger if exists leerling_notificatie_voorkeuren_set_updated_at
      on public.leerling_notificatie_voorkeuren;
  end if;
end $$;
drop table if exists public.leerling_notificatie_voorkeuren;

drop policy if exists "student_notificaties_update_gelezen_guarded"
  on public.leerling_notificaties;
drop policy if exists "instructeur_notificaties_select"
  on public.leerling_notificaties;
drop policy if exists "instructeur_notificaties_insert"
  on public.leerling_notificaties;
drop policy if exists "student_notificaties_select"
  on public.leerling_notificaties;
drop policy if exists "student_notificaties_update"
  on public.leerling_notificaties;
drop policy if exists "instructeur_notificaties_all"
  on public.leerling_notificaties;

create policy "student_notificaties_select"
  on public.leerling_notificaties
  for select
  using (
    leerling_id in (
      select id from public.leerlingen where user_id = auth.uid()
    )
  );

create policy "student_notificaties_update"
  on public.leerling_notificaties
  for update
  using (
    leerling_id in (
      select id from public.leerlingen where user_id = auth.uid()
    )
  )
  with check (
    leerling_id in (
      select id from public.leerlingen where user_id = auth.uid()
    )
  );

create policy "instructeur_notificaties_all"
  on public.leerling_notificaties
  for all
  using (instructeur_id = auth.uid())
  with check (instructeur_id = auth.uid());

drop index if exists public.idx_leerling_notificaties_event_key;
drop index if exists public.idx_leerling_notificaties_scheduled;

alter table public.leerling_notificaties
  drop constraint if exists leerling_notificaties_target_route_internal_chk;

alter table public.leerling_notificaties
  drop column if exists metadata,
  drop column if exists scheduled_for,
  drop column if exists target_route;

grant all on table public.leerling_notificaties to anon;
grant all on table public.leerling_notificaties to authenticated;
grant all on table public.leerling_notificaties to service_role;

commit;
