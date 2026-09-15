-- FleetIQ 17.4.7.2.1: explicit tenant boundaries for five privileged RPCs.
-- Foreign and absent IDs share the same scoped lookup/error paths.
begin;

create or replace function public.workshop_list_technicians()
returns table(id uuid, username text)
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_role text;
begin
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  join public.profiles p on p.id = m.user_id
  join public.organisations o on o.id = m.organisation_id
  where m.user_id = auth.uid() and m.organisation_id = v_org
    and m.is_active and p.is_active and o.is_active
  for share of m, p, o;
  if not found then
    raise exception 'Active organisation membership required.' using errcode = '42501';
  end if;
  return query
  select p.id, coalesce(nullif(btrim(p.full_name), ''), p.username)
  from public.profiles p
  join public.organisation_memberships m on m.user_id = p.id
  where m.organisation_id = v_org and m.is_active and p.is_active
    and m.role = 'technician'
    and (v_role in ('administrator', 'manager', 'workshop')
         or (v_role = 'technician' and p.id = auth.uid()))
  order by coalesce(nullif(btrim(p.full_name), ''), p.username);
end;
$$;

create or replace function public.fleet_assign_driver(
  p_driver_id uuid,
  p_vehicle_id uuid,
  p_assigned_from timestamptz default now()
)
returns public.driver_assignments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_role text;
  v_row public.driver_assignments;
  v_when timestamptz := coalesce(p_assigned_from, now());
begin
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  join public.profiles p on p.id = m.user_id
  join public.organisations o on o.id = m.organisation_id
  where m.user_id = auth.uid() and m.organisation_id = v_org
    and m.is_active and p.is_active and o.is_active
  for share of m, p, o;
  if not found then
    raise exception 'Active organisation membership required.' using errcode = '42501';
  end if;
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;
  if not ((v_role = 'administrator') or (v_role = 'manager')) then
    raise exception 'Only an Administrator or Manager can change vehicle assignments.';
  end if;

  -- Serialize assignment changes so the two partial unique indexes and history
  -- transitions remain deterministic during concurrent reassignment attempts.
  lock table public.driver_assignments in share row exclusive mode;

  if not exists (select 1 from public.drivers where id = p_driver_id and organisation_id = v_org and is_active) then
    raise exception 'The selected Driver is not active or does not exist.';
  end if;
  if not exists (select 1 from public.vehicles where id = p_vehicle_id and organisation_id = v_org and is_active) then
    raise exception 'The selected Vehicle is not active or does not exist.';
  end if;

  -- Idempotent when this exact pair is already current.
  select * into v_row
  from public.driver_assignments
  where organisation_id = v_org and driver_id = p_driver_id and vehicle_id = p_vehicle_id and is_active
  limit 1;
  if found then
    return v_row;
  end if;

  -- A Driver has at most one current Vehicle and a Vehicle at most one current Driver.
  -- Reject inconsistent historic links before ending any related assignment.
  if exists (
    select 1 from public.driver_assignments a
    where a.organisation_id = v_org and a.is_active
      and (a.driver_id = p_driver_id or a.vehicle_id = p_vehicle_id)
      and (
        not exists (select 1 from public.drivers d where d.id = a.driver_id and d.organisation_id = v_org)
        or not exists (select 1 from public.vehicles v where v.id = a.vehicle_id and v.organisation_id = v_org)
      )
  ) then
    raise exception 'Assignment not available.';
  end if;
  update public.driver_assignments
     set is_active = false,
         assigned_to = greatest(v_when, assigned_from),
         updated_at = now()
   where organisation_id = v_org and is_active
     and (driver_id = p_driver_id or vehicle_id = p_vehicle_id);

  insert into public.driver_assignments(organisation_id, driver_id, vehicle_id, assigned_from, is_active)
  values (v_org, p_driver_id, p_vehicle_id, v_when, true)
  returning * into v_row;

  return v_row;
