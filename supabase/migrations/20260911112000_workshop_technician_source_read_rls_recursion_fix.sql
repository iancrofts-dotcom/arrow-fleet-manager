-- FleetIQ Build 17.4.4.5
-- Fix infinite RLS recursion introduced by 20260911104000 when the
-- workshop_inspections policy queried workshop_repair_jobs while the existing
-- Driver repair-job policy queried workshop_inspections.
--
-- Technician source-read checks are moved behind narrowly scoped
-- SECURITY DEFINER predicates. They return only a boolean and always bind the
-- lookup to auth.uid(); callers cannot use them to enumerate repair-job data.

-- Remove the recursive policies first so Workshop becomes usable again as
-- soon as this migration is applied.
drop policy if exists "technicians read assigned repair source inspections"
  on public.workshop_inspections;
drop policy if exists "technicians read assigned repair source items"
  on public.workshop_inspection_items;

create or replace function public.workshop_technician_can_read_source_inspection(
  p_inspection_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.workshop_repair_jobs repair
    where repair.inspection_id = p_inspection_id
      and repair.technician_profile_id = auth.uid()
      and repair.status <> 'cancelled'
  );
$$;

create or replace function public.workshop_technician_can_read_source_item(
  p_inspection_item_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.workshop_repair_jobs repair
    where repair.inspection_item_id = p_inspection_item_id
      and repair.technician_profile_id = auth.uid()
      and repair.status <> 'cancelled'
  );
$$;

revoke all on function public.workshop_technician_can_read_source_inspection(uuid)
  from public, anon;
revoke all on function public.workshop_technician_can_read_source_item(uuid)
  from public, anon;
grant execute on function public.workshop_technician_can_read_source_inspection(uuid)
  to authenticated;
grant execute on function public.workshop_technician_can_read_source_item(uuid)
  to authenticated;

create policy "technicians read assigned repair source inspections"
on public.workshop_inspections
for select to authenticated
using (
  public.has_fleetiq_role('technician')
  and public.workshop_technician_can_read_source_inspection(workshop_inspections.id)
);

create policy "technicians read assigned repair source items"
on public.workshop_inspection_items
for select to authenticated
using (
  public.has_fleetiq_role('technician')
  and public.workshop_technician_can_read_source_item(workshop_inspection_items.id)
);

-- Preserve the established direct-write lock.
revoke insert, update, delete on table public.workshop_inspections
  from anon, authenticated;
revoke insert, update, delete on table public.workshop_inspection_items
  from anon, authenticated;
