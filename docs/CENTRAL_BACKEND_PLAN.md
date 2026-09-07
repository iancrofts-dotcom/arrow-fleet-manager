# Central backend plan

## Current architecture

FleetIQ is SQLite-authoritative: `AppDatabase`, feature repositories, and
services use `sqflite`; documents and inspection photos retain device-local
file paths. This prevents shared Windows/Web/Android authority.

## Release-1 target

Supabase Auth, PostgreSQL with RLS, and private Storage. Supabase Auth owns
credentials and sessions. An application profile owns role, active status,
display data, and optional driver link. Existing roles map directly to the
profile role enum; behavior is unchanged until migration.

## Storage and security

Private buckets: vehicle-documents, driver-documents, inspection-photos,
workshop-attachments, and driver-photos. Store object keys, never absolute
local paths; use authenticated/signed downloads. No service-role key, database
password, or plaintext password is ever shipped to Flutter.

## Transition sequence

1. Config/client foundation. 2. Auth/profile. 3. Vehicles remote repository.
4. Drivers, assignments, compliance. 5. Documents/storage. 6. Workshop.
7. Dashboard/calendar/reports. 8. Web blockers. 9. SQLite import. 10. release
validation. Keep SQLite as fallback until import and cross-platform validation
are complete; roll back by retaining the local authority path.

## Auth security model

`auth.users` owns credentials, password hashing, tokens, reset and invite
identity. `public.profiles` owns FleetIQ role, active state, display identifier,
optional driver link and migration identifiers; it never stores passwords.
New identities receive inactive driver profiles through a server-side trigger;
metadata cannot assign a privileged role. RLS permits only an active user to
read their own profile and grants no direct client writes. Future invite/role/
activation operations require an Edge Function or other privileged server path
with a service-role key held server-side only. Supabase refresh is separate
from FleetIQ's existing idle/absolute lock policy.

## Vehicle foundation

Release 1 is explicitly one-company: `public.vehicles` has no tenant or company
key. Its UUID `id` is the central identity; nullable unique `legacy_id` records
the former SQLite integer ID during controlled import. Relationships must be
translated through that mapping rather than treating the integer as a central
key.

| SQLite | Dart `Vehicle` | PostgreSQL | Type/nullability | Import note |
|---|---|---|---|---|
| `id` | `id` | `legacy_id` | integer, nullable/unique | Preserve only for import mapping; PostgreSQL `id` is a generated UUID. |
| `registration` | `registration` | `registration` | text, not null | Required in SQLite and add flow; normalize consistently before import. |
| `fleetNumber` | `fleetNumber` | `fleet_number` | text, not null | Current default list ordering field. |
| `make` | `make` | `make` | text, nullable | SQLite permits null; local mapper currently substitutes an empty string. |
| `model` | `model` | `model` | text, nullable | SQLite permits null; local mapper currently substitutes an empty string. |
| `year` | `year` | `manufacture_year` | integer, nullable | SQLite permits null; validate non-null imported values. |
| `vin` | `vin` | `vin` | text, nullable | SQLite permits null; do not invent a uniqueness rule before data audit. |
| `motExpiry` | `motExpiry` | `mot_expiry` | date, nullable | Convert stored ISO text to date-only. |
| `serviceDue` | `serviceDue` | `service_due` | date, nullable | Convert stored ISO text to date-only. |
| `taxiPlateNumber` | `taxiPlateNumber` | `taxi_plate_number` | text, nullable | Specialist taxi/private-hire field. |
| `taxiLicensingAuthority` | `taxiLicensingAuthority` | `taxi_licensing_authority` | text, nullable | Specialist taxi/private-hire field. |
| `taxiPlateIssueDate` | `taxiPlateIssueDate` | `taxi_plate_issue_date` | date, nullable | Convert stored ISO text to date-only. |
| `taxiPlateExpiry` | `taxiPlateExpiry` | `taxi_plate_expiry` | date, nullable | Drives calendar and compliance attention. |
| `active` | `active` | `is_active` | boolean, not null | Convert SQLite 0/1; retain inactive history. |
| — | — | `created_at` | timestamptz, not null | Generated centrally. |
| — | — | `updated_at` | timestamptz, not null | Maintained centrally by trigger. |

The Fleet screens select the backend vehicle repository only when
`FLEETIQ_BACKEND_MODE=supabase`; local mode and all vehicle-dependent features
outside the Fleet vertical slice remain SQLite-backed. Central vehicle details
hide local-only relationships. No offline synchronization exists. Later work must migrate
vehicles first, record every integer-to-UUID mapping, migrate dependent driver
assignments, inspections, maintenance, documents, defects, and workshop rows,
then validate cross-device behavior before switching repository selection.

Vehicle RLS mirrors current application authorization: active administrators
and managers read and write, active workshop users read only, and no client
role can delete. Drivers are not granted broad reads; assigned-vehicle access
must wait for the central assignment relationship and its scoped policy.

## Username vs email authentication migration

Current FleetIQ login is username/password; Supabase Auth is email/password.
Profiles retain the FleetIQ username, but no fake email address or plaintext
password migration is permitted. A later controlled migration must collect or
verify an email identity and invite/reset credentials before switching login.

## Parallel auth adapter status

FleetAuthAdapter, local and Supabase adapters, SDK gateway and explicit mode
factory are available. Local remains the production default and LoginScreen
remains local. Local uses usernames; remote uses email. No credentials were
migrated and a live Supabase/RLS proof is still required.

## Web blockers

`sqflite_common_ffi`, `dart:io`, `File`/`Directory`, `path_provider`, and
`open_filex` are storage/opening/report platform blockers. Replace them only
in the owning feature during the migration phases.

## Recommended next command

**Command #4B: add `supabase_flutter`, a guarded backend client initializer,
and unit tests for `BackendConfig`; do not migrate auth or repositories.**
