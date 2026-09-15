-- Release-candidate safety lock: central Driver assignments are read-only
-- until assignment mutation flows and their RLS behavior have been separately
-- proven. Keep SELECT available under the existing role-scoped read policy.

revoke insert, update, delete on table public.driver_assignments
  from authenticated;
revoke all on table public.driver_assignments from anon;

drop policy if exists "fleet managers insert assignments"
  on public.driver_assignments;
drop policy if exists "fleet managers update assignments"
  on public.driver_assignments;

-- Be explicit about the intended client privilege for this release stage.
grant select on table public.driver_assignments to authenticated;
