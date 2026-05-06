-- Backend-ready learner notifications.
-- Additive migration: keeps existing omschrijving/aangemaakt_op columns working.

create table if not exists public.leerling_notificaties (
  id uuid primary key default gen_random_uuid(),
  leerling_id uuid not null references public.leerlingen(id) on delete cascade,
  instructeur_id uuid references public.instructeur_profielen(id) on delete cascade,
  titel text not null,
  omschrijving text,
  bericht text,
  type text not null default 'systeem',
  target_route text,
  gelezen boolean not null default false,
  aangemaakt_op timestamptz not null default now(),
  created_at timestamptz not null default now(),
  scheduled_for timestamptz,
  metadata jsonb not null default '{}'::jsonb
);

alter table public.leerling_notificaties
  add column if not exists bericht text,
  add column if not exists target_route text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists scheduled_for timestamptz,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

update public.leerling_notificaties
set
  bericht = coalesce(bericht, omschrijving),
  created_at = coalesce(created_at, aangemaakt_op)
where bericht is null
   or created_at is null;

create index if not exists idx_leerling_notificaties_leerling_created
  on public.leerling_notificaties(leerling_id, gelezen, created_at desc);

create index if not exists idx_leerling_notificaties_scheduled
  on public.leerling_notificaties(scheduled_for)
  where scheduled_for is not null;

alter table public.leerling_notificaties enable row level security;

drop policy if exists "student_notificaties_select" on public.leerling_notificaties;
create policy "student_notificaties_select" on public.leerling_notificaties
  for select
  using (
    leerling_id in (
      select id from public.leerlingen where user_id = auth.uid()
    )
  );

drop policy if exists "student_notificaties_update" on public.leerling_notificaties;
create policy "student_notificaties_update" on public.leerling_notificaties
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

drop policy if exists "instructeur_notificaties_all" on public.leerling_notificaties;
create policy "instructeur_notificaties_all" on public.leerling_notificaties
  for all
  using (instructeur_id = auth.uid())
  with check (instructeur_id = auth.uid());

comment on table public.leerling_notificaties is
  'Learner-facing in-app notifications. Push delivery can be added later.';
comment on column public.leerling_notificaties.bericht is
  'Primary notification message for the learner app. Existing omschrijving remains for backward compatibility.';
comment on column public.leerling_notificaties.target_route is
  'Student app route opened when the notification is tapped.';
