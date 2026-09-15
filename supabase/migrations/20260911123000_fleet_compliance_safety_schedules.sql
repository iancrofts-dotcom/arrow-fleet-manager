-- FleetIQ Build 17.4.5
-- Vehicle statutory classification and recurring PSV/Taxi safety schedules.

alter table public.vehicles
  add column if not exists mot_type text not null default 'standard',
  add column if not exists psv_garage_check_enabled boolean not null default false,
  add column if not exists psv_garage_check_interval_weeks integer not null default 6,
  add column if not exists psv_garage_check_last_date date,
  add column if not exists psv_garage_check_due date,
  add column if not exists taxi_safety_check_enabled boolean not null default false,
  add column if not exists taxi_safety_check_interval_weeks integer not null default 6,
  add column if not exists taxi_safety_check_last_date date,
  add column if not exists taxi_safety_check_due date;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_mot_type_check'
      and conrelid = 'public.vehicles'::regclass
  ) then
    alter table public.vehicles
      add constraint vehicles_mot_type_check
      check (mot_type in ('standard', 'psv'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_psv_garage_interval_check'
      and conrelid = 'public.vehicles'::regclass
  ) then
    alter table public.vehicles
      add constraint vehicles_psv_garage_interval_check
      check (psv_garage_check_interval_weeks in (5, 6));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_taxi_safety_interval_check'
      and conrelid = 'public.vehicles'::regclass
  ) then
    alter table public.vehicles
      add constraint vehicles_taxi_safety_interval_check
      check (taxi_safety_check_interval_weeks in (5, 6));
  end if;
end
$$;

comment on column public.vehicles.mot_type is
  'standard or psv; controls FleetIQ statutory MOT labelling.';
comment on column public.vehicles.psv_garage_check_due is
  'Next scheduled PSV garage/safety inspection date.';
comment on column public.vehicles.taxi_safety_check_due is
  'Next scheduled Taxi/Private Hire safety inspection date.';
