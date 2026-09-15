-- FleetIQ Build 17.4.6.18.1
-- Organisation custom roles + controlled Administrator Driver deletion.

create table if not exists public.custom_roles (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null,
  description text not null default '',
  permissions jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organisation_id, name),
  check (jsonb_typeof(permissions) = 'array')
);

alter table public.profiles
  add column if not exists custom_role_id uuid
  references public.custom_roles(id) on delete set null;

alter table public.drivers
  add column if not exists deleted_at timestamptz,
  add column if not exists deleted_by uuid references auth.users(id) on delete set null;

create index if not exists custom_roles_organisation_id_idx
  on public.custom_roles (organisation_id);
create index if not exists profiles_custom_role_id_idx
  on public.profiles (custom_role_id);
create index if not exists drivers_deleted_at_idx
  on public.drivers (deleted_at);

alter table public.custom_roles enable row level security;

drop policy if exists fleet_custom_roles_admin_select on public.custom_roles;
create policy fleet_custom_roles_admin_select
  on public.custom_roles for select to authenticated
  using (
    organisation_id = public.fleet_current_organisation_id()
    and (
      exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.is_active and p.role = 'administrator'
      )
      or exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.is_active and p.custom_role_id = custom_roles.id
      )
    )
  );

create or replace function public.fleet_has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select case
    when p.role = 'administrator' then true
    when p.custom_role_id is null then true
    else exists (
      select 1
      from public.custom_roles r
      where r.id = p.custom_role_id
        and r.organisation_id = public.fleet_current_organisation_id()
        and r.is_active
        and r.permissions ? p_permission
    )
  end
  from public.profiles p
  where p.id = auth.uid() and p.is_active;
$$;

revoke all on function public.fleet_has_permission(text) from public;
grant execute on function public.fleet_has_permission(text) to authenticated;

-- Restrict custom-role accounts at the database boundary. Existing built-in
-- roles continue to use their established role RLS because fleet_has_permission
-- returns true for profiles without a custom role.
do $$
declare
  rec record;
begin
  for rec in
    select * from (values
      ('vehicles', 'view_vehicles', 'manage_vehicles'),
      ('drivers', 'view_drivers', 'manage_drivers'),
      ('driver_assignments', 'view_drivers', 'manage_drivers'),
      ('driver_compliance', 'view_compliance', 'manage_compliance'),
      ('fleet_documents', 'view_documents', 'manage_documents'),
      ('workshop_inspections', 'access_workshop', 'operate_workshop'),
      ('workshop_inspection_items', 'access_workshop', 'operate_workshop'),
      ('workshop_repair_jobs', 'access_workshop', 'operate_workshop'),
      ('workshop_inspection_templates', 'access_workshop', 'manage_inspection_templates'),
      ('workshop_inspection_template_items', 'access_workshop', 'manage_inspection_templates')
    ) as t(table_name, read_permission, write_permission)
  loop
    if to_regclass('public.' || rec.table_name) is not null then
      execute format('drop policy if exists fleet_custom_role_read on public.%I', rec.table_name);
      execute format(
        'create policy fleet_custom_role_read on public.%I as restrictive for select to authenticated using (public.fleet_has_permission(%L))',
        rec.table_name, rec.read_permission
      );
      execute format('drop policy if exists fleet_custom_role_insert on public.%I', rec.table_name);
      execute format(
        'create policy fleet_custom_role_insert on public.%I as restrictive for insert to authenticated with check (public.fleet_has_permission(%L))',
        rec.table_name, rec.write_permission
      );
      execute format('drop policy if exists fleet_custom_role_update on public.%I', rec.table_name);
      execute format(
        'create policy fleet_custom_role_update on public.%I as restrictive for update to authenticated using (public.fleet_has_permission(%L)) with check (public.fleet_has_permission(%L))',
        rec.table_name, rec.write_permission, rec.write_permission
      );
      execute format('drop policy if exists fleet_custom_role_delete on public.%I', rec.table_name);
      execute format(
        'create policy fleet_custom_role_delete on public.%I as restrictive for delete to authenticated using (public.fleet_has_permission(%L))',
        rec.table_name, rec.write_permission
      );
    end if;
  end loop;
end;
$$;
