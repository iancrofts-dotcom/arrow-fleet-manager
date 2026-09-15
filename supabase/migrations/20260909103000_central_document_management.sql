-- FleetIQ central application parity: operational Fleet/Driver document management.
-- Direct table writes remain revoked; metadata writes are performed through
-- security-definer RPCs and Storage remains private.

alter table public.fleet_documents
  add column if not exists title text not null default '';
alter table public.fleet_documents
  add column if not exists archived_at timestamptz;

create index if not exists fleet_documents_active_entity_idx
  on public.fleet_documents(entity_type, entity_id, created_at desc)
  where archived_at is null;

-- Tighten document metadata reads before enabling Driver documents.
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

-- Replace broad Storage policies with entity-aware rules.
drop policy if exists "fleet documents management read" on storage.objects;
drop policy if exists "fleet documents management insert" on storage.objects;
drop policy if exists "fleet documents management delete" on storage.objects;

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
      and split_part(name,'/',2) = coalesce((
        select driver_id::text from public.profiles where id=auth.uid()
      ), '')
    )
  )
);

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
  )
);

create policy "fleet documents scoped delete" on storage.objects
for delete to authenticated using (
  bucket_id = 'fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (
      public.has_fleetiq_role('workshop')
      and split_part(name,'/',1) in ('workshop','vehicle','general')
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
begin
  if p_entity_type not in ('vehicle','driver','general') then
    raise exception 'Unsupported document subject';
  end if;
  if p_entity_type='driver' then
    if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')) then
      raise exception 'Driver document access denied';
    end if;
    if not exists(select 1 from public.drivers where id=p_entity_id) then
      raise exception 'Driver not found';
    end if;
    v_driver_id := p_entity_id;
  elsif p_entity_type='vehicle' then
    if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')) then
      raise exception 'Vehicle document access denied';
    end if;
    if not exists(select 1 from public.vehicles where id=p_entity_id) then
      raise exception 'Vehicle not found';
    end if;
    v_vehicle_id := p_entity_id;
  else
    if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')) then
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
declare v_driver_id uuid;
begin
  select driver_id into v_driver_id
  from public.fleet_documents where id=p_document_id and archived_at is null;
  if not found then raise exception 'Document not found'; end if;
  if v_driver_id is not null then
    if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager')) then
      raise exception 'Driver document access denied';
    end if;
  elsif not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')) then
    raise exception 'Document archive access denied';
  end if;
  update public.fleet_documents set archived_at=now() where id=p_document_id;
end; $$;

revoke all on function public.fleet_register_document(text,uuid,text,text,text,text,text,bigint,date,text) from public,anon;
revoke all on function public.fleet_archive_document(uuid) from public,anon;
grant execute on function public.fleet_register_document(text,uuid,text,text,text,text,text,bigint,date,text) to authenticated;
grant execute on function public.fleet_archive_document(uuid) to authenticated;

-- Keep metadata immutable to ordinary clients; RPCs above own the write path.
revoke insert,update,delete on public.fleet_documents from anon,authenticated;
