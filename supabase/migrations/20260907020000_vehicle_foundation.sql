-- Release 1 central vehicle foundation. SQLite remains authoritative until a
-- separately validated import and application cutover.
create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  legacy_id integer unique,
  registration text not null,
  fleet_number text not null,
  make text,
  model text,
  manufacture_year integer,
  vin text,
  mot_expiry date,
  service_due date,
  taxi_plate_number text,
  taxi_licensing_authority text,
  taxi_plate_issue_date date,
  taxi_plate_expiry date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vehicles_manufacture_year_valid check (
    manufacture_year is null or manufacture_year between 1886 and 9999
  )
);

create index vehicles_fleet_number_idx on public.vehicles (fleet_number);
create index vehicles_active_mot_expiry_idx
  on public.vehicles (mot_expiry)
  where is_active;
create index vehicles_active_service_due_idx
  on public.vehicles (service_due)
  where is_active;
create index vehicles_active_taxi_plate_expiry_idx
  on public.vehicles (taxi_plate_expiry)
  where is_active and taxi_plate_expiry is not null;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public
as $$ begin
  new.updated_at = now();
  return new;
end; $$;

create trigger set_vehicles_updated_at
  before update on public.vehicles
  for each row execute procedure public.set_updated_at();

alter table public.vehicles enable row level security;

create policy "fleet roles read vehicles" on public.vehicles
  for select to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
  );

create policy "fleet managers insert vehicles" on public.vehicles
  for insert to authenticated with check (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
  );

create policy "fleet managers update vehicles" on public.vehicles
  for update to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
  ) with check (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
  );

-- Deliberately no client DELETE policy. Vehicle retirement uses is_active.
