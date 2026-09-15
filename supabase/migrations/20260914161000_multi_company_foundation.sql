-- FleetIQ Build 17.4.6.19
-- Multi-company management foundation.
--
-- Moves effective role/custom-role identity onto organisation membership while
-- keeping profile mirrors for backward compatibility with existing screens and
-- server workflows. Active-company switches refresh those mirrors atomically.

alter table public.organisation_memberships
  add column if not exists role text,
  add column if not exists custom_role_id uuid references public.custom_roles(id) on delete set null;

update public.organisation_memberships m
   set role = coalesce(m.role, p.role::text),
       custom_role_id = coalesce(m.custom_role_id, p.custom_role_id)
  from public.profiles p
 where p.id = m.user_id;

update public.organisation_memberships
   set role = 'manager'
 where role is null;

alter table public.organisation_memberships
  alter column role set not null;

alter table public.organisation_memberships
  drop constraint if exists organisation_memberships_role_check;
alter table public.organisation_memberships
  add constraint organisation_memberships_role_check
  check (role in ('administrator', 'manager', 'workshop', 'technician', 'driver'));

create index if not exists organisation_memberships_custom_role_id_idx
  on public.organisation_memberships(custom_role_id);

create or replace function public.fleet_membership_access_defaults()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_custom uuid;
begin
  if new.role is null then
    select p.role::text, p.custom_role_id into v_role, v_custom
    from public.profiles p where p.id = new.user_id;
    new.role := coalesce(v_role, 'manager');
    if new.custom_role_id is null then new.custom_role_id := v_custom; end if;
  end if;
  return new;
end;
$$;

drop trigger if exists fleet_membership_access_defaults_trigger on public.organisation_memberships;
create trigger fleet_membership_access_defaults_trigger
before insert or update on public.organisation_memberships
for each row execute function public.fleet_membership_access_defaults();

create or replace function public.fleet_sync_profile_access_to_active_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.active_organisation_id is not null then
    update public.organisation_memberships
       set role = new.role::text,
           custom_role_id = new.custom_role_id,
           updated_at = now()
     where organisation_id = new.active_organisation_id
       and user_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists fleet_profile_access_membership_sync_trigger on public.profiles;
create trigger fleet_profile_access_membership_sync_trigger
after update of role, custom_role_id on public.profiles
for each row execute function public.fleet_sync_profile_access_to_active_membership();

create or replace function public.fleet_current_access_profile()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_user uuid := auth.uid();
  v_org uuid;
  v_result jsonb;
begin
  if v_user is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  v_org := public.fleet_current_organisation_id();

  select jsonb_build_object(
    'id', p.id,
    'username', p.username,
    'role', m.role,
    'is_active', (p.is_active and m.is_active),
    'driver_legacy_id', p.driver_legacy_id,
    'driver_id', p.driver_id,
    'custom_role_id', m.custom_role_id,
    'custom_roles', case
      when r.id is null then null
      else jsonb_build_object(
        'name', r.name,
        'permissions', r.permissions
      )
    end
  )
  into v_result
  from public.profiles p
  join public.organisation_memberships m
    on m.user_id = p.id and m.organisation_id = v_org
  left join public.custom_roles r
    on r.id = m.custom_role_id and r.organisation_id = v_org and r.is_active
  where p.id = v_user;

  if v_result is null then
    raise exception 'Active FleetIQ organisation membership required.' using errcode = '42501';
  end if;
  return v_result;
end;
$$;

revoke all on function public.fleet_current_access_profile() from public;
grant execute on function public.fleet_current_access_profile() to authenticated;

create or replace function public.fleet_has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select case
    when m.role = 'administrator' then true
    when m.custom_role_id is null then true
    else exists (
      select 1
      from public.custom_roles r
      where r.id = m.custom_role_id
        and r.organisation_id = m.organisation_id
        and r.is_active
        and r.permissions ? p_permission
    )
  end
  from public.organisation_memberships m
  join public.profiles p on p.id = m.user_id
  where m.user_id = auth.uid()
    and m.organisation_id = public.fleet_current_organisation_id()
    and m.is_active
    and p.is_active;
$$;

revoke all on function public.fleet_has_permission(text) from public;
grant execute on function public.fleet_has_permission(text) to authenticated;

