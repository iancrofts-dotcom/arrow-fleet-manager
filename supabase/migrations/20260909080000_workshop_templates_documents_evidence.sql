-- FleetIQ Build 10: central Workshop templates, pre-populated inspections,
-- photo evidence and central document metadata/storage foundation.

create table if not exists public.workshop_inspection_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null check (btrim(name) <> ''),
  description text not null default '',
  inspection_type text check (inspection_type is null or inspection_type in (
    'scheduledService','defectInspection','annualInspection','motPreparation',
    'repairInspection','returnToService','driverDailyInspection'
  )),
  template_version integer not null default 1 check (template_version > 0),
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists workshop_template_name_version_uq
  on public.workshop_inspection_templates (lower(name), template_version);

create table if not exists public.workshop_inspection_template_items (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.workshop_inspection_templates(id) on delete cascade,
  section_title text,
  category text not null check (btrim(category) <> ''),
  title text not null check (btrim(title) <> ''),
  description text not null default '',
  response_type text not null default 'passFailNotApplicable',
  mandatory boolean not null default true,
  critical_safety_item boolean not null default false,
  auto_create_repair boolean not null default true,
  repair_priority text not null default 'medium' check (repair_priority in ('low','medium','high','critical')),
  roadworthy_impact text not null default 'none' check (roadworthy_impact in ('none','advisory','notRoadworthy')),
  photo_required_on_fail boolean not null default false,
  allow_notes boolean not null default true,
  default_status text not null default 'notApplicable' check (default_status in ('notApplicable','pass','fail','advisory')),
  display_order integer not null check (display_order >= 0)
);

create index if not exists workshop_template_items_order_idx
  on public.workshop_inspection_template_items(template_id, display_order);

alter table public.workshop_inspections
  add column if not exists template_id uuid references public.workshop_inspection_templates(id) on delete set null;
alter table public.workshop_inspection_items
  add column if not exists template_item_id uuid references public.workshop_inspection_template_items(id) on delete set null;
alter table public.workshop_inspection_items
  add column if not exists critical_safety_item boolean not null default false;
alter table public.workshop_inspection_items
  add column if not exists auto_create_repair boolean not null default false;
alter table public.workshop_inspection_items
  add column if not exists repair_priority text not null default 'medium';
alter table public.workshop_inspection_items
  add column if not exists roadworthy_impact text not null default 'none';
alter table public.workshop_inspection_items
  add column if not exists photo_required_on_fail boolean not null default false;
alter table public.workshop_inspection_items
  add column if not exists allow_notes boolean not null default true;

create table if not exists public.fleet_documents (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('workshopInspectionItem','workshopInspection','vehicle','driver','general')),
  entity_id uuid not null,
  category text not null default 'evidence',
  inspection_id uuid references public.workshop_inspections(id) on delete cascade,
  inspection_item_id uuid references public.workshop_inspection_items(id) on delete cascade,
  vehicle_id uuid references public.vehicles(id) on delete cascade,
  driver_id uuid references public.drivers(id) on delete cascade,
  file_name text not null check (btrim(file_name) <> ''),
  storage_path text not null unique check (btrim(storage_path) <> ''),
  content_type text not null default 'application/octet-stream',
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  caption text not null default '',
  expires_on date,
  uploaded_by uuid references public.profiles(id) on delete set null,
  uploader_name text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists fleet_documents_entity_idx on public.fleet_documents(entity_type, entity_id, created_at desc);
create index if not exists fleet_documents_inspection_item_idx on public.fleet_documents(inspection_item_id, created_at desc);
create index if not exists fleet_documents_vehicle_idx on public.fleet_documents(vehicle_id, created_at desc);
create index if not exists fleet_documents_driver_idx on public.fleet_documents(driver_id, created_at desc);

alter table public.workshop_inspection_templates enable row level security;
alter table public.workshop_inspection_template_items enable row level security;
alter table public.fleet_documents enable row level security;

revoke all on table public.workshop_inspection_templates from anon, authenticated;
revoke all on table public.workshop_inspection_template_items from anon, authenticated;
revoke all on table public.fleet_documents from anon, authenticated;
grant select on table public.workshop_inspection_templates to authenticated;
grant select on table public.workshop_inspection_template_items to authenticated;
grant select on table public.fleet_documents to authenticated;

