-- FleetIQ Build 16: secured central Driver <-> Vehicle assignment operations.
-- History is append-only: assignments are ended, never deleted.
-- Ordinary authenticated clients retain SELECT only; mutations are RPC-only.

revoke insert, update, delete on table public.driver_assignments from authenticated;
revoke all on table public.driver_assignments from anon;
grant select on table public.driver_assignments to authenticated;

drop policy if exists "fleet managers insert assignments" on public.driver_assignments;
drop policy if exists "fleet managers update assignments" on public.driver_assignments;

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
  v_row public.driver_assignments;
  v_when timestamptz := coalesce(p_assigned_from, now());
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')) then
    raise exception 'Only an Administrator or Manager can change vehicle assignments.';
  end if;

  -- Serialize assignment changes so the two partial unique indexes and history
  -- transitions remain deterministic during concurrent reassignment attempts.
  lock table public.driver_assignments in share row exclusive mode;

  if not exists (select 1 from public.drivers where id = p_driver_id and is_active) then
    raise exception 'The selected Driver is not active or does not exist.';
  end if;
  if not exists (select 1 from public.vehicles where id = p_vehicle_id and is_active) then
    raise exception 'The selected Vehicle is not active or does not exist.';
  end if;

  -- Idempotent when this exact pair is already current.
  select * into v_row
  from public.driver_assignments
  where driver_id = p_driver_id and vehicle_id = p_vehicle_id and is_active
  limit 1;
  if found then
    return v_row;
  end if;

  -- A Driver has at most one current Vehicle and a Vehicle at most one current Driver.
  update public.driver_assignments
     set is_active = false,
         assigned_to = greatest(v_when, assigned_from),
         updated_at = now()
   where is_active
     and (driver_id = p_driver_id or vehicle_id = p_vehicle_id);

  insert into public.driver_assignments(driver_id, vehicle_id, assigned_from, is_active)
  values (p_driver_id, p_vehicle_id, v_when, true)
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
  v_row public.driver_assignments;
  v_when timestamptz := coalesce(p_assigned_to, now());
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')) then
    raise exception 'Only an Administrator or Manager can change vehicle assignments.';
  end if;

  select * into v_row
  from public.driver_assignments
  where id = p_assignment_id
  for update;
  if not found then
    raise exception 'Assignment not found.';
  end if;
  if not v_row.is_active then
    return v_row;
  end if;

  update public.driver_assignments
     set is_active = false,
         assigned_to = greatest(v_when, assigned_from),
         updated_at = now()
   where id = p_assignment_id
   returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.fleet_assign_driver(uuid,uuid,timestamptz) from public, anon;
revoke all on function public.fleet_end_driver_assignment(uuid,timestamptz) from public, anon;
grant execute on function public.fleet_assign_driver(uuid,uuid,timestamptz) to authenticated;
grant execute on function public.fleet_end_driver_assignment(uuid,timestamptz) to authenticated;
