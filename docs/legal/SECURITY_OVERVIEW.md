# FleetIQ Security Overview — Launch Candidate v2026-09-15.2

FleetIQ is operated by Ian Crofts trading as FleetIQ. The service uses a central Supabase backend for production data and is designed around organisation isolation rather than shared/local fallback.

Implemented application controls include authenticated access; real organisation tenancy; restrictive tenant row-level security; membership-specific built-in/custom roles; protected company ownership; tenant-scoped document paths; server-side privileged operations; tenant/user-scoped cached reads and approved offline queues; idempotent supported mutation replay; and no Supabase service-role key in Flutter clients.

Operational launch controls still require completion/verification in the production runbook: branded support/privacy email, administrator MFA policy where supported, production secrets management, Supabase backup/PITR selection and restore test, dependency/vulnerability review, release/signing controls, incident and personal-data-breach response, periodic access review, logging/monitoring configuration, business continuity and supplier reviews.

FleetIQ does not claim ISO 27001, Cyber Essentials, SOC 2 or another certification unless and until it has actually obtained that certification. Security information supplied to customers must accurately describe the current production configuration.