end;
$$;

create or replace function public.fleet_end_driver_assignment(
  p_assignment_id uuid,
  p_assigned_to timestamptz default now()
)
returns public.driver_assignments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_role text;
  v_row public.driver_assignments;
  v_when timestamptz := coalesce(p_assigned_to, now());
begin
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  join public.profiles p on p.id = m.user_id
  join public.organisations o on o.id = m.organisation_id
  where m.user_id = auth.uid() and m.organisation_id = v_org
    and m.is_active and p.is_active and o.is_active
  for share of m, p, o;
  if not found then
    raise exception 'Active organisation membership required.' using errcode = '42501';
  end if;
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;
  if not ((v_role = 'administrator') or (v_role = 'manager')) then
    raise exception 'Only an Administrator or Manager can change vehicle assignments.';
  end if;

  select * into v_row
  from public.driver_assignments
  where id = p_assignment_id and organisation_id = v_org
  for update;
  if not found then
    raise exception 'Assignment not found.';
  end if;
  if not exists (select 1 from public.drivers where id = v_row.driver_id and organisation_id = v_org)
     or not exists (select 1 from public.vehicles where id = v_row.vehicle_id and organisation_id = v_org) then
    raise exception 'Assignment not found.';
  end if;
  if not v_row.is_active then
    return v_row;
  end if;

  update public.driver_assignments
     set is_active = false,
         assigned_to = greatest(v_when, assigned_from),
         updated_at = now()
   where id = p_assignment_id and organisation_id = v_org
   returning * into v_row;
  return v_row;
end;
$$;