create policy "workshop roles read templates" on public.workshop_inspection_templates
  for select to authenticated using (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop') or public.has_fleetiq_role('technician')
  );
create policy "workshop roles read template items" on public.workshop_inspection_template_items
  for select to authenticated using (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop') or public.has_fleetiq_role('technician')
  );
create policy "central roles read documents" on public.fleet_documents
  for select to authenticated using (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or
    public.has_fleetiq_role('workshop') or
    (public.has_fleetiq_role('technician') and inspection_id in (
      select id from public.workshop_inspections where technician_profile_id = auth.uid()
    ))
  );

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('fleet-documents', 'fleet-documents', false, 10485760,
  array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "fleet documents management read" on storage.objects
for select to authenticated using (
  bucket_id = 'fleet-documents' and (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop') or
    (public.has_fleetiq_role('technician') and split_part(name,'/',1)='workshop' and exists(
      select 1 from public.workshop_inspections wi
      where wi.id::text = split_part(name,'/',2) and wi.technician_profile_id = auth.uid()
    ))
  )
);
create policy "fleet documents management insert" on storage.objects
for insert to authenticated with check (
  bucket_id = 'fleet-documents' and (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop') or
    (public.has_fleetiq_role('technician') and split_part(name,'/',1)='workshop' and exists(
      select 1 from public.workshop_inspections wi
      where wi.id::text = split_part(name,'/',2) and wi.technician_profile_id = auth.uid()
    ))
  )
);
create policy "fleet documents management delete" on storage.objects
for delete to authenticated using (
  bucket_id = 'fleet-documents' and (
    public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop')
  )
);

-- Seed a central PMI/safety template modelled on the existing FleetIQ Workshop flow.
with inserted as (
  insert into public.workshop_inspection_templates(id, name, description, inspection_type, template_version, is_default, is_active)
  values ('10000000-0000-4000-8000-000000000010', 'FleetIQ Workshop Safety Inspection', 'Pre-populated workshop safety and PMI checklist.', null, 1, true, true)
  on conflict (id) do update set is_active=true, is_default=true, name=excluded.name, description=excluded.description
  returning id
)
insert into public.workshop_inspection_template_items(
  template_id, section_title, category, title, description, mandatory,
  critical_safety_item, auto_create_repair, repair_priority, roadworthy_impact,
  photo_required_on_fail, allow_notes, default_status, display_order
)
select inserted.id, v.section_title, v.category, v.title, '', true,
       v.critical, true, v.priority, v.impact, v.photo_required, true, 'notApplicable', v.display_order
from inserted
cross join (values
 ('Vehicle information','vehicleInformation','Registration / fleet identity confirmed',false,'medium','none',false,0),
 ('Vehicle information','vehicleInformation','Mileage recorded and verified',false,'medium','none',false,1),
 ('Exterior & body','exterior','Mirrors, glazing and wipers',false,'medium','advisory',true,2),
 ('Exterior & body','bodywork','Body panels, doors and security',false,'medium','advisory',true,3),
 ('Wheels & tyres','wheelsTyres','Front tyre condition and tread',true,'critical','notRoadworthy',true,4),
 ('Wheels & tyres','wheelsTyres','Rear tyre condition and tread',true,'critical','notRoadworthy',true,5),
 ('Wheels & tyres','wheelsTyres','Wheel nuts, rims and visible damage',true,'critical','notRoadworthy',true,6),
 ('Brakes','brakes','Brake pads / linings condition',true,'critical','notRoadworthy',true,7),
 ('Brakes','brakes','Brake discs / drums condition',true,'critical','notRoadworthy',true,8),
 ('Brakes','brakes','Brake fluid, hoses and leaks',true,'critical','notRoadworthy',true,9),
 ('Steering & suspension','steering','Steering operation and free play',true,'critical','notRoadworthy',true,10),
 ('Steering & suspension','suspension','Suspension components and security',true,'high','notRoadworthy',true,11),
 ('Engine & transmission','engine','Engine oil and fluid leaks',false,'high','advisory',true,12),
 ('Engine & transmission','engine','Coolant level / cooling system',false,'high','advisory',true,13),
 ('Engine & transmission','transmission','Transmission / driveline condition',false,'high','advisory',true,14),
 ('Electrical & lighting','electrical','Headlights, indicators and brake lights',true,'high','notRoadworthy',true,15),
 ('Electrical & lighting','electrical','Warning lamps and dashboard indications',false,'high','advisory',true,16),
 ('Interior & safety','interior','Seat belts and passenger restraints',true,'critical','notRoadworthy',true,17),
 ('Interior & safety','interior','Emergency exits and safety equipment',true,'critical','notRoadworthy',true,18),
 ('Interior & safety','interior','Fire extinguisher / first aid equipment',false,'medium','advisory',true,19),
 ('Underbody','underbody','Chassis, underbody and visible corrosion',true,'high','notRoadworthy',true,20),
 ('Underbody','underbody','Exhaust system security and leaks',false,'medium','advisory',true,21),
 ('Road test','roadTest','Braking performance',true,'critical','notRoadworthy',true,22),
 ('Road test','roadTest','Steering and handling',true,'critical','notRoadworthy',true,23),
 ('Road test','roadTest','Noise, vibration and drivability',false,'medium','advisory',true,24),
 ('Sign off','signOff','Final defect and repair review completed',true,'high','none',false,25)
) as v(section_title,category,title,critical,priority,impact,photo_required,display_order)
on conflict do nothing;

create or replace function public.workshop_create_inspection_from_template(
  p_vehicle_id uuid,
  p_template_id uuid,
  p_inspection_type text,
  p_mileage integer,
  p_notes text default '',
  p_technician_profile_id uuid default null
) returns uuid
language plpgsql security definer set search_path=public
as $$
declare v_id uuid; v_template_name text; v_template_type text;
begin
  select name, inspection_type into v_template_name, v_template_type
  from public.workshop_inspection_templates where id=p_template_id and is_active=true;
  if not found then raise exception 'Active inspection template not found'; end if;
  if v_template_type is not null and v_template_type <> p_inspection_type then raise exception 'Template does not match inspection type'; end if;
  v_id := public.workshop_create_inspection(p_vehicle_id,p_inspection_type,p_mileage,p_notes,p_technician_profile_id);
  update public.workshop_inspections set template_id=p_template_id, template_name=v_template_name where id=v_id;
  insert into public.workshop_inspection_items(
    inspection_id, template_item_id, category, section_title, title, response_type,
    status, mandatory, repair_required, notes, photo_count, display_order,
    critical_safety_item, auto_create_repair, repair_priority, roadworthy_impact,
    photo_required_on_fail, allow_notes
  )
  select v_id, ti.id, ti.category, ti.section_title, ti.title, ti.response_type,
    ti.default_status, ti.mandatory, false, '', 0, ti.display_order,
    ti.critical_safety_item, ti.auto_create_repair, ti.repair_priority,
    ti.roadworthy_impact, ti.photo_required_on_fail, ti.allow_notes
  from public.workshop_inspection_template_items ti
  where ti.template_id=p_template_id order by ti.display_order;
  return v_id;
end; $$;

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
declare v_id uuid; v_assigned uuid; v_user text;
begin
  select wi.technician_profile_id into v_assigned
  from public.workshop_inspections wi
  join public.workshop_inspection_items ii on ii.inspection_id=wi.id
  where wi.id=p_inspection_id and ii.id=p_inspection_item_id;
  if not found then raise exception 'Inspection item not found'; end if;
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop') or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())) then
    raise exception 'Evidence upload access denied';
  end if;
  if p_size_bytes <= 0 or p_size_bytes > 10485760 then raise exception 'Evidence file size is invalid'; end if;
  if p_content_type not in ('image/jpeg','image/png','image/webp','application/pdf') then raise exception 'Unsupported evidence file type'; end if;
  if p_storage_path not like ('workshop/' || p_inspection_id::text || '/' || p_inspection_item_id::text || '/%') then raise exception 'Invalid evidence storage path'; end if;
  if not exists(select 1 from storage.objects where bucket_id='fleet-documents' and name=p_storage_path) then raise exception 'Evidence object was not uploaded'; end if;
  select username into v_user from public.profiles where id=auth.uid();
  insert into public.fleet_documents(entity_type,entity_id,category,inspection_id,inspection_item_id,file_name,storage_path,content_type,size_bytes,caption,uploaded_by,uploader_name)
  values('workshopInspectionItem',p_inspection_item_id,'inspectionEvidence',p_inspection_id,p_inspection_item_id,btrim(p_file_name),p_storage_path,p_content_type,p_size_bytes,coalesce(p_caption,''),auth.uid(),coalesce(v_user,''))
  returning id into v_id;
  update public.workshop_inspection_items set photo_count=photo_count+1 where id=p_inspection_item_id;
  return v_id;
end; $$;

-- Completion now respects the template's photo-required-on-fail contract.
create or replace function public.workshop_complete_inspection(p_inspection_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_assigned uuid; v_status text; v_fail int; v_critical int; v_adv int; v_repairs int; v_outstanding int; v_total int; v_score int; v_username text; v_not_roadworthy int;
begin
  select technician_profile_id,status into v_assigned,v_status from public.workshop_inspections where id=p_inspection_id;
  if not found then raise exception 'Inspection not found'; end if;
  if not (public.has_fleetiq_role('administrator') or public.has_fleetiq_role('manager') or public.has_fleetiq_role('workshop') or (public.has_fleetiq_role('technician') and v_assigned=auth.uid())) then raise exception 'Inspection completion access denied'; end if;
  if v_status in ('signedOff','cancelled') then raise exception 'Inspection is locked'; end if;
  if exists(select 1 from public.workshop_inspection_items where inspection_id=p_inspection_id and mandatory=true and status='notApplicable') then raise exception 'Complete all mandatory checklist items'; end if;
  if exists(select 1 from public.workshop_inspection_items where inspection_id=p_inspection_id and status='fail' and photo_required_on_fail=true and photo_count=0) then raise exception 'A required failure photo is missing'; end if;
  select count(*), count(*) filter(where status='fail'), count(*) filter(where status='fail' and critical_safety_item=true), count(*) filter(where status='advisory'), count(*) filter(where repair_required=true), count(*) filter(where status='fail' and roadworthy_impact='notRoadworthy')
    into v_total,v_fail,v_critical,v_adv,v_repairs,v_not_roadworthy from public.workshop_inspection_items where inspection_id=p_inspection_id;
  if v_total=0 then raise exception 'Inspection requires at least one checklist item'; end if;
  select count(*) into v_outstanding from public.workshop_repair_jobs where inspection_id=p_inspection_id and status not in ('completed','cancelled');
  v_score := greatest(0,least(100,100-(v_fail*20)-(v_adv*5)));
  select username into v_username from public.profiles where id=auth.uid();
  update public.workshop_inspections set
    overall_result=case when v_fail>0 then 'fail' when v_adv>0 then 'advisory' else 'pass' end,
    inspection_score=v_score,critical_failures=v_critical,advisories=v_adv,repairs_required=v_repairs,
    status=case when v_outstanding>0 then 'awaitingRepair' else 'completed' end,
    vehicle_status=case when v_outstanding>0 then 'awaitingRepair' when v_not_roadworthy>0 then 'notRoadworthy' else 'roadworthy' end,
    date_completed=case when v_outstanding=0 then now() else null end,
    technician_signature=coalesce(technician_signature,v_username)
  where id=p_inspection_id;
end; $$;

revoke all on function public.workshop_create_inspection_from_template(uuid,uuid,text,integer,text,uuid) from public,anon;
revoke all on function public.workshop_register_evidence(uuid,uuid,text,text,text,bigint,text) from public,anon;
grant execute on function public.workshop_create_inspection_from_template(uuid,uuid,text,integer,text,uuid) to authenticated;
grant execute on function public.workshop_register_evidence(uuid,uuid,text,text,text,bigint,text) to authenticated;

-- Direct database mutations remain closed. Storage object writes are bucket/RLS scoped above.
revoke insert,update,delete on public.workshop_inspection_templates from anon,authenticated;
revoke insert,update,delete on public.workshop_inspection_template_items from anon,authenticated;
revoke insert,update,delete on public.fleet_documents from anon,authenticated;
