-- FleetIQ Build 15: central Driver compliance and scoped Driver document writes.
-- Assignment mutation remains intentionally locked and is not changed here.

create table if not exists public.driver_compliance (
  driver_id uuid primary key references public.drivers(id) on delete cascade,
  licence_expiry date,
  cpc_expiry date,
  medical_expiry date,
  dbs_expiry date,
  taxi_licence_number text,
  taxi_licence_expiry date,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.driver_compliance(driver_id, licence_expiry)
select id, licence_expiry from public.drivers
on conflict(driver_id) do nothing;

create index if not exists driver_compliance_taxi_expiry_idx
  on public.driver_compliance(taxi_licence_expiry)
  where taxi_licence_expiry is not null;

create index if not exists driver_compliance_licence_expiry_idx
  on public.driver_compliance(licence_expiry)
  where licence_expiry is not null;

alter table public.driver_compliance enable row level security;
revoke all on table public.driver_compliance from anon, authenticated;
grant select on table public.driver_compliance to authenticated;

drop policy if exists "fleet roles read driver compliance" on public.driver_compliance;
create policy "fleet roles read driver compliance" on public.driver_compliance
  for select to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (
      public.has_fleetiq_role('driver')
      and driver_id = (
        select driver_id from public.profiles where id = auth.uid()
      )
    )
  );

create or replace function public.fleet_save_driver_compliance(
  p_driver_id uuid,
  p_licence_expiry date default null,
  p_cpc_expiry date default null,
  p_medical_expiry date default null,
  p_dbs_expiry date default null,
  p_taxi_licence_number text default null,
  p_taxi_licence_expiry date default null
) returns jsonb
language plpgsql security definer set search_path=public
as $$
declare
  v_own_driver_id uuid;
  v_row public.driver_compliance;
begin
  select driver_id into v_own_driver_id
  from public.profiles where id = auth.uid();

  if not (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (
      public.has_fleetiq_role('driver')
      and v_own_driver_id = p_driver_id
    )
  ) then
    raise exception 'Driver compliance access denied';
  end if;

  if not exists(select 1 from public.drivers where id=p_driver_id and is_active) then
    raise exception 'Active Driver not found';
  end if;

  insert into public.driver_compliance(
    driver_id,
    licence_expiry,
    cpc_expiry,
    medical_expiry,
    dbs_expiry,
    taxi_licence_number,
    taxi_licence_expiry,
    updated_by
  ) values (
    p_driver_id,
    p_licence_expiry,
    p_cpc_expiry,
    p_medical_expiry,
    p_dbs_expiry,
    nullif(btrim(coalesce(p_taxi_licence_number,'')),''),
    p_taxi_licence_expiry,
    auth.uid()
  )
  on conflict(driver_id) do update set
    licence_expiry = excluded.licence_expiry,
    cpc_expiry = excluded.cpc_expiry,
    medical_expiry = excluded.medical_expiry,
    dbs_expiry = excluded.dbs_expiry,
    taxi_licence_number = excluded.taxi_licence_number,
    taxi_licence_expiry = excluded.taxi_licence_expiry,
    updated_by = auth.uid(),
    updated_at = now()
  returning * into v_row;

  -- Keep the Driver profile's licence expiry aligned with compliance so the
  -- existing central calendar/reporting summaries continue to see it.
  update public.drivers
  set licence_expiry = p_licence_expiry
  where id = p_driver_id;

  return jsonb_build_object(
    'driver_id', v_row.driver_id,
    'licence_expiry', v_row.licence_expiry,
    'cpc_expiry', v_row.cpc_expiry,
    'medical_expiry', v_row.medical_expiry,
    'dbs_expiry', v_row.dbs_expiry,
    'taxi_licence_number', v_row.taxi_licence_number,
    'taxi_licence_expiry', v_row.taxi_licence_expiry,
    'updated_at', v_row.updated_at
  );
end; $$;

revoke all on function public.fleet_save_driver_compliance(uuid,date,date,date,date,text,date)
  from public, anon;
grant execute on function public.fleet_save_driver_compliance(uuid,date,date,date,date,text,date)
  to authenticated;

