-- FleetIQ Build 17.4.4
-- User self-service profile details and human-readable Workshop audit names.

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists phone text;

-- Driver-linked accounts already have a trustworthy human name.
update public.profiles p
set full_name = btrim(d.first_name || ' ' || d.last_name)
from public.drivers d
where p.driver_id = d.id
  and coalesce(btrim(p.full_name), '') = '';

create or replace function public.fleet_update_my_profile(
  p_full_name text,
  p_phone text default ''
) returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_name text := btrim(coalesce(p_full_name, ''));
  v_phone text := btrim(coalesce(p_phone, ''));
begin
  if auth.uid() is null or not public.is_fleetiq_active() then
    raise exception 'Active FleetIQ account required';
  end if;
  if length(v_name) < 2 or position('@' in v_name) > 0 then
    raise exception 'Enter your name, not an email address';
  end if;

  update public.profiles
  set full_name = v_name,
      phone = nullif(v_phone, ''),
      updated_at = now()
  where id = auth.uid();

  -- Keep current Workshop assignment labels human-readable. Historical
  -- ownership IDs remain authoritative; this only refreshes the display label.
  update public.workshop_repair_jobs
  set technician_name = v_name
  where technician_profile_id = auth.uid()
    and status not in ('completed', 'cancelled');

  update public.workshop_inspections
  set technician_name = v_name,
      updated_at = now()
  where technician_profile_id = auth.uid()
    and status not in ('signedOff', 'cancelled');
end;
$$;

revoke all on function public.fleet_update_my_profile(text,text)
from public, anon;
grant execute on function public.fleet_update_my_profile(text,text)
to authenticated;

-- Keep the established RPC return shape (`username`) while returning the
-- technician's profile name whenever one has been supplied.
create or replace function public.workshop_list_technicians()
returns table(id uuid, username text)
language sql stable security definer set search_path = public
as $$
  select p.id,
         coalesce(nullif(btrim(p.full_name), ''), p.username) as username
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
  order by coalesce(nullif(btrim(p.full_name), ''), p.username);
$$;

create or replace function public.workshop_assign_inspection_technician(
  p_inspection_id uuid,
  p_technician_profile_id uuid
) returns void
language plpgsql security definer set search_path=public
as $$
declare v_name text := '';
begin
  if not (
    public.has_fleetiq_role('administrator') or
    public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop')
  ) then
    raise exception 'Workshop management role required';
  end if;
  if p_technician_profile_id is not null then
    select coalesce(nullif(btrim(full_name), ''), username)
    into v_name
    from public.profiles
    where id=p_technician_profile_id and is_active=true and role='technician';
    if not found then raise exception 'Active technician not found'; end if;
  end if;
  update public.workshop_inspections
  set technician_profile_id=p_technician_profile_id,
      technician_name=v_name
  where id=p_inspection_id and status not in ('signedOff','cancelled');
  if not found then raise exception 'Inspection not found or locked'; end if;
end;
$$;

create or replace function public.workshop_assign_repair_technician(
  p_repair_job_id uuid,
  p_technician_profile_id uuid
) returns void
language plpgsql security definer set search_path=public
as $$
declare v_name text := '';
begin
  if not (
    public.has_fleetiq_role('administrator') or
    public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop')
  ) then
    raise exception 'Workshop management role required';
  end if;
  if p_technician_profile_id is not null then
    select coalesce(nullif(btrim(full_name), ''), username)
    into v_name
    from public.profiles
    where id=p_technician_profile_id and is_active=true and role='technician';
    if not found then raise exception 'Active technician not found'; end if;
  end if;
  update public.workshop_repair_jobs
  set technician_profile_id=p_technician_profile_id,
      technician_name=v_name,
      status=case
        when p_technician_profile_id is null and status='assigned' then 'open'
        when p_technician_profile_id is not null and status='open' then 'assigned'
        else status
      end
  where id=p_repair_job_id and status not in ('completed','cancelled');
  if not found then raise exception 'Repair job not found or locked'; end if;
end;
$$;

-- Final Workshop closure records a human name. If an older account still has
-- an email address as its username, sign-off is stopped until My Profile has
-- been completed instead of writing an email address into the audit record.
create or replace function public.workshop_manager_sign_off_repair_job(
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
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
  ) then
    raise exception 'Workshop management role required';
  end if;
  if p_actual_hours < 0 or p_actual_cost < 0 then
    raise exception 'Repair actuals must be non-negative';
  end if;

  select coalesce(
           nullif(btrim(full_name), ''),
           case when position('@' in username) = 0 then nullif(btrim(username), '') end
         )
  into v_name
  from public.profiles
  where id=auth.uid() and is_active=true;

  if coalesce(v_name, '') = '' then
    raise exception 'Set your full name in My Profile before signing off repair jobs';
  end if;

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
    signed_off_name=v_name,
    signed_off_at=now()
  where id=p_repair_job_id
    and status='awaitingInspection'
  returning inspection_id into v_inspection_id;

  if v_inspection_id is null then
    raise exception 'Repair job must be Awaiting Inspection before manager sign-off';
  end if;

  if not exists (
    select 1
    from public.workshop_repair_jobs
    where inspection_id=v_inspection_id
      and status not in ('completed','cancelled')
  ) then
    update public.workshop_inspections
    set status='completed',
        date_completed=coalesce(date_completed,now()),
        vehicle_status=case
          when exists (
            select 1
            from public.workshop_repair_jobs
            where inspection_id=v_inspection_id
              and status='completed'
              and roadworthy=false
          ) then 'notRoadworthy'
          else 'roadworthy'
        end,
        updated_at=now()
    where id=v_inspection_id;
  end if;
end;
$$;

revoke all on function public.workshop_manager_sign_off_repair_job(uuid,boolean,numeric,numeric,text,text)
from public, anon;
grant execute on function public.workshop_manager_sign_off_repair_job(uuid,boolean,numeric,numeric,text,text)
to authenticated;
