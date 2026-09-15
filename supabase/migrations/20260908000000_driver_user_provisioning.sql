-- Central security audit used only by trusted provisioning infrastructure.
create table public.security_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid not null,
  action text not null check (action in ('driver_user_provisioned')),
  target_driver_id uuid not null,
  target_profile_id uuid,
  outcome text not null check (outcome in ('success', 'idempotent', 'failed')),
  failure_category text,
  created_at timestamptz not null default now(),
  constraint security_audit_failure_category_valid check (
    (outcome = 'failed' and failure_category is not null)
    or (outcome <> 'failed' and failure_category is null)
  )
);

alter table public.security_audit_events enable row level security;
revoke all on table public.security_audit_events from anon, authenticated;
