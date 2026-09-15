-- FleetIQ Build 17: complete central Workshop repair workflow and template management.
-- Direct table mutation stays closed; all operational changes go through role-aware RPCs.

alter table public.workshop_repair_jobs
  add column if not exists work_notes text not null default '',
  add column if not exists parts_notes text not null default '',
  add column if not exists signed_off_by uuid references public.profiles(id) on delete set null,
  add column if not exists signed_off_name text not null default '',
  add column if not exists signed_off_at timestamptz;

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
  v_is_technician boolean := public.has_fleetiq_role('technician');
begin
  if not (
    public.has_fleetiq_role('administrator') or
    public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop') or
    v_is_technician
  ) then
    raise exception 'Workshop role required';
  end if;
  if p_mileage < 0 then raise exception 'Mileage must be non-negative'; end if;
  if p_inspection_type not in ('scheduledService','defectInspection','annualInspection','motPreparation','repairInspection','returnToService','driverDailyInspection') then
    raise exception 'Invalid inspection type';
  end if;

  select registration, fleet_number into v_registration, v_fleet_number
  from public.vehicles where id = p_vehicle_id and is_active = true;
  if not found then raise exception 'Active vehicle not found'; end if;

  if v_is_technician then
    p_technician_profile_id := auth.uid();
  end if;

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

create or replace function public.workshop_update_repair_job(
  p_repair_job_id uuid,
  p_status text,
  p_parts_required boolean,
  p_actual_hours numeric,
  p_actual_cost numeric,
  p_roadworthy boolean,
  p_work_notes text default '',
  p_parts_notes text default ''
) returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_assigned uuid;
  v_current_status text;
  v_is_manager boolean;
begin
  select technician_profile_id,status into v_assigned,v_current_status
  from public.workshop_repair_jobs where id=p_repair_job_id;
  if not found then raise exception 'Repair job not found'; end if;

  v_is_manager := public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop');
  if not (v_is_manager or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())) then
    raise exception 'Repair job write access denied';
  end if;
  if p_status not in ('open','assigned','inProgress','awaitingParts','awaitingInspection','completed','cancelled') then
    raise exception 'Invalid repair status';
  end if;
  if not v_is_manager and p_status in ('completed','cancelled') then
    raise exception 'Technicians must submit repairs for management sign-off';
  end if;
  if p_actual_hours < 0 or p_actual_cost < 0 then
    raise exception 'Repair actuals must be non-negative';
  end if;

  update public.workshop_repair_jobs set
    status=p_status,
    parts_required=coalesce(p_parts_required,false),
    actual_hours=p_actual_hours,
    actual_cost=p_actual_cost,
    roadworthy=coalesce(p_roadworthy,false),
    work_notes=coalesce(p_work_notes,''),
    parts_notes=coalesce(p_parts_notes,''),
    started_at=case when p_status in ('inProgress','awaitingParts','awaitingInspection','completed') then coalesce(started_at,now()) else started_at end,
    completed_at=case when p_status='completed' then coalesce(completed_at,now()) when p_status<>'completed' then null else completed_at end,
    signed_off_by=case when p_status='completed' then signed_off_by else null end,
    signed_off_name=case when p_status='completed' then signed_off_name else '' end,
    signed_off_at=case when p_status='completed' then signed_off_at else null end
  where id=p_repair_job_id;
end;
$$;

create or replace function public.workshop_sign_off_repair_job(
  p_repair_job_id uuid,
  p_roadworthy boolean,
  p_actual_hours numeric,
  p_actual_cost numeric,
  p_work_notes text default '',
  p_parts_notes text default ''
) returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_name text;
  v_inspection_id uuid;
begin
  if not (
    public.has_fleetiq_role('administrator') or
    public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop')
  ) then
    raise exception 'Workshop management role required';
  end if;
  if p_actual_hours < 0 or p_actual_cost < 0 then
    raise exception 'Repair actuals must be non-negative';
  end if;
  select username into v_name from public.profiles where id=auth.uid();

  update public.workshop_repair_jobs set
    status='completed',
    roadworthy=coalesce(p_roadworthy,false),
    actual_hours=p_actual_hours,
    actual_cost=p_actual_cost,
    work_notes=coalesce(p_work_notes,''),
    parts_notes=coalesce(p_parts_notes,''),
    started_at=coalesce(started_at,now()),
    completed_at=now(),
    signed_off_by=auth.uid(),
    signed_off_name=coalesce(v_name,''),
    signed_off_at=now()
  where id=p_repair_job_id
    and status='awaitingInspection'
  returning inspection_id into v_inspection_id;

  if v_inspection_id is null then
    raise exception 'Repair job must be awaiting sign-off';
  end if;

  if not exists (
    select 1 from public.workshop_repair_jobs
    where inspection_id=v_inspection_id and status not in ('completed','cancelled')
  ) then
    update public.workshop_inspections
    set status='completed',
        date_completed=coalesce(date_completed,now()),
        vehicle_status=case
          when exists (
            select 1 from public.workshop_repair_jobs
            where inspection_id=v_inspection_id and status='completed' and roadworthy=false
          ) then 'notRoadworthy'
          else 'roadworthy'
        end
    where id=v_inspection_id and status='awaitingRepair';
  end if;
end;
$$;

