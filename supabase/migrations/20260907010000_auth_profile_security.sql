-- Auth/profile security foundation. No business tables or client write policy.
create or replace function public.current_fleetiq_role()
returns public.fleetiq_role
language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.is_fleetiq_active()
returns boolean
language sql stable security definer set search_path = public
as $$ select coalesce((select is_active from public.profiles where id = auth.uid()), false) $$;

create or replace function public.has_fleetiq_role(required_role public.fleetiq_role)
returns boolean
language sql stable security definer set search_path = public
as $$ select public.is_fleetiq_active() and public.current_fleetiq_role() = required_role $$;

create or replace function public.create_fleetiq_profile()
returns trigger language plpgsql security definer set search_path = public
as $$ begin
  insert into public.profiles (id, username, role, is_active)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', new.email, new.id::text), 'driver', false);
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users for each row execute procedure public.create_fleetiq_profile();

create policy "active users read own profile" on public.profiles
  for select to authenticated using (id = auth.uid() and public.is_fleetiq_active());

-- No insert/update/delete policy: normal clients cannot set role, active state,
-- or driver linkage. Future privileged server-side operations own those writes.