-- Ensure central document metadata parity is present even if Build 13's
-- document-management migration has not yet been applied to the live project.
alter table public.fleet_documents
  add column if not exists title text not null default '';
alter table public.fleet_documents
  add column if not exists archived_at timestamptz;

create index if not exists fleet_documents_active_entity_idx
  on public.fleet_documents(entity_type, entity_id, created_at desc)
  where archived_at is null;

drop policy if exists "central roles read documents" on public.fleet_documents;
create policy "central roles read documents" on public.fleet_documents
  for select to authenticated using (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (
      public.has_fleetiq_role('workshop')
      and driver_id is null
    )
    or (
      public.has_fleetiq_role('technician')
      and inspection_id in (
        select id from public.workshop_inspections
        where technician_profile_id = auth.uid()
      )
    )
    or (
      public.has_fleetiq_role('driver')
      and driver_id = (
        select driver_id from public.profiles where id = auth.uid()
      )
    )
  );

drop policy if exists "fleet documents management read" on storage.objects;
drop policy if exists "fleet documents scoped read" on storage.objects;
create policy "fleet documents scoped read" on storage.objects
for select to authenticated using (
  bucket_id = 'fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (
      public.has_fleetiq_role('workshop')
      and split_part(name,'/',1) in ('workshop','vehicle','general')
    )
    or (
      public.has_fleetiq_role('technician')
      and split_part(name,'/',1)='workshop'
      and exists(
        select 1 from public.workshop_inspections wi
        where wi.id::text = split_part(name,'/',2)
          and wi.technician_profile_id = auth.uid()
      )
    )
    or (
      public.has_fleetiq_role('driver')
      and split_part(name,'/',1)='driver'
      and split_part(name,'/',2)=coalesce((
        select driver_id::text from public.profiles where id=auth.uid()
      ),'')
    )
  )
);

-- Permit a Driver to upload only into their own Driver document namespace.
drop policy if exists "fleet documents management insert" on storage.objects;
drop policy if exists "fleet documents scoped insert" on storage.objects;
create policy "fleet documents scoped insert" on storage.objects
for insert to authenticated with check (
  bucket_id = 'fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (
      public.has_fleetiq_role('workshop')
      and split_part(name,'/',1) in ('workshop','vehicle','general')
    )
    or (
      public.has_fleetiq_role('technician')
      and split_part(name,'/',1)='workshop'
      and exists(
        select 1 from public.workshop_inspections wi
        where wi.id::text = split_part(name,'/',2)
          and wi.technician_profile_id = auth.uid()
      )
    )
    or (
      public.has_fleetiq_role('driver')
      and split_part(name,'/',1)='driver'
      and split_part(name,'/',2)=coalesce((
        select driver_id::text from public.profiles where id=auth.uid()
      ),'')
    )
  )
);

drop policy if exists "fleet documents management delete" on storage.objects;
drop policy if exists "fleet documents scoped delete" on storage.objects;
create policy "fleet documents scoped delete" on storage.objects
for delete to authenticated using (
  bucket_id = 'fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (
      public.has_fleetiq_role('workshop')
      and split_part(name,'/',1) in ('workshop','vehicle','general')
    )
    or (
      public.has_fleetiq_role('driver')
      and split_part(name,'/',1)='driver'
      and split_part(name,'/',2)=coalesce((
        select driver_id::text from public.profiles where id=auth.uid()
      ),'')
    )
  )
);

create or replace function public.fleet_register_document(
  p_entity_type text,
  p_entity_id uuid,
  p_category text,
  p_title text,
  p_file_name text,
  p_storage_path text,
  p_content_type text,
  p_size_bytes bigint,
  p_expires_on date default null,
  p_caption text default ''
) returns uuid
language plpgsql security definer set search_path=public,storage
as $$
declare
  v_id uuid;
  v_username text;
  v_vehicle_id uuid;
  v_driver_id uuid;
  v_own_driver_id uuid;
