# FleetIQ Supabase foundation

Release 1 uses one company and a central PostgreSQL database, Supabase Auth,
Row Level Security, and private Storage. Flutter clients receive only the
project URL and anon key through `--dart-define`; service-role keys and
database credentials never belong in a client build.

The initial migration is planning-only. It introduces application profiles
alongside Supabase Auth and retains `legacy_id` for controlled SQLite import.
No production repository uses this schema yet.

The vehicle foundation migration adds the one-company Release 1
`public.vehicles` table. Central records use generated UUIDs; nullable unique
`legacy_id` values preserve SQLite integer identities solely for controlled
import and relationship mapping. Active administrators and managers can read,
insert, and update; active workshop users can read; drivers receive no broad
fleet access; and no client DELETE policy exists. Retirement is represented by
`is_active = false`.

The Flutter backend vehicle DTO, gateway, and repository power the Fleet
screens only in explicit Supabase mode. Local mode and dependent assignments,
documents, maintenance, compliance, calendar, inspections, and workshop flows
remain SQLite-backed. There is no automatic fallback or offline synchronization.
Future cutover must import vehicles, retain the legacy-to-UUID map, migrate all
dependent records, validate shared clients, and only then change production
repository selection.

`supabase_flutter` is present only for the opt-in client foundation. The app
still uses SQLite and does not initialize Supabase at startup. Development can
provide `FLEETIQ_SUPABASE_URL` and `FLEETIQ_SUPABASE_ANON_KEY` via
`--dart-define`; never ship a service-role key in Flutter.
