-- Planning foundation only; no Flutter repository uses this schema yet.
create type public.fleetiq_role as enum (
  'administrator', 'manager', 'workshop', 'driver'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  legacy_id text unique,
  username text not null,
  role public.fleetiq_role not null,
  is_active boolean not null default true,
  driver_legacy_id integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