begin
  if p_entity_type not in ('vehicle','driver','general') then
    raise exception 'Unsupported document subject';
  end if;
  select driver_id into v_own_driver_id from public.profiles where id=auth.uid();

  if p_entity_type='driver' then
    if not (
      public.has_fleetiq_role('administrator')
      or public.has_fleetiq_role('manager')
      or (public.has_fleetiq_role('driver') and v_own_driver_id=p_entity_id)
    ) then
      raise exception 'Driver document access denied';
    end if;
    if not exists(select 1 from public.drivers where id=p_entity_id) then
      raise exception 'Driver not found';
    end if;
    v_driver_id := p_entity_id;
  elsif p_entity_type='vehicle' then
    if not (
      public.has_fleetiq_role('administrator')
      or public.has_fleetiq_role('manager')
      or public.has_fleetiq_role('workshop')
    ) then
      raise exception 'Vehicle document access denied';
    end if;
    if not exists(select 1 from public.vehicles where id=p_entity_id) then
      raise exception 'Vehicle not found';
    end if;
    v_vehicle_id := p_entity_id;
  else
    if not (
      public.has_fleetiq_role('administrator')
      or public.has_fleetiq_role('manager')
      or public.has_fleetiq_role('workshop')
    ) then
      raise exception 'General document access denied';
    end if;
  end if;

  if btrim(coalesce(p_category,''))='' or btrim(coalesce(p_title,''))='' or btrim(coalesce(p_file_name,''))='' then
    raise exception 'Document title, category and file name are required';
  end if;
  if p_size_bytes <= 0 or p_size_bytes > 10485760 then
    raise exception 'Document file size is invalid';
  end if;
  if p_content_type not in ('image/jpeg','image/png','image/webp','application/pdf') then
    raise exception 'Unsupported document file type';
  end if;
  if p_storage_path not like (p_entity_type || '/' || p_entity_id::text || '/%') then
    raise exception 'Invalid document storage path';
  end if;
  if not exists(
    select 1 from storage.objects
    where bucket_id='fleet-documents' and name=p_storage_path
  ) then
    raise exception 'Document object was not uploaded';
  end if;

  select username into v_username from public.profiles where id=auth.uid();
  insert into public.fleet_documents(
    entity_type, entity_id, category, title, vehicle_id, driver_id,
    file_name, storage_path, content_type, size_bytes, caption, expires_on,
    uploaded_by, uploader_name
  ) values (
    p_entity_type, p_entity_id, btrim(p_category), btrim(p_title),
    v_vehicle_id, v_driver_id, btrim(p_file_name), p_storage_path,
    p_content_type, p_size_bytes, coalesce(p_caption,''), p_expires_on,
    auth.uid(), coalesce(v_username,'')
  ) returning id into v_id;
  return v_id;
end; $$;

create or replace function public.fleet_archive_document(p_document_id uuid)
returns void
language plpgsql security definer set search_path=public
as $$
declare
  v_driver_id uuid;
  v_own_driver_id uuid;
begin
  select driver_id into v_driver_id
  from public.fleet_documents where id=p_document_id and archived_at is null;
  if not found then raise exception 'Document not found'; end if;
  select driver_id into v_own_driver_id from public.profiles where id=auth.uid();

  if v_driver_id is not null then
    if not (
      public.has_fleetiq_role('administrator')
      or public.has_fleetiq_role('manager')
      or (public.has_fleetiq_role('driver') and v_driver_id=v_own_driver_id)
    ) then
      raise exception 'Driver document access denied';
    end if;
  elsif not (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
  ) then
    raise exception 'Document archive access denied';
  end if;
  update public.fleet_documents set archived_at=now() where id=p_document_id;
end; $$;

revoke all on function public.fleet_register_document(text,uuid,text,text,text,text,text,bigint,date,text)
  from public,anon;
revoke all on function public.fleet_archive_document(uuid) from public,anon;
grant execute on function public.fleet_register_document(text,uuid,text,text,text,text,text,bigint,date,text)
  to authenticated;
grant execute on function public.fleet_archive_document(uuid) to authenticated;

revoke insert,update,delete on public.fleet_documents from anon,authenticated;