create or replace function public.fleet_set_active_organisation(
  p_organisation_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_membership public.organisation_memberships%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  select m.* into v_membership
  from public.organisation_memberships m
  join public.organisations o on o.id = m.organisation_id
  where m.user_id = auth.uid()
    and m.organisation_id = p_organisation_id
    and m.is_active
    and o.is_active;

  if not found then
    raise exception 'Organisation membership not available.' using errcode = '42501';
  end if;

  update public.profiles
     set active_organisation_id = p_organisation_id,
         role = v_membership.role::public.fleetiq_role,
         custom_role_id = v_membership.custom_role_id,
         updated_at = now()
   where id = auth.uid();
end;
$$;

revoke all on function public.fleet_set_active_organisation(uuid) from public;
grant execute on function public.fleet_set_active_organisation(uuid) to authenticated;

create or replace function public.fleet_list_my_organisations()
returns table (
  id uuid,
  name text,
  slug text,
  is_active boolean,
  is_current boolean
)
language sql
stable
security definer
set search_path = public, auth
as $$
  select o.id,
         o.name,
         o.slug,
         o.is_active,
         (p.active_organisation_id = o.id) as is_current
  from public.organisation_memberships m
  join public.organisations o on o.id = m.organisation_id
  join public.profiles p on p.id = auth.uid()
  where m.user_id = auth.uid()
    and m.is_active
    and o.is_active
  order by o.name;
$$;

revoke all on function public.fleet_list_my_organisations() from public;
grant execute on function public.fleet_list_my_organisations() to authenticated;

create or replace function public.fleet_create_organisation(
  p_name text,
  p_slug text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user uuid := auth.uid();
  v_current uuid;
  v_role text;
  v_org public.organisations%rowtype;
begin
  if v_user is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  v_current := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  where m.user_id = v_user and m.organisation_id = v_current and m.is_active;

  if v_role <> 'administrator' then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_name, ''))) < 2 then
    raise exception 'Company name is required.' using errcode = '22023';
  end if;
  if coalesce(p_slug, '') !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' then
    raise exception 'Company code is invalid.' using errcode = '22023';
  end if;

  insert into public.organisations(name, slug, created_by)
  values (trim(p_name), lower(trim(p_slug)), v_user)
  returning * into v_org;

  insert into public.organisation_memberships(
    organisation_id, user_id, is_active, role, custom_role_id
  ) values (
    v_org.id, v_user, true, 'administrator', null
  );

  update public.profiles
     set active_organisation_id = v_org.id,
         role = 'administrator',
         custom_role_id = null,
         updated_at = now()
   where id = v_user;

  return jsonb_build_object(
    'id', v_org.id,
    'name', v_org.name,
    'slug', v_org.slug,
    'is_active', v_org.is_active,
    'is_current', true
  );
end;
$$;

revoke all on function public.fleet_create_organisation(text, text) from public;
grant execute on function public.fleet_create_organisation(text, text) to authenticated;

create or replace function public.fleet_update_current_organisation(
  p_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user uuid := auth.uid();
  v_org_id uuid;
  v_role text;
  v_org public.organisations%rowtype;
begin
  if v_user is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  v_org_id := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  where m.user_id = v_user and m.organisation_id = v_org_id and m.is_active;
  if v_role <> 'administrator' then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_name, ''))) < 2 then
    raise exception 'Company name is required.' using errcode = '22023';
  end if;

  update public.organisations
     set name = trim(p_name), updated_at = now()
   where id = v_org_id
   returning * into v_org;

  return jsonb_build_object(
    'id', v_org.id,
    'name', v_org.name,
    'slug', v_org.slug,
    'is_active', v_org.is_active,
    'is_current', true
  );
end;
$$;

revoke all on function public.fleet_update_current_organisation(text) from public;
grant execute on function public.fleet_update_current_organisation(text) to authenticated;

create or replace function public.fleet_list_current_organisation_members()
returns table (
  user_id uuid,
  username text,
  email text,
  role text,
  custom_role_name text,
  is_active boolean
)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_org uuid;
  v_role text;
begin
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  where m.user_id = auth.uid() and m.organisation_id = v_org and m.is_active;
  if v_role <> 'administrator' then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;

  return query
  select m.user_id,
         coalesce(p.username, ''),
         coalesce(u.email, ''),
         m.role,
         r.name,
         (m.is_active and p.is_active)
  from public.organisation_memberships m
  join public.profiles p on p.id = m.user_id
  join auth.users u on u.id = m.user_id
  left join public.custom_roles r
    on r.id = m.custom_role_id and r.organisation_id = v_org
  where m.organisation_id = v_org
  order by coalesce(p.username, u.email, '');
end;
$$;

revoke all on function public.fleet_list_current_organisation_members() from public;
grant execute on function public.fleet_list_current_organisation_members() to authenticated;
