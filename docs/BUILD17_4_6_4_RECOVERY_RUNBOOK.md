# FleetIQ Build 17.4.6.4 — Commercial Recovery Hardening

## Purpose

Build 17.4.6.4 hardens the emergency-resilience engine delivered in 17.4.6.3. It deliberately fails closed until FleetIQ has a server-authoritative organisation/tenant identifier for the authenticated user.

## Why activation is blocked

The current central sources available for this build prove authenticated profiles and role/RLS paths, but do not prove an organisation identifier on every operational record or mutation. Activating a durable offline queue using a guessed `default` company would be unsafe for a commercial multi-company release.

The activation policy therefore requires both:

- a non-empty authenticated user ID; and
- a non-placeholder, server-authoritative tenant/organisation ID.

No screen, gateway, or normal central operation is redirected to SQLite.

## Recovery procedure

1. Confirm Supabase service health and application connectivity.
2. Confirm the signed-in FleetIQ account has been revalidated.
3. Resolve the organisation/tenant identity from the server-authoritative membership model.
4. Count pending mutations for that exact tenant + user scope.
5. Replay in stored creation order.
6. Stop on renewed connectivity failure.
7. Leave authorization, validation, server, or conflict failures in the queue for explicit review.
8. Confirm pending count reaches zero before clearing emergency state.
9. Never delete an unresolved queue merely to make the application appear recovered.

## Database backup / restore commercial runbook

Before production schema changes:

1. Confirm the Supabase project has an appropriate managed backup/PITR policy for the commercial tier in use.
2. Record the migration version currently deployed.
3. Export/retain the migration set in source control/release artifacts.
4. Take/verify a recoverable database backup before destructive or high-risk migrations.
5. Treat Storage objects separately from PostgreSQL backups; verify the recovery strategy for FleetIQ documents and Workshop evidence.
6. Perform restore drills in a non-production project/environment.
7. Validate authentication, profiles, fleet data, documents, Workshop relationships, RLS, and audit history after restore.
8. Record recovery point, recovery time, operator, result, and any data gap.

## Required next schema stage before live emergency writes

FleetIQ needs a real organisation model, not a client-supplied company string. The required server architecture is:

`auth.users -> organisation_memberships -> organisations -> organisation-scoped operational records`

RLS and privileged RPCs must derive organisation access from authenticated membership. Once that exists and current central write gateways expose/derive that scope safely, the 17.4.6.3 queue can be activated on production mutations.

## Release boundary

This build does not add or deploy a Supabase migration, does not enable automatic offline production writes, does not add a service-role key to Flutter, and does not weaken RLS or authentication failures into offline mode.
