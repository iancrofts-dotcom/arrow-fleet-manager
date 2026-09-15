-- FleetIQ Build 16.3: Driver assigned-vehicle visibility and central daily inspections.
-- Drivers gain read access only to their current assigned vehicle and their own
-- daily inspection history. Daily inspection writes remain RPC-only.

create policy "drivers read current assigned vehicle"
on public.vehicles
for select to authenticated
using (
  public.has_fleetiq_role('driver')
  and exists (
    select 1
    from public.driver_assignments assignment
    join public.profiles profile on profile.id = auth.uid()
    where assignment.vehicle_id = vehicles.id
      and assignment.driver_id = profile.driver_id
      and assignment.is_active = true
      and assignment.assigned_to is null
  )
);

create policy "drivers read own workshop inspections"
on public.workshop_inspections
for select to authenticated
using (
  public.has_fleetiq_role('driver')
  and driver_id = (select driver_id from public.profiles where id = auth.uid())
);

create policy "drivers read own workshop inspection items"
on public.workshop_inspection_items
for select to authenticated
using (
  public.has_fleetiq_role('driver')
  and exists (
    select 1
    from public.workshop_inspections inspection
    where inspection.id = workshop_inspection_items.inspection_id
      and inspection.driver_id = (
        select driver_id from public.profiles where id = auth.uid()
      )
  )
);

create policy "drivers read own workshop repair jobs"
on public.workshop_repair_jobs
for select to authenticated
using (
  public.has_fleetiq_role('driver')
  and exists (
    select 1
    from public.workshop_inspections inspection
    where inspection.id = workshop_repair_jobs.inspection_id
      and inspection.driver_id = (
        select driver_id from public.profiles where id = auth.uid()
      )
  )
);

create or replace function public.workshop_save_driver_daily_inspection(
  p_vehicle_id uuid,
  p_mileage integer,
  p_notes text default '',
  p_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
  v_driver_name text;
  v_registration text;
  v_fleet_number text;
  v_inspection_id uuid;
  v_inspection_number text;
  v_item jsonb;
  v_item_id uuid;
  v_title text;
  v_category text;
  v_status text;
  v_item_notes text;
  v_repair_required boolean;
  v_display_order integer;
  v_failures integer := 0;
  v_repairs integer := 0;
  v_total integer := 0;
  v_score integer := 0;
  v_job_number text;
begin
  if auth.uid() is null or not public.has_fleetiq_role('driver') then
    raise exception 'Driver account required.';
  end if;

  select p.driver_id, p.username
    into v_driver_id, v_driver_name
  from public.profiles p
  where p.id = auth.uid()
    and p.is_active = true;

  if v_driver_id is null then
    raise exception 'Signed-in account is not linked to a Driver.';
  end if;

  if p_mileage is null or p_mileage <= 0 then
    raise exception 'Odometer must be greater than zero.';
  end if;

  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array'
     or jsonb_array_length(coalesce(p_items, '[]'::jsonb)) = 0 then
    raise exception 'Daily inspection requires checklist items.';
  end if;

  if not exists (
    select 1
    from public.driver_assignments a
    where a.driver_id = v_driver_id
      and a.vehicle_id = p_vehicle_id
      and a.is_active = true
      and a.assigned_to is null
  ) then
    raise exception 'This vehicle is not currently assigned to the signed-in Driver.';
  end if;

  select v.registration, v.fleet_number
    into v_registration, v_fleet_number
  from public.vehicles v
  where v.id = p_vehicle_id
    and v.is_active = true;

  if not found then
    raise exception 'Assigned vehicle is not active.';
  end if;

  v_inspection_number := 'DI-' || to_char(current_date, 'YYYYMMDD') || '-' ||
    lpad(nextval('public.workshop_inspection_number_seq')::text, 6, '0');

  insert into public.workshop_inspections(
    inspection_number,
    vehicle_id,
    registration,
    fleet_number,
    driver_id,
    driver_name,
    inspection_type,
    status,
    vehicle_status,
    date_started,
    mileage,
    overall_result,
    notes
  ) values (
    v_inspection_number,
    p_vehicle_id,
    v_registration,
    coalesce(v_fleet_number, ''),
    v_driver_id,
    v_driver_name,
    'driverDailyInspection',
    'inProgress',
    'roadworthy',
    now(),
    p_mileage,
    'pending',
    coalesce(p_notes, '')
  ) returning id into v_inspection_id;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_title := btrim(coalesce(v_item->>'title', ''));
    v_category := btrim(coalesce(v_item->>'category', ''));
    v_status := coalesce(v_item->>'status', 'notApplicable');
    v_item_notes := coalesce(v_item->>'notes', '');
    v_repair_required := coalesce((v_item->>'repair_required')::boolean, false);
    v_display_order := coalesce((v_item->>'display_order')::integer, v_total);

    if v_title = '' or v_category = '' then
      raise exception 'Checklist title and category are required.';
    end if;
    if v_status not in ('notApplicable', 'pass', 'fail') then
      raise exception 'Invalid daily inspection checklist status.';
    end if;

    insert into public.workshop_inspection_items(
      inspection_id,
      category,
      title,
      response_type,
      response_value,
      status,
      mandatory,
      repair_required,
      notes,
      display_order
    ) values (
      v_inspection_id,
      v_category,
      v_title,
      'passFailNotApplicable',
      v_status,
      v_status,
      true,
      v_repair_required,
      v_item_notes,
      v_display_order
    ) returning id into v_item_id;

    v_total := v_total + 1;
    if v_status = 'fail' then
      v_failures := v_failures + 1;
    end if;

    if v_status = 'fail' or v_repair_required then
      v_repairs := v_repairs + 1;
      v_job_number := 'RJ-' || to_char(current_date, 'YYYYMMDD') || '-' ||
        lpad(nextval('public.workshop_job_number_seq')::text, 6, '0');

      insert into public.workshop_repair_jobs(
        job_number,
        inspection_id,
        inspection_item_id,
        vehicle_id,
        vehicle_registration,
        title,
        description,
        priority,
        status,
        technician_name,
        parts_required,
        estimated_hours,
        estimated_cost,
        roadworthy
      ) values (
        v_job_number,
        v_inspection_id,
        v_item_id,
        p_vehicle_id,
        v_registration,
        v_title,
        nullif(v_item_notes, ''),
        'medium',
        'open',
        '',
        false,
        0,
        0,
        false
      );
    end if;
  end loop;

  v_score := case
    when v_total = 0 then 0
    else greatest(0, least(100, round(((v_total - v_failures)::numeric / v_total::numeric) * 100)::integer))
  end;

  update public.workshop_inspections
  set overall_result = case when v_failures > 0 then 'fail' else 'pass' end,
      inspection_score = v_score,
      critical_failures = v_failures,
      advisories = 0,
      repairs_required = v_repairs,
      status = case when v_repairs > 0 then 'awaitingRepair' else 'completed' end,
      vehicle_status = case when v_repairs > 0 then 'awaitingRepair' else 'roadworthy' end,
      date_completed = case when v_repairs > 0 then null else now() end,
      updated_at = now()
  where id = v_inspection_id;

  return v_inspection_id;
end;
$$;

revoke all on function public.workshop_save_driver_daily_inspection(uuid,integer,text,jsonb)
from public, anon;
grant execute on function public.workshop_save_driver_daily_inspection(uuid,integer,text,jsonb)
to authenticated;