create or replace function public.workshop_save_template(
  p_template_id uuid,
  p_name text,
  p_description text,
  p_inspection_type text,
  p_is_active boolean,
  p_items jsonb
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
  v_item jsonb;
  v_order integer := 0;
begin
  if not (
    public.has_fleetiq_role('administrator') or
    public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop')
  ) then
    raise exception 'Workshop management role required';
  end if;
  if btrim(coalesce(p_name,''))='' then raise exception 'Template name is required'; end if;
  if p_inspection_type is not null and p_inspection_type not in ('scheduledService','defectInspection','annualInspection','motPreparation','repairInspection','returnToService','driverDailyInspection') then
    raise exception 'Invalid inspection type';
  end if;
  if jsonb_typeof(coalesce(p_items,'[]'::jsonb)) <> 'array' then
    raise exception 'Template items must be an array';
  end if;
  if jsonb_array_length(coalesce(p_items,'[]'::jsonb)) = 0 then
    raise exception 'Template requires at least one checklist item';
  end if;

  if p_template_id is null then
    insert into public.workshop_inspection_templates(name,description,inspection_type,template_version,is_default,is_active)
    values(btrim(p_name),coalesce(p_description,''),p_inspection_type,1,false,coalesce(p_is_active,true))
    returning id into v_id;
  else
    update public.workshop_inspection_templates
    set name=btrim(p_name), description=coalesce(p_description,''), inspection_type=p_inspection_type,
        template_version=template_version+1, is_active=coalesce(p_is_active,true)
    where id=p_template_id
    returning id into v_id;
    if v_id is null then raise exception 'Template not found'; end if;
    delete from public.workshop_inspection_template_items where template_id=v_id;
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    if btrim(coalesce(v_item->>'title',''))='' then raise exception 'Checklist item title is required'; end if;
    insert into public.workshop_inspection_template_items(
      template_id, section_title, category, title, description, response_type, mandatory,
      critical_safety_item, auto_create_repair, repair_priority, roadworthy_impact,
      photo_required_on_fail, allow_notes, default_status, display_order
    ) values (
      v_id,
      nullif(btrim(coalesce(v_item->>'section_title','')),''),
      coalesce(nullif(btrim(v_item->>'category'),''),'General'),
      btrim(v_item->>'title'),
      coalesce(v_item->>'description',''),
      coalesce(nullif(v_item->>'response_type',''),'passFailNotApplicable'),
      coalesce((v_item->>'mandatory')::boolean,true),
      coalesce((v_item->>'critical_safety_item')::boolean,false),
      coalesce((v_item->>'auto_create_repair')::boolean,true),
      coalesce(nullif(v_item->>'repair_priority',''),'medium'),
      coalesce(nullif(v_item->>'roadworthy_impact',''),'none'),
      coalesce((v_item->>'photo_required_on_fail')::boolean,false),
      coalesce((v_item->>'allow_notes')::boolean,true),
      coalesce(nullif(v_item->>'default_status',''),'notApplicable'),
      coalesce((v_item->>'display_order')::integer,v_order)
    );
    v_order := v_order + 1;
  end loop;
  return v_id;
end;
$$;

revoke insert,update,delete on public.workshop_repair_jobs from anon,authenticated;
revoke insert,update,delete on public.workshop_inspection_templates from anon,authenticated;
revoke insert,update,delete on public.workshop_inspection_template_items from anon,authenticated;

revoke all on function public.workshop_update_repair_job(uuid,text,boolean,numeric,numeric,boolean) from public,anon,authenticated;
revoke all on function public.workshop_update_repair_job(uuid,text,boolean,numeric,numeric,boolean,text,text) from public,anon;
revoke all on function public.workshop_sign_off_repair_job(uuid,boolean,numeric,numeric,text,text) from public,anon;
revoke all on function public.workshop_save_template(uuid,text,text,text,boolean,jsonb) from public,anon;
grant execute on function public.workshop_update_repair_job(uuid,text,boolean,numeric,numeric,boolean,text,text) to authenticated;
grant execute on function public.workshop_sign_off_repair_job(uuid,boolean,numeric,numeric,text,text) to authenticated;
grant execute on function public.workshop_save_template(uuid,text,text,text,boolean,jsonb) to authenticated;

-- Auto-promote failed checklist defects into unassigned repair jobs. This fires
-- only for rows written through the existing secured inspection-item RPC.
create or replace function public.workshop_auto_create_repair_from_defect()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vehicle_id uuid;
  v_registration text;
  v_number text;
begin
  if new.status='fail'
     and coalesce(new.auto_create_repair,false)=true
     and not exists (
       select 1 from public.workshop_repair_jobs repair
       where repair.inspection_item_id=new.id
         and repair.status <> 'cancelled'
     ) then
    select vehicle_id,registration into v_vehicle_id,v_registration
    from public.workshop_inspections where id=new.inspection_id;
    if found then
      v_number := 'RJ-' || to_char(current_date,'YYYYMMDD') || '-' ||
        lpad(nextval('public.workshop_job_number_seq')::text,6,'0');
      insert into public.workshop_repair_jobs(
        job_number,inspection_id,inspection_item_id,vehicle_id,vehicle_registration,
        title,description,priority,status,parts_required,estimated_hours,estimated_cost,roadworthy
      ) values (
        v_number,new.inspection_id,new.id,v_vehicle_id,v_registration,
        new.title,coalesce(new.notes,''),coalesce(new.repair_priority,'medium'),'open',false,0,0,false
      );
      update public.workshop_inspections
      set status='awaitingRepair',vehicle_status='awaitingRepair'
      where id=new.inspection_id and status not in ('signedOff','cancelled');
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists workshop_auto_create_repair_from_defect on public.workshop_inspection_items;
create trigger workshop_auto_create_repair_from_defect
after insert or update of status, auto_create_repair on public.workshop_inspection_items
for each row execute function public.workshop_auto_create_repair_from_defect();

create policy "technicians read active workshop vehicles"
on public.vehicles
for select to authenticated
using (
  public.has_fleetiq_role('technician')
  and is_active = true
);
