-- Fase 10: backend hardening & privacy fixes.
-- Same shared Supabase project migration as the instructor app.
-- Run once in Supabase; this copy keeps the learner repo contract visible.

alter table if exists public.lessen
  drop constraint if exists lessen_beoordeling_check;

update public.lessen
set beoordeling = case lower(trim(beoordeling))
  when 'onvoldoende' then '2'
  when 'voldoende' then '3'
  when 'goed' then '4'
  else beoordeling
end
where beoordeling is not null
  and lower(trim(beoordeling)) in ('onvoldoende', 'voldoende', 'goed');

alter table if exists public.lessen
  add constraint lessen_beoordeling_check
  check (
    beoordeling is null
    or beoordeling in ('1', '2', '3', '4', '5')
  )
  not valid;

comment on column public.lessen.beoordeling is
  'Learner-facing lesson rating score stored as text value 1..5. Older labels should be migrated before enabling this constraint.';

alter table if exists public.facturen
  add column if not exists betaal_link_url text,
  add column if not exists stripe_checkout_url text,
  add column if not exists stripe_checkout_session text,
  add column if not exists stripe_payment_intent_id text,
  add column if not exists betaald_op timestamptz,
  add column if not exists invoice_pdf_url text,
  add column if not exists download_url text;

create index if not exists facturen_stripe_checkout_session_idx
  on public.facturen (stripe_checkout_session)
  where stripe_checkout_session is not null;

create index if not exists facturen_stripe_payment_intent_idx
  on public.facturen (stripe_payment_intent_id)
  where stripe_payment_intent_id is not null;

drop view if exists public.student_lessen_view;

create view public.student_lessen_view
with (security_barrier = true)
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
  case
    when l.status = 'gepland'
      or (l.status = 'afgerond' and l.zichtbaar_voor_leerling is true)
    then l.locatie
    else null
  end as locatie,
  case
    when l.status = 'afgerond' and l.zichtbaar_voor_leerling is true
    then l.geoefende_onderwerpen
    else null
  end as geoefende_onderwerpen,
  case
    when l.status = 'afgerond' and l.zichtbaar_voor_leerling is true
    then l.instructeur_feedback
    else null
  end as instructeur_feedback,
  case
    when l.status = 'afgerond' and l.zichtbaar_voor_leerling is true
    then l.leerling_notitie
    else null
  end as leerling_notitie,
  case
    when l.status = 'afgerond' and l.zichtbaar_voor_leerling is true
    then l.competentie_scores
    else null
  end as competentie_scores,
  case
    when l.status = 'afgerond' and l.zichtbaar_voor_leerling is true
    then l.beoordeling
    else null
  end as beoordeling,
  l.zichtbaar_voor_leerling,
  l.aangemaakt_op,
  l.bijgewerkt_op,
  i.naam as instructeur_naam,
  i.telefoon as instructeur_telefoon
from public.lessen l
join public.leerlingen leerling on leerling.id = l.leerling_id
left join public.instructeur_profielen i on i.id = l.instructeur_id
where leerling.user_id = auth.uid()
  and (
    l.status = 'gepland'
    or (l.status = 'afgerond' and l.zichtbaar_voor_leerling is true)
  );

grant select on public.student_lessen_view to authenticated;

comment on view public.student_lessen_view is
  'Safe learner-facing projection of lessons. Internal notities and hidden feedback are never exposed.';

drop policy if exists "student_lessen_select" on public.lessen;

create or replace function public.update_student_lesson_note(
  p_les_id uuid,
  p_notitie text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.lessen l
  set
    leerling_notitie = nullif(trim(p_notitie), ''),
    bijgewerkt_op = now()
  from public.leerlingen leerling
  where l.id = p_les_id
    and leerling.id = l.leerling_id
    and leerling.user_id = auth.uid()
    and l.status = 'afgerond'
    and l.zichtbaar_voor_leerling is true;
end;
$$;

grant execute on function public.update_student_lesson_note(uuid, text)
  to authenticated;

comment on function public.update_student_lesson_note(uuid, text) is
  'Learner-safe update path for leerling_notitie only.';
