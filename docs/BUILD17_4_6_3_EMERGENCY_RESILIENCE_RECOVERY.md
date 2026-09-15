# FleetIQ Build 17.4.6.3 — Emergency Resilience & Recovery

## Purpose

This build combines the read-resilience and emergency-write recovery engines while preserving FleetIQ's existing central Supabase architecture and original feature UI.

## Safety boundary

Emergency behavior is deliberately narrower than ordinary central operation:

- Connectivity and timeout failures may use a last-known-good read cache.
- Connectivity and timeout failures may queue an explicitly opted-in central mutation.
- Authentication, authorization/RLS, server, validation and unknown failures never fall back or queue automatically.
- Cache and queue records are isolated by an explicit `tenantId + userId` scope.
- Empty tenant/user scope is rejected rather than guessed.
- No SQLite fallback is introduced into central mode.
- No Supabase service-role key is introduced into Flutter.

## Read recovery

`CentralResilienceRuntime.runCached`:

1. Runs the central operation.
2. On success, records the connection as online and stores a JSON-safe last-known-good payload.
3. On connectivity/timeout, records offline state and returns cache when present and within optional maximum age.
4. On all other failures, rethrows without consulting cache.

`SharedPreferences` is used because it already exists in the FleetIQ project and works on Web, Windows and Android. It is resilience storage only; it does not replace Supabase as the source of truth.

## Emergency write queue

`CentralResilienceRuntime.runWrite`:

1. Generates an idempotency identifier before the central mutation starts.
2. Calls the supplied mutation with that identifier.
3. On success returns `CentralWriteDisposition.completed`.
4. On connectivity/timeout persists the JSON-safe mutation payload and returns `CentralWriteDisposition.queued`.
5. On authorization/RLS/server/unknown failures rethrows and does not queue.

Queue entries retain:

- idempotency id
- tenant/user scope
- operation name
- JSON-safe payload
- original creation time
- replay attempts
- last replay timestamp
- last replay error

The queue is capped at 500 entries by default. FleetIQ fails visibly if that limit is reached rather than dropping an emergency write silently.

## Replay and conflict policy

Replay is FIFO within the authenticated scope.

- Successful replay removes the queue entry.
- Renewed connectivity/timeout stops replay immediately, preserving order.
- A non-connectivity replay failure remains queued with an audit error and attempt count. Replay continues to later records so one validation/conflict record does not permanently block the entire queue.
- Missing replay handlers leave the item queued and record the reason.

Replay handlers receive the original queue/idempotency id. Server-side adapters should forward it to an idempotent RPC or equivalent duplicate-prevention mechanism where supported.

## Tenant isolation requirement

The resilience engine intentionally refuses to infer a company/tenant. Production write adapters must obtain the authenticated FleetIQ tenant and user identifiers from the current central auth/session model and create `CentralResilienceScope(tenantId: ..., userId: ...)`.

Do not use a constant, username, registration number, local SQLite id, or guessed metadata field as the tenant key.

## Activation status

The durable cache/queue/replay engine is supplied in this build and the existing 17.4.6.2 `run()` behavior remains backward compatible.

Emergency queued writes are **not globally activated in every Supabase gateway by this overlay**. Current recovered source material does not expose a trustworthy tenant/company identifier for every gateway. Activating writes without that identity would create cross-company recovery risk.

Before production activation of queued mutations, wire a `CentralResilienceScopeProvider` to FleetIQ's current authenticated tenant/user context and register exact replay handlers for each permitted operation.

## Operations intended for controlled activation

The catalog contains stable names for vehicles, drivers, assignments, Workshop inspection/repair mutations and Documents. This catalog is not permission: each adapter must still enforce the existing FleetIQ role/RLS rules.

## Evidence/documents

Binary document/evidence uploads are not placed into SharedPreferences by this build. Only JSON mutation metadata belongs in the emergency queue. Offline binary evidence requires a dedicated platform-safe encrypted file staging design and storage quota policy before activation.

## Disaster recovery

This build is application outage resilience. It does not replace Supabase database backups, PITR/restore, Storage recovery or migration backup procedures.
