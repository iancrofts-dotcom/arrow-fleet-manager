# FleetIQ Build 17.4.6 — Resilience & Recovery

## 17.4.6.1 — Central resilience foundation

This increment is deliberately additive and contains no automatic local fallback.

Goals:
- represent central connection state consistently;
- distinguish true network/timeout loss from authentication, authorization, RLS and server failures;
- provide an operation guard that records central availability while preserving the existing error contract;
- establish tests proving non-connectivity errors never trigger an offline state.

Release boundary:
- no SQLite fallback;
- no offline writes;
- no queued mutations;
- no Supabase schema migration;
- no UI/navigation change;
- no service-role credential in Flutter.

## Planned 17.4.6.2 — Read resilience and visible status

After 17.4.6.1 passes the normal development gate:
- wire the tracker into proven central gateways/repositories;
- add a non-invasive central connection-status surface/banner;
- preserve existing FleetIQ screens and workflows;
- add read-only last-known-good emergency snapshots where safe;
- keep central mode isolated from normal SQLite services.

## Planned 17.4.6.3 — Emergency write queue and reconciliation

Only after read resilience is proven:
- durable queued mutation model with idempotency IDs;
- explicit Emergency Local Mode;
- controlled replay after reconnection;
- conflict detection before applying queued changes;
- never blindly overwrite newer Supabase records.

## Planned 17.4.6.4 — Backup, restore and recovery runbook

- Supabase backup/restore procedure;
- recovery validation and audit logging;
- commercial operational runbook;
- disaster-recovery test cases ready for full RC testing.
