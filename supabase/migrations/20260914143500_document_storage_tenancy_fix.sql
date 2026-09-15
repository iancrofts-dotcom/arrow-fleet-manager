-- FleetIQ Build 17.4.6.18.4
-- Align central document registration with organisation-prefixed Storage paths.
-- New canonical path:
--   <organisation-uuid>/<entity-type>/<entity-id>/<unique-file-name>
--
-- The Build 15 registration RPC still validated the pre-tenancy path
-- (<entity-type>/<entity-id>/...), which caused a P0001 "Invalid document
-- storage path" after Build 17.4.6.18 correctly began prefixing object names
-- with the authenticated organisation id.

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
language plpgsql
security definer
set search_path = public, storage, auth
as $$
declare
  v_id uuid;
  v_username text;
  v_vehicle_id uuid;
  v_driver_id uuid;
  v_own_driver_id uuid;
  v_org uuid;
  v_expected_prefix text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  v_org := public.fleet_current_organisation_id();
  if v_org is null then
    raise exception 'FleetIQ organisation could not be resolved' using errcode = '42501';
  end if;

  if p_entity_type not in ('vehicle', 'driver', 'general') then
    raise exception 'Unsupported document subject';
  end if;

  select driver_id
    into v_own_driver_id
    from public.profiles
   where id = auth.uid()
     and is_active;

  if p_entity_type = 'driver' then
    if not (
      public.has_fleetiq_role('administrator')
      or public.has_fleetiq_role('manager')
      or (public.has_fleetiq_role('driver') and v_own_driver_id = p_entity_id)
    ) then
      raise exception 'Driver document access denied' using errcode = '42501';
    end if;

    if not exists (
      select 1
        from public.drivers d
       where d.id = p_entity_id
         and d.organisation_id = v_org
         and d.deleted_at is null
    ) then
      raise exception 'Driver not found';
    end if;
    v_driver_id := p_entity_id;

  elsif p_entity_type = 'vehicle' then
    if not (
      public.has_fleetiq_role('administrator')
      or public.has_fleetiq_role('manager')
      or public.has_fleetiq_role('workshop')
    ) then
      raise exception 'Vehicle document access denied' using errcode = '42501';
    end if;

    if not exists (
      select 1
        from public.vehicles v
       where v.id = p_entity_id
         and v.organisation_id = v_org
    ) then
      raise exception 'Vehicle not found';
    end if;
    v_vehicle_id := p_entity_id;

  else
    if not (
      public.has_fleetiq_role('administrator')
      or public.has_fleetiq_role('manager')
      or public.has_fleetiq_role('workshop')
    ) then
      raise exception 'General document access denied' using errcode = '42501';
    end if;
  end if;

  -- Custom-role accounts use the legacy Manager compatibility role at the
  -- role boundary, so preserve the Build 17.4.6.18.1 permission restriction
  -- explicitly inside this SECURITY DEFINER RPC as well.
  if not public.fleet_has_permission('manage_documents') then
    raise exception 'Document management permission required' using errcode = '42501';
  end if;

  if btrim(coalesce(p_category, '')) = ''
     or btrim(coalesce(p_title, '')) = ''
     or btrim(coalesce(p_file_name, '')) = '' then
    raise exception 'Document title, category and file name are required';
  end if;

  if p_size_bytes <= 0 or p_size_bytes > 10485760 then
    raise exception 'Document file size is invalid';
  end if;

  if p_content_type not in (
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf'
  ) then
    raise exception 'Unsupported document file type';
  end if;

  v_expected_prefix :=
    v_org::text || '/' || p_entity_type || '/' || p_entity_id::text || '/';

  if p_storage_path is null
     or left(p_storage_path, length(v_expected_prefix)) <> v_expected_prefix then
    raise exception 'Invalid document storage path';
  end if;

  if not exists (
    select 1
      from storage.objects o
     where o.bucket_id = 'fleet-documents'
       and o.name = p_storage_path
  ) then
    raise exception 'Document object was not uploaded';
  end if;

  select username
    into v_username
    from public.profiles
   where id = auth.uid();

  insert into public.fleet_documents(
    organisation_id,
    entity_type,
    entity_id,
    category,
    title,
    vehicle_id,
    driver_id,
    file_name,
    storage_path,
    content_type,
    size_bytes,
    caption,
    expires_on,
    uploaded_by,
    uploader_name
  ) values (
    v_org,
    p_entity_type,
    p_entity_id,
    btrim(p_category),
    btrim(p_title),
    v_vehicle_id,
    v_driver_id,
    btrim(p_file_name),
    p_storage_path,
    p_content_type,
    p_size_bytes,
    coalesce(p_caption, ''),
    p_expires_on,
    auth.uid(),
    coalesce(v_username, '')
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.fleet_register_document(
  text, uuid, text, text, text, text, text, bigint, date, text
) from public, anon;

grant execute on function public.fleet_register_document(
  text, uuid, text, text, text, text, text, bigint, date, text
) to authenticated;
