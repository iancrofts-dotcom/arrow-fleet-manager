-- Release 1 central driver and assignment foundation. Production Driver
-- screens remain on SQLite until a separately validated cutover.
create table public.drivers (
  id uuid primary key default gen_random_uuid(),
  legacy_id integer unique,
  first_name text not null check (btrim(first_name) <> ''),
  last_name text not null check (btrim(last_name) <> ''),
  licence_number text not null check (btrim(licence_number) <> ''),
  licence_expiry date,
  phone text,
  email text,
  username text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index drivers_name_idx on public.drivers (last_name, first_name);
create index drivers_username_idx on public.drivers (username) where username is not null;
create trigger set_drivers_updated_at before update on public.drivers
  for each row execute procedure public.set_updated_at();

alter table public.profiles
  add column driver_id uuid unique references public.drivers(id) on delete restrict;

create table public.driver_assignments (
  id uuid primary key default gen_random_uuid(),
  legacy_id integer unique,
  driver_id uuid not null references public.drivers(id) on delete restrict,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  assigned_from timestamptz not null,
  assigned_to timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint driver_assignments_dates_valid check (
    assigned_to is null or assigned_to >= assigned_from
  ),
  constraint driver_assignments_state_valid check (
    (is_active and assigned_to is null)
    or (not is_active and assigned_to is not null)
  )
);

create unique index driver_assignments_current_driver_uidx
  on public.driver_assignments (driver_id) where is_active;
create unique index driver_assignments_current_vehicle_uidx
  on public.driver_assignments (vehicle_id) where is_active;
create index driver_assignments_driver_history_idx
  on public.driver_assignments (driver_id, assigned_from desc);
create index driver_assignments_vehicle_history_idx
  on public.driver_assignments (vehicle_id, assigned_from desc);
create trigger set_driver_assignments_updated_at
  before update on public.driver_assignments
  for each row execute procedure public.set_updated_at();

alter table public.drivers enable row level security;
alter table public.driver_assignments enable row level security;

revoke all on table public.drivers from anon, authenticated;
revoke all on table public.driver_assignments from anon, authenticated;
grant select, insert, update on table public.drivers to authenticated;
grant select, insert, update on table public.driver_assignments to authenticated;

create policy "fleet roles read drivers" on public.drivers
  for select to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
    or (
      public.has_fleetiq_role('driver')
      and id = (select driver_id from public.profiles where id = auth.uid())
    )
  );
create policy "fleet managers insert drivers" on public.drivers
  for insert to authenticated with check (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')
  );
create policy "fleet managers update drivers" on public.drivers
  for update to authenticated using (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')
  ) with check (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')
  );

create policy "fleet roles read assignments" on public.driver_assignments
  for select to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
    or (
      public.has_fleetiq_role('driver')
      and driver_id = (select driver_id from public.profiles where id = auth.uid())
    )
  );
create policy "fleet managers insert assignments" on public.driver_assignments
  for insert to authenticated with check (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')
  );
create policy "fleet managers update assignments" on public.driver_assignments
  for update to authenticated using (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')
  ) with check (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')
  );

-- Deliberately no DELETE policies and no profile UPDATE policy. Linkage is
-- controlled server-side; operational history is ended, never client-deleted.
