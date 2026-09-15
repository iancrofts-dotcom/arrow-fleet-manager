-- FleetIQ Build 17.4.6.18
-- Organisation tenancy + safe central offline replay.
--
-- This migration preserves existing role-specific RLS and adds organisation
-- isolation as RESTRICTIVE policies, so tenant checks are ANDed with existing
-- FleetIQ permission policies rather than replacing them.

create extension if not exists pgcrypto;

create table if not exists public.organisations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) >= 2),
  slug text not null unique check (slug = lower(slug)),
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organisation_memberships (
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (organisation_id, user_id)
);

alter table public.profiles
  add column if not exists active_organisation_id uuid
  references public.organisations(id) on delete set null;

alter table public.organisations enable row level security;
alter table public.organisation_memberships enable row level security;

create or replace function public.fleet_current_organisation_id()
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user uuid := auth.uid();
  v_active uuid;
  v_count integer;
begin
  if v_user is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  select p.active_organisation_id
    into v_active
    from public.profiles p
   where p.id = v_user;

  if v_active is not null and exists (
    select 1
      from public.organisation_memberships m
      join public.organisations o on o.id = m.organisation_id
     where m.user_id = v_user
       and m.organisation_id = v_active
       and m.is_active
       and o.is_active
  ) then
    return v_active;
  end if;

  select count(*)
    into v_count
    from public.organisation_memberships m
    join public.organisations o on o.id = m.organisation_id
   where m.user_id = v_user
     and m.is_active
     and o.is_active;

  if v_count = 1 then
    select m.organisation_id into v_active
      from public.organisation_memberships m
      join public.organisations o on o.id = m.organisation_id
     where m.user_id = v_user
       and m.is_active
       and o.is_active
     limit 1;
    return v_active;
  end if;

  if v_count = 0 then
    raise exception 'No active FleetIQ organisation membership.' using errcode = '42501';
  end if;

  raise exception 'Select an active FleetIQ organisation.' using errcode = '42501';
end;
$$;

revoke all on function public.fleet_current_organisation_id() from public;
grant execute on function public.fleet_current_organisation_id() to authenticated;

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

