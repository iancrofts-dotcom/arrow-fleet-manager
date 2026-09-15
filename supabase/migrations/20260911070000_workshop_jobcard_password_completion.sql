-- FleetIQ Build 17.4: Workshop job-card completion, technician mileage,
-- assigned-repair evidence visibility, and reliable management sign-off.
-- Password changes/resets use Supabase Auth and require no database write policy.

alter table public.workshop_repair_jobs
  add column if not exists technician_mileage integer
  check (technician_mileage is null or technician_mileage > 0);

-- A technician assigned to a repair created from a Driver inspection needs to
-- read that defect's evidence even when the parent inspection itself was not
-- assigned to that technician.
drop policy if exists "technicians read assigned repair evidence" on public.fleet_documents;
create policy "technicians read assigned repair evidence"
on public.fleet_documents
for select to authenticated
using (
  public.has_fleetiq_role('technician')
  and inspection_item_id is not null
  and exists (
    select 1
    from public.workshop_repair_jobs repair
    where repair.inspection_item_id = fleet_documents.inspection_item_id
      and repair.technician_profile_id = auth.uid()
      and repair.status <> 'cancelled'
  )
);

-- Rebuild the private storage read rule so a technician can download the same
-- evidence object. Existing management, Workshop, Driver and inspection-tech
-- access remains intact.
drop policy if exists "fleet documents scoped read" on storage.objects;
create policy "fleet documents scoped read" on storage.objects
for select to authenticated using (
  bucket_id='fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (public.has_fleetiq_role('workshop') and split_part(name,'/',1) in ('workshop','vehicle','general'))
    or (
      public.has_fleetiq_role('technician')
      and split_part(name,'/',1)='workshop'
      and (
        exists (
          select 1
          from public.workshop_inspections wi
          where wi.id::text=split_part(name,'/',2)
            and wi.technician_profile_id=auth.uid()
        )
        or exists (
          select 1
          from public.workshop_repair_jobs repair
          where repair.inspection_id::text=split_part(name,'/',2)
            and repair.inspection_item_id::text=split_part(name,'/',3)
            and repair.technician_profile_id=auth.uid()
            and repair.status <> 'cancelled'
        )
      )
    )
    or (public.has_fleetiq_role('driver') and (
      (split_part(name,'/',1)='driver' and split_part(name,'/',2)=coalesce((select driver_id::text from public.profiles where id=auth.uid()),''))
      or (split_part(name,'/',1)='workshop' and exists(
        select 1 from public.workshop_inspections wi
        where wi.id::text=split_part(name,'/',2)
          and wi.driver_id=(select driver_id from public.profiles where id=auth.uid())
      ))
    ))
  )
);

-- V2 repair update keeps the same role boundary but adds a separate technician
-- odometer snapshot. It never overwrites the source inspection mileage.
create or replace function public.workshop_update_repair_job_v2(
  p_repair_job_id uuid,
  p_status text,
  p_parts_required boolean,
  p_actual_hours numeric,
  p_actual_cost numeric,
  p_roadworthy boolean,
  p_work_notes text default '',
  p_parts_notes text default '',
  p_technician_mileage integer default null
) returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_assigned uuid;
  v_is_manager boolean;
begin
  select technician_profile_id into v_assigned
  from public.workshop_repair_jobs
  where id=p_repair_job_id;
  if not found then raise exception 'Repair job not found'; end if;

  v_is_manager := public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop');

  if not (
    v_is_manager
    or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())
  ) then
    raise exception 'Repair job write access denied';
  end if;

  if p_status not in ('open','assigned','inProgress','awaitingParts','awaitingInspection','cancelled') then
    raise exception 'Invalid repair status';
  end if;
  if not v_is_manager and p_status in ('open','cancelled') then
    raise exception 'Technicians cannot reopen or cancel repair jobs';
  end if;
  if p_actual_hours < 0 or p_actual_cost < 0 then
    raise exception 'Repair actuals must be non-negative';
  end if;
  if p_technician_mileage is not null and p_technician_mileage <= 0 then
    raise exception 'Technician mileage must be greater than zero';
  end if;

  update public.workshop_repair_jobs set
    status=p_status,
    parts_required=coalesce(p_parts_required,false),
    actual_hours=p_actual_hours,
    actual_cost=p_actual_cost,
    roadworthy=coalesce(p_roadworthy,false),
    work_notes=coalesce(p_work_notes,''),
    parts_notes=coalesce(p_parts_notes,''),
    technician_mileage=coalesce(p_technician_mileage,technician_mileage),
    started_at=case
      when p_status in ('inProgress','awaitingParts','awaitingInspection')
        then coalesce(started_at,now())
      else started_at
    end,
    completed_at=null,
    signed_off_by=null,
    signed_off_name='',
    signed_off_at=null
  where id=p_repair_job_id;
end;
$$;

-- New unambiguous RPC name avoids any stale/overloaded PostgREST function
-- signature and owns final completion exclusively for management roles.
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

  select username into v_name
  from public.profiles
  where id=auth.uid() and is_active=true;

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

revoke all on function public.workshop_update_repair_job_v2(uuid,text,boolean,numeric,numeric,boolean,text,text,integer)
from public,anon;
grant execute on function public.workshop_update_repair_job_v2(uuid,text,boolean,numeric,numeric,boolean,text,text,integer)
to authenticated;

revoke all on function public.workshop_manager_sign_off_repair_job(uuid,boolean,numeric,numeric,text,text)
from public,anon;
grant execute on function public.workshop_manager_sign_off_repair_job(uuid,boolean,numeric,numeric,text,text)
to authenticated;