create or replace function public.workshop_create_inspection(
  p_vehicle_id uuid,
  p_inspection_type text,
  p_mileage integer,
  p_notes text default '',
  p_technician_profile_id uuid default null
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_org uuid;
  v_role text;
  v_id uuid;
  v_registration text;
  v_fleet_number text;
  v_technician_name text := '';
  v_number text;
  v_is_technician boolean;
begin
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  join public.profiles p on p.id = m.user_id
  join public.organisations o on o.id = m.organisation_id
  where m.user_id = auth.uid() and m.organisation_id = v_org
    and m.is_active and p.is_active and o.is_active
  for share of m, p, o;
  if not found then
    raise exception 'Active organisation membership required.' using errcode = '42501';
  end if;
  v_is_technician := v_role = 'technician';
  if not (
    (v_role = 'administrator') or
    (v_role = 'manager') or
    (v_role = 'workshop') or
    v_is_technician
  ) then
    raise exception 'Workshop role required';
  end if;
  if p_mileage < 0 then raise exception 'Mileage must be non-negative'; end if;
  if p_inspection_type not in ('scheduledService','defectInspection','annualInspection','motPreparation','repairInspection','returnToService','driverDailyInspection') then
    raise exception 'Invalid inspection type';
  end if;

  select registration, fleet_number into v_registration, v_fleet_number
  from public.vehicles where id = p_vehicle_id and organisation_id = v_org and is_active = true;
  if not found then raise exception 'Active vehicle not found'; end if;

  if p_technician_profile_id is not null and not exists (
    select 1 from public.profiles p
    join public.organisation_memberships m on m.user_id = p.id
    where p.id = p_technician_profile_id and p.is_active
      and m.organisation_id = v_org and m.is_active and m.role = 'technician'
  ) then
    raise exception 'Active technician not found';
  end if;

  if v_is_technician then
    p_technician_profile_id := auth.uid();
  end if;

  if p_technician_profile_id is not null then
    select p.username into v_technician_name
    from public.profiles p
    join public.organisation_memberships m on m.user_id = p.id
    where p.id = p_technician_profile_id and p.is_active
      and m.organisation_id = v_org and m.is_active and m.role = 'technician';
    if not found then raise exception 'Active technician not found'; end if;
  end if;

  v_number := 'WI-' || to_char(current_date,'YYYYMMDD') || '-' || lpad(nextval('public.workshop_inspection_number_seq')::text,6,'0');
  insert into public.workshop_inspections(
    organisation_id, inspection_number, vehicle_id, registration, fleet_number, technician_profile_id,
    technician_name, inspection_type, status, vehicle_status, date_started, mileage,
    overall_result, notes
  ) values (
    v_org, v_number, p_vehicle_id, v_registration, coalesce(v_fleet_number,''), p_technician_profile_id,
    v_technician_name, p_inspection_type, 'inProgress', 'roadworthy', now(), p_mileage,
    'pending', coalesce(p_notes,'')
  ) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.workshop_create_inspection_from_template(
  p_vehicle_id uuid,
  p_template_id uuid,
  p_inspection_type text,
  p_mileage integer,
  p_notes text default '',
  p_technician_profile_id uuid default null
) returns uuid
language plpgsql security definer set search_path=public
as $$
declare
  v_org uuid;
  v_role text;
  v_id uuid; v_template_name text; v_template_type text;
begin
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  join public.profiles p on p.id = m.user_id
  join public.organisations o on o.id = m.organisation_id
  where m.user_id = auth.uid() and m.organisation_id = v_org
    and m.is_active and p.is_active and o.is_active
  for share of m, p, o;
  if not found then
    raise exception 'Active organisation membership required.' using errcode = '42501';
  end if;
  if v_role not in ('administrator', 'manager', 'workshop', 'technician') then
    raise exception 'Workshop role required';
  end if;
  select name, inspection_type into v_template_name, v_template_type
  from public.workshop_inspection_templates where id=p_template_id and organisation_id = v_org and is_active=true;
  if not found then raise exception 'Active inspection template not found'; end if;
  if v_template_type is not null and v_template_type <> p_inspection_type then raise exception 'Template does not match inspection type'; end if;
  v_id := public.workshop_create_inspection(p_vehicle_id,p_inspection_type,p_mileage,p_notes,p_technician_profile_id);
  update public.workshop_inspections set template_id=p_template_id, template_name=v_template_name where id=v_id and organisation_id = v_org;
  insert into public.workshop_inspection_items(
    organisation_id, inspection_id, template_item_id, category, section_title, title, response_type,
    status, mandatory, repair_required, notes, photo_count, display_order,
    critical_safety_item, auto_create_repair, repair_priority, roadworthy_impact,
    photo_required_on_fail, allow_notes
  )
  select v_org, v_id, ti.id, ti.category, ti.section_title, ti.title, ti.response_type,
    ti.default_status, ti.mandatory, false, '', 0, ti.display_order,
    ti.critical_safety_item, ti.auto_create_repair, ti.repair_priority,
    ti.roadworthy_impact, ti.photo_required_on_fail, ti.allow_notes
  from public.workshop_inspection_template_items ti
  where ti.template_id=p_template_id and ti.organisation_id = v_org order by ti.display_order;
  return v_id;
end; $$;

revoke all on function public.workshop_list_technicians() from public, anon;
grant execute on function public.workshop_list_technicians() to authenticated;
revoke all on function public.fleet_assign_driver(uuid,uuid,timestamptz) from public, anon;
grant execute on function public.fleet_assign_driver(uuid,uuid,timestamptz) to authenticated;
revoke all on function public.fleet_end_driver_assignment(uuid,timestamptz) from public, anon;
grant execute on function public.fleet_end_driver_assignment(uuid,timestamptz) to authenticated;
revoke all on function public.workshop_create_inspection(uuid,text,integer,text,uuid) from public, anon;
grant execute on function public.workshop_create_inspection(uuid,text,integer,text,uuid) to authenticated;
revoke all on function public.workshop_create_inspection_from_template(uuid,uuid,text,integer,text,uuid) from public, anon;
grant execute on function public.workshop_create_inspection_from_template(uuid,uuid,text,integer,text,uuid) to authenticated;

commit;