create or replace function public.fleet_set_active_organisation(
  p_organisation_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  if not exists (
    select 1
      from public.organisation_memberships m
      join public.organisations o on o.id = m.organisation_id
     where m.user_id = auth.uid()
       and m.organisation_id = p_organisation_id
       and m.is_active
       and o.is_active
  ) then
    raise exception 'Organisation membership not available.' using errcode = '42501';
  end if;
  update public.profiles
     set active_organisation_id = p_organisation_id
   where id = auth.uid();
end;
$$;

revoke all on function public.fleet_set_active_organisation(uuid) from public;
grant execute on function public.fleet_set_active_organisation(uuid) to authenticated;

-- Bootstrap the current production deployment into one real organisation.
-- This is a migration bridge for the existing single-company data set, not a
-- permanent "default/global" tenant identifier.
do $$
declare
  v_org uuid;
  v_slug text := 'existing-fleetiq-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
begin
  select id into v_org from public.organisations order by created_at limit 1;
  if v_org is null then
    insert into public.organisations(name, slug, created_by)
    values ('FleetIQ Existing Organisation', v_slug, null)
    returning id into v_org;
  end if;

  insert into public.organisation_memberships(organisation_id, user_id)
  select v_org, p.id
    from public.profiles p
  on conflict (organisation_id, user_id) do nothing;

  update public.profiles p
     set active_organisation_id = v_org
   where p.active_organisation_id is null
     and exists (
       select 1 from public.organisation_memberships m
        where m.user_id = p.id and m.organisation_id = v_org and m.is_active
     );
end;
$$;

-- Membership/organisation read policies. Service-role administrative actions
-- remain available server-side; authenticated users only see their memberships.
drop policy if exists fleet_organisation_member_select on public.organisations;
create policy fleet_organisation_member_select
  on public.organisations
  for select
  to authenticated
  using (
    exists (
      select 1
        from public.organisation_memberships m
       where m.organisation_id = organisations.id
         and m.user_id = auth.uid()
         and m.is_active
    )
  );

drop policy if exists fleet_membership_self_select on public.organisation_memberships;
create policy fleet_membership_self_select
  on public.organisation_memberships
  for select
  to authenticated
  using (user_id = auth.uid());

-- Add organisation identity to all central operational records currently used
-- by FleetIQ. Conditional DDL keeps the migration safe if a future deployment
-- does not contain one of the optional Workshop tables.
do $$
declare
  v_table text;
  v_org uuid;
  v_tables text[] := array[
    'vehicles',
    'drivers',
    'driver_assignments',
    'driver_compliance',
    'fleet_documents',
    'workshop_inspections',
    'workshop_inspection_items',
    'workshop_repair_jobs',
    'workshop_inspection_templates',
    'workshop_inspection_template_items'
  ];
begin
  select id into v_org from public.organisations order by created_at limit 1;
  foreach v_table in array v_tables loop
    if to_regclass('public.' || v_table) is not null then
      execute format(
        'alter table public.%I add column if not exists organisation_id uuid references public.organisations(id) on delete restrict',
        v_table
      );
      execute format(
        'update public.%I set organisation_id = $1 where organisation_id is null',
        v_table
      ) using v_org;
      execute format(
        'alter table public.%I alter column organisation_id set not null',
        v_table
      );
      execute format(
        'create index if not exists %I on public.%I (organisation_id)',
        v_table || '_organisation_id_idx',
        v_table
      );
    end if;
  end loop;
end;
$$;

create or replace function public.fleet_enforce_current_organisation()
returns trigger
language plpgsql
security invoker
set search_path = public, auth
as $$
declare
  v_org uuid;
begin
  -- Service-role/server operations have no auth.uid(). They must provide an
  -- explicit organisation_id and are then checked by their server workflow.
  if auth.uid() is null then
    if new.organisation_id is null then
      raise exception 'Server FleetIQ mutation requires organisation_id.' using errcode = '23502';
    end if;
    return new;
  end if;

  v_org := public.fleet_current_organisation_id();
  if tg_op = 'INSERT' and new.organisation_id is null then
    new.organisation_id := v_org;
  end if;
  if new.organisation_id is distinct from v_org then
    raise exception 'Cross-organisation FleetIQ mutation rejected.' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- Add a restrictive tenant boundary without removing existing role/driver RLS.
do $$
declare
  v_table text;
  v_tables text[] := array[
    'vehicles',
    'drivers',
    'driver_assignments',
    'driver_compliance',
    'fleet_documents',
    'workshop_inspections',
    'workshop_inspection_items',
    'workshop_repair_jobs',
    'workshop_inspection_templates',
    'workshop_inspection_template_items'
  ];
begin
  foreach v_table in array v_tables loop
    if to_regclass('public.' || v_table) is not null then
      execute format('alter table public.%I enable row level security', v_table);
      execute format('drop policy if exists fleet_org_isolation on public.%I', v_table);
      execute format(
        'create policy fleet_org_isolation on public.%I as restrictive for all to authenticated using (organisation_id = public.fleet_current_organisation_id()) with check (organisation_id = public.fleet_current_organisation_id())',
        v_table
      );
      execute format('drop trigger if exists fleet_enforce_org on public.%I', v_table);
      execute format(
        'create trigger fleet_enforce_org before insert or update on public.%I for each row execute function public.fleet_enforce_current_organisation()',
        v_table
      );
    end if;
  end loop;
end;
$$;

-- Idempotency receipts for queued operational writes. Payloads/binaries are not
-- stored here; only the operation result needed to make retries safe.
create table if not exists public.fleet_mutation_receipts (
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  idempotency_key text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  operation text not null,
  result jsonb not null default 'null'::jsonb,
  created_at timestamptz not null default now(),
  primary key (organisation_id, idempotency_key)
);

alter table public.fleet_mutation_receipts enable row level security;
drop policy if exists fleet_mutation_receipt_org_select on public.fleet_mutation_receipts;
create policy fleet_mutation_receipt_org_select
  on public.fleet_mutation_receipts
  for select
  to authenticated
  using (
    organisation_id = public.fleet_current_organisation_id()
    and user_id = auth.uid()
  );

-- One idempotent server endpoint for the operational mutations FleetIQ permits
-- while offline. New record creation, account/invitation management and binary
-- evidence uploads deliberately remain online-only because they require server
-- generated relationships or remote file bytes.
create or replace function public.fleet_apply_resilient_mutation(
  p_operation text,
  p_payload jsonb,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_org uuid;
  v_existing jsonb;
  v_result jsonb := 'null'::jsonb;
  v_text text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  if trim(coalesce(p_idempotency_key, '')) = '' then
    raise exception 'Idempotency key is required.' using errcode = '22023';
  end if;

  v_org := public.fleet_current_organisation_id();

  select r.result into v_existing
    from public.fleet_mutation_receipts r
   where r.organisation_id = v_org
     and r.idempotency_key = p_idempotency_key;
  if found then
    return v_existing;
  end if;

  case p_operation
    when 'workshop.inspection_item.save' then
      select public.workshop_save_inspection_item(
        (p_payload->>'id')::uuid,
        (p_payload->>'inspection_id')::uuid,
        p_payload->>'category',
        p_payload->>'section_title',
        p_payload->>'title',
        p_payload->>'response_type',
        p_payload->>'response_value',
        p_payload->>'status',
        coalesce((p_payload->>'mandatory')::boolean, false),
        coalesce((p_payload->>'repair_required')::boolean, false),
        p_payload->>'notes',
        coalesce((p_payload->>'display_order')::integer, 0)
      )::text into v_text;
      v_result := to_jsonb(v_text);

    when 'workshop.repair_job.update' then
      perform public.workshop_update_repair_job_v2(
        (p_payload->>'id')::uuid,
        p_payload->>'status',
        p_payload->>'parts_required',
        nullif(p_payload->>'actual_hours', '')::numeric,
        nullif(p_payload->>'actual_cost', '')::numeric,
        nullif(p_payload->>'roadworthy', '')::boolean,
        p_payload->>'work_notes',
        p_payload->>'parts_notes',
        nullif(p_payload->>'technician_mileage', '')::integer
      );
      v_result := jsonb_build_object('ok', true);

    when 'workshop.repair_job.sign_off' then
      perform public.workshop_manager_sign_off_repair_job(
        (p_payload->>'id')::uuid,
        nullif(p_payload->>'roadworthy', '')::boolean,
        nullif(p_payload->>'actual_hours', '')::numeric,
        nullif(p_payload->>'actual_cost', '')::numeric,
        p_payload->>'work_notes',
        p_payload->>'parts_notes'
      );
      v_result := jsonb_build_object('ok', true);

    when 'workshop.inspection.assign_technician' then
      perform public.workshop_assign_inspection_technician(
        (p_payload->>'inspection_id')::uuid,
        nullif(p_payload->>'technician_profile_id', '')::uuid
      );
      v_result := jsonb_build_object('ok', true);

    when 'workshop.repair_job.assign_technician' then
      perform public.workshop_assign_repair_technician(
        (p_payload->>'repair_job_id')::uuid,
        nullif(p_payload->>'technician_profile_id', '')::uuid
      );
      v_result := jsonb_build_object('ok', true);

    when 'workshop.inspection.complete' then
      perform public.workshop_complete_inspection(
        (p_payload->>'inspection_id')::uuid
      );
      v_result := jsonb_build_object('ok', true);

    when 'workshop.inspection.sign_off' then
      perform public.workshop_sign_off_inspection(
        (p_payload->>'inspection_id')::uuid
      );
      v_result := jsonb_build_object('ok', true);

    when 'document.archive' then
      perform public.fleet_archive_document(
        (p_payload->>'document_id')::uuid
      );
      v_result := jsonb_build_object('ok', true);

    else
      raise exception 'Operation % is not approved for FleetIQ offline replay.', p_operation
        using errcode = '22023';
  end case;

  insert into public.fleet_mutation_receipts(
    organisation_id,
    idempotency_key,
    user_id,
    operation,
    result
  ) values (
    v_org,
    p_idempotency_key,
    auth.uid(),
    p_operation,
    v_result
  )
  on conflict (organisation_id, idempotency_key) do nothing;

  select r.result into v_existing
    from public.fleet_mutation_receipts r
   where r.organisation_id = v_org
     and r.idempotency_key = p_idempotency_key;
  return coalesce(v_existing, v_result);
end;
$$;

revoke all on function public.fleet_apply_resilient_mutation(text, jsonb, text) from public;
grant execute on function public.fleet_apply_resilient_mutation(text, jsonb, text) to authenticated;

-- Storage tenant boundary. New files use <organisation-uuid>/... paths. Legacy
-- files remain accessible only when a tenant-owned fleet_documents row points at
-- that storage_path. Other buckets are unaffected by this restrictive policy.
do $$
begin
  if to_regclass('storage.objects') is not null then
    execute 'drop policy if exists fleet_documents_org_select on storage.objects';
    execute $policy$
      create policy fleet_documents_org_select
      on storage.objects
      as restrictive
      for select
      to authenticated
      using (
        bucket_id <> 'fleet-documents'
        or split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
        or exists (
          select 1
            from public.fleet_documents d
           where d.storage_path = storage.objects.name
             and d.organisation_id = public.fleet_current_organisation_id()
        )
      )
    $policy$;

    execute 'drop policy if exists fleet_documents_org_insert on storage.objects';
    execute $policy$
      create policy fleet_documents_org_insert
      on storage.objects
      as restrictive
      for insert
      to authenticated
      with check (
        bucket_id <> 'fleet-documents'
        or split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
      )
    $policy$;

    execute 'drop policy if exists fleet_documents_org_update on storage.objects';
    execute $policy$
      create policy fleet_documents_org_update
      on storage.objects
      as restrictive
      for update
      to authenticated
      using (
        bucket_id <> 'fleet-documents'
        or split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
        or exists (
          select 1 from public.fleet_documents d
           where d.storage_path = storage.objects.name
             and d.organisation_id = public.fleet_current_organisation_id()
        )
      )
      with check (
        bucket_id <> 'fleet-documents'
        or split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
      )
    $policy$;

    execute 'drop policy if exists fleet_documents_org_delete on storage.objects';
    execute $policy$
      create policy fleet_documents_org_delete
      on storage.objects
      as restrictive
      for delete
      to authenticated
      using (
        bucket_id <> 'fleet-documents'
        or split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
        or exists (
          select 1 from public.fleet_documents d
           where d.storage_path = storage.objects.name
             and d.organisation_id = public.fleet_current_organisation_id()
        )
      )
    $policy$;
  end if;
end;
$$;


-- Prefix-aware permissive Storage policies for the new tenant-scoped paths.
-- Existing legacy policies remain in place for old object names; the
-- RESTRICTIVE policies above ensure both old and new paths remain tenant-safe.
do $$
begin
  if to_regclass('storage.objects') is not null then
    execute 'drop policy if exists fleet_documents_tenant_read on storage.objects';
    execute $policy$
      create policy fleet_documents_tenant_read
      on storage.objects
      for select
      to authenticated
      using (
        bucket_id = 'fleet-documents'
        and split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
        and (
          public.has_fleetiq_role('administrator')
          or public.has_fleetiq_role('manager')
          or (
            public.has_fleetiq_role('workshop')
            and split_part(name, '/', 2) in ('workshop', 'vehicle', 'general')
          )
          or (
            public.has_fleetiq_role('technician')
            and split_part(name, '/', 2) = 'workshop'
            and exists (
              select 1 from public.workshop_inspections wi
               where wi.id::text = split_part(name, '/', 3)
                 and wi.organisation_id = public.fleet_current_organisation_id()
                 and wi.technician_profile_id = auth.uid()
            )
          )
          or (
            public.has_fleetiq_role('driver')
            and split_part(name, '/', 2) = 'driver'
            and split_part(name, '/', 3) = coalesce((
              select driver_id::text from public.profiles where id = auth.uid()
            ), '')
          )
        )
      )
    $policy$;

    execute 'drop policy if exists fleet_documents_tenant_insert on storage.objects';
    execute $policy$
      create policy fleet_documents_tenant_insert
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'fleet-documents'
        and split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
        and (
          public.has_fleetiq_role('administrator')
          or public.has_fleetiq_role('manager')
          or (
            public.has_fleetiq_role('workshop')
            and split_part(name, '/', 2) in ('workshop', 'vehicle', 'general')
          )
          or (
            public.has_fleetiq_role('technician')
            and split_part(name, '/', 2) = 'workshop'
            and exists (
              select 1 from public.workshop_inspections wi
               where wi.id::text = split_part(name, '/', 3)
                 and wi.organisation_id = public.fleet_current_organisation_id()
                 and wi.technician_profile_id = auth.uid()
            )
          )
        )
      )
    $policy$;

    execute 'drop policy if exists fleet_documents_tenant_delete on storage.objects';
    execute $policy$
      create policy fleet_documents_tenant_delete
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'fleet-documents'
        and split_part(name, '/', 1) = public.fleet_current_organisation_id()::text
        and (
          public.has_fleetiq_role('administrator')
          or public.has_fleetiq_role('manager')
          or public.has_fleetiq_role('workshop')
          or public.has_fleetiq_role('technician')
        )
      )
    $policy$;
  end if;
end;
$$;
