-- Student onboarding guard + koppelcode backend.
-- Keeps the dashboard unreachable until leerlingen.user_id is linked.

alter table public.leerlingen
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists koppel_code text,
  add column if not exists koppel_code_verloopt_op timestamptz,
  add column if not exists gekoppeld_op timestamptz;

create index if not exists idx_leerlingen_user_id
  on public.leerlingen(user_id);

create unique index if not exists leerlingen_koppel_code_unique_idx
  on public.leerlingen(koppel_code)
  where koppel_code is not null;

create or replace function public.generate_koppel_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  loop
    v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    exit when not exists (
      select 1
      from public.leerlingen
      where koppel_code = v_code
    );
  end loop;

  return v_code;
end;
$$;

alter table public.leerlingen
  alter column koppel_code set default public.generate_koppel_code(),
  alter column koppel_code_verloopt_op set default (now() + interval '30 days');

update public.leerlingen
set
  koppel_code = public.generate_koppel_code(),
  koppel_code_verloopt_op = coalesce(koppel_code_verloopt_op, now() + interval '30 days')
where koppel_code is null;

create or replace function public.regenereer_koppel_code(p_leerling_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  if auth.uid() is null then
    return jsonb_build_object('succes', false, 'fout', 'Niet ingelogd');
  end if;

  if not exists (
    select 1
    from public.leerlingen
    where id = p_leerling_id
      and instructeur_id = auth.uid()
  ) then
    return jsonb_build_object('succes', false, 'fout', 'Leerling niet gevonden');
  end if;

  v_code := public.generate_koppel_code();

  update public.leerlingen
  set
    koppel_code = v_code,
    koppel_code_verloopt_op = now() + interval '30 days',
    user_id = null,
    gekoppeld_op = null
  where id = p_leerling_id
    and instructeur_id = auth.uid();

  return jsonb_build_object('succes', true, 'koppel_code', v_code);
end;
$$;

create or replace function public.koppel_leerling_met_code(p_koppel_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_leerling public.leerlingen%rowtype;
begin
  if v_user_id is null then
    return jsonb_build_object('succes', false, 'fout', 'Niet ingelogd');
  end if;

  if nullif(trim(p_koppel_code), '') is null then
    return jsonb_build_object('succes', false, 'fout', 'Vul een koppelcode in');
  end if;

  select *
  into v_leerling
  from public.leerlingen
  where upper(koppel_code) = upper(trim(p_koppel_code))
  limit 1;

  if not found then
    return jsonb_build_object('succes', false, 'fout', 'Ongeldige koppelcode');
  end if;

  if v_leerling.koppel_code_verloopt_op is not null
      and v_leerling.koppel_code_verloopt_op < now() then
    return jsonb_build_object('succes', false, 'fout', 'Koppelcode is verlopen');
  end if;

  if v_leerling.user_id is not null and v_leerling.user_id <> v_user_id then
    return jsonb_build_object('succes', false, 'fout', 'Deze koppelcode is al gebruikt');
  end if;

  select email
  into v_email
  from auth.users
  where id = v_user_id;

  update public.leerlingen
  set
    user_id = v_user_id,
    gekoppeld_op = coalesce(gekoppeld_op, now()),
    email = coalesce(nullif(email, ''), v_email)
  where id = v_leerling.id;

  return jsonb_build_object(
    'succes', true,
    'leerling_id', v_leerling.id,
    'instructeur_id', v_leerling.instructeur_id
  );
end;
$$;

grant execute on function public.generate_koppel_code() to authenticated;
grant execute on function public.regenereer_koppel_code(uuid) to authenticated;
grant execute on function public.koppel_leerling_met_code(text) to authenticated;

alter table public.leerlingen enable row level security;

grant select, insert, update, delete on table public.leerlingen to authenticated;

drop policy if exists "student_leerling_select" on public.leerlingen;
create policy "student_leerling_select" on public.leerlingen
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "instructeur_leerlingen_select" on public.leerlingen;
create policy "instructeur_leerlingen_select" on public.leerlingen
  for select
  to authenticated
  using (instructeur_id = auth.uid());

drop policy if exists "instructeur_leerlingen_insert" on public.leerlingen;
create policy "instructeur_leerlingen_insert" on public.leerlingen
  for insert
  to authenticated
  with check (instructeur_id = auth.uid());

drop policy if exists "instructeur_leerlingen_update" on public.leerlingen;
create policy "instructeur_leerlingen_update" on public.leerlingen
  for update
  to authenticated
  using (instructeur_id = auth.uid())
  with check (instructeur_id = auth.uid());

drop policy if exists "instructeur_leerlingen_delete" on public.leerlingen;
create policy "instructeur_leerlingen_delete" on public.leerlingen
  for delete
  to authenticated
  using (instructeur_id = auth.uid());
