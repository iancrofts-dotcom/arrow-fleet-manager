-- FleetIQ central Workshop read foundation.
-- Release boundary: SELECT only. Client writes are deliberately not granted.

create table public.workshop_inspections (
  id uuid primary key default gen_random_uuid(),
  legacy_id integer unique,
  inspection_number text not null unique check (btrim(inspection_number) <> ''),
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  registration text not null check (btrim(registration) <> ''),
  fleet_number text not null default '',
  template_name text,
  technician_profile_id uuid references public.profiles(id) on delete set null,
  technician_name text not null default '',
  driver_id uuid references public.drivers(id) on delete set null,
  driver_name text,
  workshop_manager text,
  inspection_type text not null check (inspection_type in (
    'scheduledService', 'defectInspection', 'annualInspection',
    'motPreparation', 'repairInspection', 'returnToService',
    'driverDailyInspection'
  )),
  status text not null check (status in (
    'draft', 'inProgress', 'awaitingRepair', 'completed', 'signedOff', 'cancelled'
  )),
  vehicle_status text not null check (vehicle_status in (
    'roadworthy', 'notRoadworthy', 'awaitingRepair', 'underRepair', 'released'
  )),
  date_started timestamptz not null,
  date_completed timestamptz,
  mileage integer not null check (mileage >= 0),
  overall_result text not null check (overall_result in ('pending', 'pass', 'fail', 'advisory')),
  inspection_score integer not null default 0 check (inspection_score between 0 and 100),
  critical_failures integer not null default 0 check (critical_failures >= 0),
  advisories integer not null default 0 check (advisories >= 0),
  repairs_required integer not null default 0 check (repairs_required >= 0),
  labour_hours numeric(10,2) not null default 0 check (labour_hours >= 0),
  total_cost numeric(12,2) not null default 0 check (total_cost >= 0),
  notes text not null default '',
  technician_signature text,
  manager_signature text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workshop_inspection_dates_valid check (
    date_completed is null or date_completed >= date_started
  )
);

create table public.workshop_inspection_items (
  id uuid primary key default gen_random_uuid(),
  legacy_id integer unique,
  inspection_id uuid not null references public.workshop_inspections(id) on delete cascade,
  category text not null,
  section_title text,
  title text not null check (btrim(title) <> ''),
  response_type text not null default 'passFailNotApplicable',
  response_value text,
  status text not null check (status in ('notApplicable', 'pass', 'fail', 'advisory')),
  mandatory boolean not null default true,
  repair_required boolean not null default false,
  notes text not null default '',
  photo_count integer not null default 0 check (photo_count >= 0),
  display_order integer not null check (display_order >= 0)
);

create table public.workshop_repair_jobs (
  id uuid primary key default gen_random_uuid(),
  legacy_id integer unique,
  job_number text not null unique check (btrim(job_number) <> ''),
  inspection_id uuid not null references public.workshop_inspections(id) on delete restrict,
  inspection_item_id uuid references public.workshop_inspection_items(id) on delete set null,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  vehicle_registration text not null check (btrim(vehicle_registration) <> ''),
  title text not null check (btrim(title) <> ''),
  description text not null default '',
  priority text not null,
  status text not null,
  technician_profile_id uuid references public.profiles(id) on delete set null,
  technician_name text not null default '',
  parts_required boolean not null default false,
  estimated_hours numeric(10,2) not null default 0 check (estimated_hours >= 0),
  actual_hours numeric(10,2) not null default 0 check (actual_hours >= 0),
  estimated_cost numeric(12,2) not null default 0 check (estimated_cost >= 0),
  actual_cost numeric(12,2) not null default 0 check (actual_cost >= 0),
  roadworthy boolean not null default false,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  constraint workshop_repair_dates_valid check (
    (started_at is null or started_at >= created_at)
    and (completed_at is null or completed_at >= coalesce(started_at, created_at))
  )
);

create index workshop_inspections_vehicle_idx
  on public.workshop_inspections (vehicle_id, date_started desc);
create index workshop_inspections_status_idx
  on public.workshop_inspections (status, date_started desc);
create index workshop_inspections_technician_idx
  on public.workshop_inspections (technician_profile_id, date_started desc);
create index workshop_items_inspection_idx
  on public.workshop_inspection_items (inspection_id, display_order);
create index workshop_repair_jobs_inspection_idx
  on public.workshop_repair_jobs (inspection_id, created_at desc);
create index workshop_repair_jobs_vehicle_idx
  on public.workshop_repair_jobs (vehicle_id, created_at desc);
create index workshop_repair_jobs_technician_idx
  on public.workshop_repair_jobs (technician_profile_id, created_at desc);
create index workshop_repair_jobs_status_idx
  on public.workshop_repair_jobs (status, created_at desc);

create trigger set_workshop_inspections_updated_at
  before update on public.workshop_inspections
  for each row execute procedure public.set_updated_at();

alter table public.workshop_inspections enable row level security;
alter table public.workshop_inspection_items enable row level security;
alter table public.workshop_repair_jobs enable row level security;

revoke all on table public.workshop_inspections from anon, authenticated;
revoke all on table public.workshop_inspection_items from anon, authenticated;
revoke all on table public.workshop_repair_jobs from anon, authenticated;

grant select on table public.workshop_inspections to authenticated;
grant select on table public.workshop_inspection_items to authenticated;
grant select on table public.workshop_repair_jobs to authenticated;

create policy "workshop roles read inspections" on public.workshop_inspections
  for select to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
    or (
      public.has_fleetiq_role('technician')
      and technician_profile_id = auth.uid()
    )
  );

create policy "workshop roles read inspection items" on public.workshop_inspection_items
  for select to authenticated using (
    exists (
      select 1
      from public.workshop_inspections inspection
      where inspection.id = inspection_id
      and (
        public.has_fleetiq_role('administrator')
        or public.has_fleetiq_role('manager')
        or public.has_fleetiq_role('workshop')
        or (
          public.has_fleetiq_role('technician')
          and inspection.technician_profile_id = auth.uid()
        )
      )
    )
  );

create policy "workshop roles read repair jobs" on public.workshop_repair_jobs
  for select to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
    or (
      public.has_fleetiq_role('technician')
      and technician_profile_id = auth.uid()
    )
  );

-- No INSERT, UPDATE or DELETE grants/policies in this migration. Central
-- Workshop writes, evidence uploads, sign-off and template management remain
-- deliberately locked until their RLS and atomicity paths are separately proven.
