# Central drivers and assignments foundation

Production Driver screens and services remain SQLite-only. This foundation
does not select the new gateways at runtime and does not deploy the migration.

## Current architecture and identity audit

`Driver` and `DriverEntity` persist `id`, name, licence number/expiry, phone,
email, username, and active state. `DriverRepository` directly queries
`AppDatabase`; `DriverService` adds username generation, linked local User
creation/synchronisation, compensated add/update behavior, and deactivation.
Add, edit, details, list, compliance, assignment, and history screens all use
the local service.

The following relationships are local integer-only today and require dual
identity during their own cutovers: Users (`driver_id`), driver compliance,
driver documents, assignments, inspections/daily checks, defects/workshop
records, dashboard activity, reports, and calendar events. Driver and
assignment primary identities can become UUIDs centrally. Existing integer
columns must never receive derived or fabricated values from UUIDs.

There are two local assignment repository APIs (`features/drivers` and
`features/assignments`) over the same `driver_assignments` table. The table has
integer driver/vehicle IDs, `assigned_from`, nullable `assigned_to`, and
`active`; it has no declared foreign keys or uniqueness constraints. Services
query both directions, preserve ended rows for history, and reject a new
assignment when either participant already has an active assignment.
Reassignment ends the vehicle's current row before creating another. The
intended invariant is therefore both one current vehicle per driver and one
current driver per vehicle.

## Central design

`drivers` maps only current Driver fields. Compliance expiry fields remain in
the separate compliance domain. Licence number is required but deliberately
not unique because the current product has no such database rule. UUID is the
primary identity and nullable unique `legacy_id` supports deterministic import.

`driver_assignments` retains the current time fields as timestamptz values,
uses UUID foreign keys with restricted deletion, and preserves history. Two
partial unique indexes enforce both current-assignment invariants. State/date
checks require current rows to have no end and ended rows to have an end.
Reassignment and lifecycle operations must later run in one server-side
transaction/RPC: lock both participants, end conflicting current rows, then
insert the replacement. Driver or vehicle deactivation must end its current
assignment in that same transaction; history is never deleted.

`profiles.driver_id` is a nullable unique UUID foreign key to `drivers`.
`driver_legacy_id` remains temporarily for import compatibility. Normal clients
retain no profile INSERT/UPDATE/DELETE policy, so a Driver cannot self-link or
change role. Link creation/change is an audited server-side administration
operation.

RLS permits active Administrator and Manager users to read/write Drivers and
Assignments, Workshop to read both for legitimate operational identification,
and Driver users to read only their linked Driver and its assignments.
Anonymous access and client DELETE are absent. RLS remains the final authority.

## Import preflight (design only)

1. Export SQLite drivers, vehicles, and assignments without mutation.
2. Reject duplicate non-null driver usernames for manual resolution; also
   report duplicate licence numbers without assuming they are invalid.
3. Insert drivers with `legacy_id`; record the integer-to-UUID mapping.
4. Require every assignment driver and vehicle integer ID to resolve through
   the driver and vehicle `legacy_id` maps.
5. Reject orphan rows, invalid/reversed dates, active rows with end dates,
   ended rows without end dates, multiple active rows per driver, and multiple
   active rows per vehicle.
6. Insert assignments with their own `legacy_id` only after the complete
   preflight passes. Compare counts and histories transactionally.
7. Link profiles server-side using the verified driver mapping; never infer a
   link from a non-unique display name.

## Cutover blockers

- Add atomic central assignment/reassignment/deactivation operations.
- Decide and implement central Auth user provisioning/link administration.
- Introduce Driver data-source selection without local fallback.
- Convert linked User/session driver identity to dual identity.
- Migrate or explicitly guard compliance, documents, inspections, workshop,
  dashboard, reports, and calendar consumers before exposing central Drivers.
- Deploy and live-prove schema/RLS separately before production UI cutover.
