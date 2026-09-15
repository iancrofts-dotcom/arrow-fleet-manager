-- FleetIQ Build 17.4.4.4
-- A Technician assigned to a Repair Job created from a Driver inspection must
-- be able to read that Repair Job's source inspection and defect item.
-- Existing Workshop/management access remains unchanged and direct writes stay locked.

alter table public.workshop_inspections enable row level security;
alter table public.workshop_inspection_items enable row level security;

drop policy if exists "technicians read assigned repair source inspections"
  on public.workshop_inspections;
create policy "technicians read assigned repair source inspections"
on public.workshop_inspections
for select to authenticated
using (
  public.has_fleetiq_role('technician')
  and exists (
    select 1
    from public.workshop_repair_jobs repair
    where repair.inspection_id = workshop_inspections.id
      and repair.technician_profile_id = auth.uid()
      and repair.status <> 'cancelled'
  )
);

drop policy if exists "technicians read assigned repair source items"
  on public.workshop_inspection_items;
create policy "technicians read assigned repair source items"
on public.workshop_inspection_items
for select to authenticated
using (
  public.has_fleetiq_role('technician')
  and exists (
    select 1
    from public.workshop_repair_jobs repair
    where repair.inspection_item_id = workshop_inspection_items.id
      and repair.technician_profile_id = auth.uid()
      and repair.status <> 'cancelled'
  )
);

-- Keep the established direct-write lock intact.
revoke insert, update, delete on table public.workshop_inspections from anon, authenticated;
revoke insert, update, delete on table public.workshop_inspection_items from anon, authenticated;
