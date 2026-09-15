-- FleetIQ central Workshop operational write API.
-- Direct table mutation remains revoked. All writes pass through narrowly scoped,
-- role-aware SECURITY DEFINER functions so multi-table operations remain atomic.

create sequence if not exists public.workshop_inspection_number_seq;
create sequence if not exists public.workshop_job_number_seq;
revoke all on sequence public.workshop_inspection_number_seq from public, anon, authenticated;
revoke all on sequence public.workshop_job_number_seq from public, anon, authenticated;

create or replace function public.workshop_list_technicians()
returns table(id uuid, username text)
language sql stable security definer set search_path = public
as $$
  select p.id, p.username
  from public.profiles p
  where public.is_fleetiq_active()
    and (
      public.has_fleetiq_role('administrator') or
      public.has_fleetiq_role('manager') or
      public.has_fleetiq_role('workshop') or
      (public.has_fleetiq_role('technician') and p.id = auth.uid())
    )
    and p.is_active = true
    and p.role = 'technician'
  order by p.username;
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
  v_id uuid;
  v_registration text;
  v_fleet_number text;
  v_technician_name text := '';
  v_number text;
begin
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')) then
    raise exception 'Workshop management role required';
  end if;
  if p_mileage < 0 then raise exception 'Mileage must be non-negative'; end if;
  if p_inspection_type not in ('scheduledService','defectInspection','annualInspection','motPreparation','repairInspection','returnToService','driverDailyInspection') then
    raise exception 'Invalid inspection type';
  end if;

  select registration, fleet_number into v_registration, v_fleet_number
  from public.vehicles where id = p_vehicle_id and is_active = true;
  if not found then raise exception 'Active vehicle not found'; end if;

  if p_technician_profile_id is not null then
    select username into v_technician_name from public.profiles
    where id = p_technician_profile_id and is_active = true and role = 'technician';
    if not found then raise exception 'Active technician not found'; end if;
  end if;

  v_number := 'WI-' || to_char(current_date,'YYYYMMDD') || '-' || lpad(nextval('public.workshop_inspection_number_seq')::text,6,'0');
  insert into public.workshop_inspections(
    inspection_number, vehicle_id, registration, fleet_number, technician_profile_id,
    technician_name, inspection_type, status, vehicle_status, date_started, mileage,
    overall_result, notes
  ) values (
    v_number, p_vehicle_id, v_registration, coalesce(v_fleet_number,''), p_technician_profile_id,
    v_technician_name, p_inspection_type, 'inProgress', 'roadworthy', now(), p_mileage,
    'pending', coalesce(p_notes,'')
  ) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.workshop_save_inspection_item(
  p_item_id uuid,
  p_inspection_id uuid,
  p_category text,
  p_section_title text,
  p_title text,
  p_response_type text,
  p_response_value text,
  p_status text,
  p_mandatory boolean,
  p_repair_required boolean,
  p_notes text,
  p_display_order integer
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
  v_assigned uuid;
  v_status text;
begin
  select technician_profile_id, status into v_assigned, v_status
  from public.workshop_inspections where id = p_inspection_id;
  if not found then raise exception 'Inspection not found'; end if;
  if not (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop') or
    (public.has_fleetiq_role('technician') and v_assigned = auth.uid())
  ) then raise exception 'Inspection write access denied'; end if;
  if v_status in ('signedOff','cancelled') then raise exception 'Inspection is locked'; end if;
  if btrim(coalesce(p_title,'')) = '' or btrim(coalesce(p_category,'')) = '' then raise exception 'Checklist title and category are required'; end if;
  if p_status not in ('notApplicable','pass','fail','advisory') then raise exception 'Invalid checklist status'; end if;
  if p_display_order < 0 then raise exception 'Invalid display order'; end if;

  if p_item_id is null then
    insert into public.workshop_inspection_items(
      inspection_id, category, section_title, title, response_type, response_value,
      status, mandatory, repair_required, notes, display_order
    ) values (
      p_inspection_id, btrim(p_category), nullif(btrim(coalesce(p_section_title,'')),''), btrim(p_title),
      coalesce(nullif(btrim(p_response_type),''),'passFailNotApplicable'), p_response_value,
      p_status, coalesce(p_mandatory,true), coalesce(p_repair_required,false), coalesce(p_notes,''), p_display_order
    ) returning id into v_id;
  else
    update public.workshop_inspection_items set
      category=btrim(p_category), section_title=nullif(btrim(coalesce(p_section_title,'')),''), title=btrim(p_title),
      response_type=coalesce(nullif(btrim(p_response_type),''),'passFailNotApplicable'), response_value=p_response_value,
      status=p_status, mandatory=coalesce(p_mandatory,true), repair_required=coalesce(p_repair_required,false),
      notes=coalesce(p_notes,''), display_order=p_display_order
    where id=p_item_id and inspection_id=p_inspection_id returning id into v_id;
    if v_id is null then raise exception 'Checklist item not found'; end if;
  end if;
  return v_id;
end;
$$;

create or replace function public.workshop_create_repair_job(
  p_inspection_id uuid,
  p_inspection_item_id uuid,
  p_title text,
  p_description text default '',
  p_priority text default 'medium',
  p_technician_profile_id uuid default null,
  p_parts_required boolean default false,
  p_estimated_hours numeric default 0,
  p_estimated_cost numeric default 0
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid; v_vehicle_id uuid; v_registration text; v_assigned uuid; v_inspection_status text;
  v_technician_name text := ''; v_number text;
begin
  select vehicle_id, registration, technician_profile_id, status
    into v_vehicle_id, v_registration, v_assigned, v_inspection_status
  from public.workshop_inspections where id=p_inspection_id;
  if not found then raise exception 'Inspection not found'; end if;
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop') or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())) then
    raise exception 'Repair creation access denied';
  end if;
  if v_inspection_status in ('signedOff','cancelled') then raise exception 'Inspection is locked'; end if;
  if btrim(coalesce(p_title,''))='' then raise exception 'Repair title is required'; end if;
  if p_priority not in ('low','medium','high','critical') then raise exception 'Invalid repair priority'; end if;
  if p_estimated_hours < 0 or p_estimated_cost < 0 then raise exception 'Repair estimates must be non-negative'; end if;
  if p_inspection_item_id is not null and not exists(select 1 from public.workshop_inspection_items where id=p_inspection_item_id and inspection_id=p_inspection_id) then
    raise exception 'Checklist item does not belong to inspection';
  end if;
  if p_technician_profile_id is not null then
    select username into v_technician_name from public.profiles where id=p_technician_profile_id and is_active=true and role='technician';
    if not found then raise exception 'Active technician not found'; end if;
  elsif v_assigned is not null then
    p_technician_profile_id := v_assigned;
    select username into v_technician_name from public.profiles where id=v_assigned;
  end if;
  v_number := 'RJ-' || to_char(current_date,'YYYYMMDD') || '-' || lpad(nextval('public.workshop_job_number_seq')::text,6,'0');
  insert into public.workshop_repair_jobs(job_number,inspection_id,inspection_item_id,vehicle_id,vehicle_registration,title,description,priority,status,technician_profile_id,technician_name,parts_required,estimated_hours,estimated_cost)
  values(v_number,p_inspection_id,p_inspection_item_id,v_vehicle_id,v_registration,btrim(p_title),coalesce(p_description,''),p_priority,case when p_technician_profile_id is null then 'open' else 'assigned' end,p_technician_profile_id,v_technician_name,coalesce(p_parts_required,false),p_estimated_hours,p_estimated_cost)
  returning id into v_id;
  update public.workshop_inspections set status='awaitingRepair', vehicle_status='awaitingRepair' where id=p_inspection_id and status not in ('signedOff','cancelled');
  return v_id;
end;
$$;

create or replace function public.workshop_update_repair_job(
  p_repair_job_id uuid,
  p_status text,
  p_parts_required boolean,
  p_actual_hours numeric,
  p_actual_cost numeric,
  p_roadworthy boolean
) returns void
language plpgsql security definer set search_path = public
as $$
declare v_assigned uuid; v_current_status text; v_is_manager boolean;
begin
  select technician_profile_id,status into v_assigned,v_current_status from public.workshop_repair_jobs where id=p_repair_job_id;
  if not found then raise exception 'Repair job not found'; end if;
  v_is_manager := public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop');
  if not (v_is_manager or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())) then raise exception 'Repair job write access denied'; end if;
  if p_status not in ('open','assigned','inProgress','awaitingParts','awaitingInspection','completed','cancelled') then raise exception 'Invalid repair status'; end if;
  if not v_is_manager and p_status='cancelled' then raise exception 'Technicians cannot cancel repair jobs'; end if;
  if p_actual_hours < 0 or p_actual_cost < 0 then raise exception 'Repair actuals must be non-negative'; end if;
  update public.workshop_repair_jobs set
    status=p_status, parts_required=coalesce(p_parts_required,false), actual_hours=p_actual_hours,
    actual_cost=p_actual_cost, roadworthy=coalesce(p_roadworthy,false),
    started_at=case when p_status in ('inProgress','awaitingParts','awaitingInspection','completed') then coalesce(started_at,now()) else started_at end,
    completed_at=case when p_status='completed' then coalesce(completed_at,now()) when p_status<>'completed' then null else completed_at end
  where id=p_repair_job_id;
end;
$$;

create or replace function public.workshop_assign_inspection_technician(p_inspection_id uuid,p_technician_profile_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_name text := '';
begin
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')) then raise exception 'Workshop management role required'; end if;
  if p_technician_profile_id is not null then select username into v_name from public.profiles where id=p_technician_profile_id and is_active=true and role='technician'; if not found then raise exception 'Active technician not found'; end if; end if;
  update public.workshop_inspections set technician_profile_id=p_technician_profile_id, technician_name=v_name where id=p_inspection_id and status not in ('signedOff','cancelled');
  if not found then raise exception 'Inspection not found or locked'; end if;
end; $$;

create or replace function public.workshop_assign_repair_technician(p_repair_job_id uuid,p_technician_profile_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_name text := '';
begin
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')) then raise exception 'Workshop management role required'; end if;
  if p_technician_profile_id is not null then select username into v_name from public.profiles where id=p_technician_profile_id and is_active=true and role='technician'; if not found then raise exception 'Active technician not found'; end if; end if;
  update public.workshop_repair_jobs set technician_profile_id=p_technician_profile_id, technician_name=v_name, status=case when p_technician_profile_id is null and status='assigned' then 'open' when p_technician_profile_id is not null and status='open' then 'assigned' else status end where id=p_repair_job_id and status not in ('completed','cancelled');
  if not found then raise exception 'Repair job not found or locked'; end if;
end; $$;

create or replace function public.workshop_complete_inspection(p_inspection_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_assigned uuid; v_status text; v_fail int; v_adv int; v_repairs int; v_outstanding int; v_total int; v_score int; v_username text;
begin
  select technician_profile_id,status into v_assigned,v_status from public.workshop_inspections where id=p_inspection_id;
  if not found then raise exception 'Inspection not found'; end if;
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop') or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())) then raise exception 'Inspection completion access denied'; end if;
  if v_status in ('signedOff','cancelled') then raise exception 'Inspection is locked'; end if;
  select count(*), count(*) filter(where status='fail'), count(*) filter(where status='advisory'), count(*) filter(where repair_required=true)
    into v_total,v_fail,v_adv,v_repairs from public.workshop_inspection_items where inspection_id=p_inspection_id;
  if v_total=0 then raise exception 'Inspection requires at least one checklist item'; end if;
  select count(*) into v_outstanding from public.workshop_repair_jobs where inspection_id=p_inspection_id and status not in ('completed','cancelled');
  v_score := greatest(0, least(100, 100-(v_fail*20)-(v_adv*5)));
  select username into v_username from public.profiles where id=auth.uid();
  update public.workshop_inspections set
    overall_result=case when v_fail>0 then 'fail' when v_adv>0 then 'advisory' else 'pass' end,
    inspection_score=v_score, critical_failures=v_fail, advisories=v_adv, repairs_required=v_repairs,
    status=case when v_outstanding>0 then 'awaitingRepair' else 'completed' end,
    vehicle_status=case when v_outstanding>0 then 'awaitingRepair' when v_fail>0 then 'notRoadworthy' else 'roadworthy' end,
    date_completed=case when v_outstanding=0 then now() else null end,
    technician_signature=coalesce(technician_signature,v_username)
  where id=p_inspection_id;
end; $$;

create or replace function public.workshop_sign_off_inspection(p_inspection_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_username text;
begin
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')) then raise exception 'Inspection sign-off role required'; end if;
  if exists(select 1 from public.workshop_repair_jobs where inspection_id=p_inspection_id and status not in ('completed','cancelled')) then raise exception 'Outstanding repair jobs must be resolved before sign-off'; end if;
  if exists(
    select 1 from public.workshop_inspections inspection
    where inspection.id=p_inspection_id and inspection.overall_result='fail'
      and not exists(
        select 1 from public.workshop_repair_jobs repair
        where repair.inspection_id=p_inspection_id and repair.status='completed' and repair.roadworthy=true
      )
  ) then raise exception 'Failed inspection requires a completed roadworthy repair before sign-off'; end if;
  select username into v_username from public.profiles where id=auth.uid();
  update public.workshop_inspections set status='signedOff', vehicle_status='released', manager_signature=v_username, date_completed=coalesce(date_completed,now()) where id=p_inspection_id and status='completed';
  if not found then raise exception 'Inspection must be completed before sign-off'; end if;
end; $$;

-- Keep direct mutation closed even after this migration.
revoke insert, update, delete on public.workshop_inspections from anon, authenticated;
revoke insert, update, delete on public.workshop_inspection_items from anon, authenticated;
revoke insert, update, delete on public.workshop_repair_jobs from anon, authenticated;

revoke all on function public.workshop_list_technicians() from public, anon;
revoke all on function public.workshop_create_inspection(uuid,text,integer,text,uuid) from public, anon;
revoke all on function public.workshop_save_inspection_item(uuid,uuid,text,text,text,text,text,text,boolean,boolean,text,integer) from public, anon;
revoke all on function public.workshop_create_repair_job(uuid,uuid,text,text,text,uuid,boolean,numeric,numeric) from public, anon;
revoke all on function public.workshop_update_repair_job(uuid,text,boolean,numeric,numeric,boolean) from public, anon;
revoke all on function public.workshop_assign_inspection_technician(uuid,uuid) from public, anon;
revoke all on function public.workshop_assign_repair_technician(uuid,uuid) from public, anon;
revoke all on function public.workshop_complete_inspection(uuid) from public, anon;
revoke all on function public.workshop_sign_off_inspection(uuid) from public, anon;

grant execute on function public.workshop_list_technicians() to authenticated;
grant execute on function public.workshop_create_inspection(uuid,text,integer,text,uuid) to authenticated;
grant execute on function public.workshop_save_inspection_item(uuid,uuid,text,text,text,text,text,text,boolean,boolean,text,integer) to authenticated;
grant execute on function public.workshop_create_repair_job(uuid,uuid,text,text,text,uuid,boolean,numeric,numeric) to authenticated;
grant execute on function public.workshop_update_repair_job(uuid,text,boolean,numeric,numeric,boolean) to authenticated;
grant execute on function public.workshop_assign_inspection_technician(uuid,uuid) to authenticated;
grant execute on function public.workshop_assign_repair_technician(uuid,uuid) to authenticated;
grant execute on function public.workshop_complete_inspection(uuid) to authenticated;
grant execute on function public.workshop_sign_off_inspection(uuid) to authenticated;
