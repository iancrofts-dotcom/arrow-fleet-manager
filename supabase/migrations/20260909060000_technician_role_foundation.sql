-- Central Workshop role foundation. This migration is intentionally separate
-- from the Workshop tables so PostgreSQL commits the enum value before later
-- RLS policies reference it.
alter type public.fleetiq_role add value if not exists 'technician';
