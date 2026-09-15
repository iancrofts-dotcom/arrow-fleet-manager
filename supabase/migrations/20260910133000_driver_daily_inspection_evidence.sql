-- FleetIQ Build 17.3.1: allow a Driver to attach evidence only to their own
-- authenticated daily inspection items. Existing management/technician access
-- is preserved. Direct Workshop table writes remain locked.

create or replace function public.workshop_register_evidence(
  p_inspection_id uuid,
  p_inspection_item_id uuid,
  p_file_name text,
  p_storage_path text,
  p_content_type text,
  p_size_bytes bigint,
  p_caption text default ''
) returns uuid
language plpgsql security definer set search_path=public,storage
as $$
declare
  v_id uuid;
  v_assigned uuid;
  v_driver_id uuid;
  v_user text;
begin
  select wi.technician_profile_id, wi.driver_id
    into v_assigned, v_driver_id
  from public.workshop_inspections wi
  join public.workshop_inspection_items ii on ii.inspection_id=wi.id
  where wi.id=p_inspection_id and ii.id=p_inspection_item_id;
  if not found then raise exception 'Inspection item not found'; end if;

  if not (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or public.has_fleetiq_role('workshop')
    or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())
    or (
      public.has_fleetiq_role('driver')
      and v_driver_id=(select driver_id from public.profiles where id=auth.uid())
    )
  ) then
    raise exception 'Evidence upload access denied';
  end if;

  if p_size_bytes <= 0 or p_size_bytes > 10485760 then raise exception 'Evidence file size is invalid'; end if;
  if p_content_type not in ('image/jpeg','image/png','image/webp','application/pdf') then raise exception 'Unsupported evidence file type'; end if;
  if p_storage_path not like ('workshop/' || p_inspection_id::text || '/' || p_inspection_item_id::text || '/%') then raise exception 'Invalid evidence storage path'; end if;
  if not exists(select 1 from storage.objects where bucket_id='fleet-documents' and name=p_storage_path) then raise exception 'Evidence object was not uploaded'; end if;

  select username into v_user from public.profiles where id=auth.uid();
  insert into public.fleet_documents(
    entity_type,entity_id,category,inspection_id,inspection_item_id,file_name,
    storage_path,content_type,size_bytes,caption,uploaded_by,uploader_name
  ) values(
    'workshopInspectionItem',p_inspection_item_id,'inspectionEvidence',
    p_inspection_id,p_inspection_item_id,btrim(p_file_name),p_storage_path,
    p_content_type,p_size_bytes,coalesce(p_caption,''),auth.uid(),coalesce(v_user,'')
  ) returning id into v_id;

  update public.workshop_inspection_items
  set photo_count=photo_count+1
  where id=p_inspection_item_id;
  return v_id;
end; $$;

revoke all on function public.workshop_register_evidence(uuid,uuid,text,text,text,bigint,text) from public,anon;
grant execute on function public.workshop_register_evidence(uuid,uuid,text,text,text,bigint,text) to authenticated;

-- Extend the existing private bucket policies with a narrowly scoped Driver
-- Workshop namespace for inspections belonging to that Driver.
drop policy if exists "fleet documents scoped read" on storage.objects;
create policy "fleet documents scoped read" on storage.objects
for select to authenticated using (
  bucket_id='fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (public.has_fleetiq_role('workshop') and split_part(name,'/',1) in ('workshop','vehicle','general'))
    or (public.has_fleetiq_role('technician') and split_part(name,'/',1)='workshop' and exists(
      select 1 from public.workshop_inspections wi
      where wi.id::text=split_part(name,'/',2) and wi.technician_profile_id=auth.uid()
    ))
    or (public.has_fleetiq_role('driver') and (
      (split_part(name,'/',1)='driver' and split_part(name,'/',2)=coalesce((select driver_id::text from public.profiles where id=auth.uid()),''))
      or (split_part(name,'/',1)='workshop' and exists(
        select 1 from public.workshop_inspections wi
        where wi.id::text=split_part(name,'/',2)
          and wi.driver_id=(select driver_id from public.profiles where id=auth.uid())
      ))
    ))
  )
);

drop policy if exists "fleet documents scoped insert" on storage.objects;
create policy "fleet documents scoped insert" on storage.objects
for insert to authenticated with check (
  bucket_id='fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (public.has_fleetiq_role('workshop') and split_part(name,'/',1) in ('workshop','vehicle','general'))
    or (public.has_fleetiq_role('technician') and split_part(name,'/',1)='workshop' and exists(
      select 1 from public.workshop_inspections wi
      where wi.id::text=split_part(name,'/',2) and wi.technician_profile_id=auth.uid()
    ))
    or (public.has_fleetiq_role('driver') and (
      (split_part(name,'/',1)='driver' and split_part(name,'/',2)=coalesce((select driver_id::text from public.profiles where id=auth.uid()),''))
      or (split_part(name,'/',1)='workshop' and exists(
        select 1 from public.workshop_inspections wi
        where wi.id::text=split_part(name,'/',2)
          and wi.driver_id=(select driver_id from public.profiles where id=auth.uid())
      ))
    ))
  )
);

drop policy if exists "fleet documents scoped delete" on storage.objects;
create policy "fleet documents scoped delete" on storage.objects
for delete to authenticated using (
  bucket_id='fleet-documents' and (
    public.has_fleetiq_role('administrator')
    or public.has_fleetiq_role('manager')
    or (public.has_fleetiq_role('workshop') and split_part(name,'/',1) in ('workshop','vehicle','general'))
    or (public.has_fleetiq_role('driver') and (
      (split_part(name,'/',1)='driver' and split_part(name,'/',2)=coalesce((select driver_id::text from public.profiles where id=auth.uid()),''))
      or (split_part(name,'/',1)='workshop' and exists(
        select 1 from public.workshop_inspections wi
        where wi.id::text=split_part(name,'/',2)
          and wi.driver_id=(select driver_id from public.profiles where id=auth.uid())
      ))
    ))
  )
);
