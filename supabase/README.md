# FleetIQ Supabase foundation

Release 1 uses one company and a central PostgreSQL database, Supabase Auth,
Row Level Security, and private Storage. Flutter clients receive only the
project URL and anon key through `--dart-define`; service-role keys and
database credentials never belong in a client build.

The initial migration is planning-only. It introduces application profiles
alongside Supabase Auth and retains `legacy_id` for controlled SQLite import.
No production repository uses this schema yet.

`supabase_flutter` is present only for the opt-in client foundation. The app
still uses SQLite and does not initialize Supabase at startup. Development can
provide `FLEETIQ_SUPABASE_URL` and `FLEETIQ_SUPABASE_ANON_KEY` via
`--dart-define`; never ship a service-role key in Flutter.
