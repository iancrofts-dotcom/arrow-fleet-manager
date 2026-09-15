begin;

create table if not exists public.fleet_legal_documents (
  id uuid primary key default gen_random_uuid(), kind text not null, version text not null, title text not null,
  content text not null, requires_acceptance boolean not null default false, active boolean not null default true,
  effective_at timestamptz not null default now(), created_at timestamptz not null default now(), unique(kind,version)
);
create table if not exists public.fleet_legal_acceptances (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  organisation_id uuid references public.organisations(id) on delete set null, kind text not null, version text not null,
  accepted_at timestamptz not null default now(), unique(user_id,organisation_id,kind,version)
);
create table if not exists public.fleet_data_requests (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete restrict,
  requested_by uuid not null references auth.users(id) on delete restrict, request_type text not null check(request_type in ('access','rectification','erasure','restriction','objection','portability','other')),
  details text not null default '', status text not null default 'open' check(status in ('open','in_review','completed','declined')),
  created_at timestamptz not null default now(), completed_at timestamptz
);
create table if not exists public.fleet_offboarding_requests (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete restrict,
  requested_by uuid not null references auth.users(id) on delete restrict, request_export boolean not null default true,
  details text not null default '', status text not null default 'open' check(status in ('open','export_preparing','export_ready','deletion_scheduled','completed','cancelled')),
  created_at timestamptz not null default now(), completed_at timestamptz
);

alter table public.fleet_legal_documents enable row level security;
alter table public.fleet_legal_acceptances enable row level security;
alter table public.fleet_data_requests enable row level security;
alter table public.fleet_offboarding_requests enable row level security;

create policy legal_documents_authenticated_read on public.fleet_legal_documents for select to authenticated using(active);
create policy legal_acceptances_own_read on public.fleet_legal_acceptances for select to authenticated using(user_id=auth.uid());
create policy data_requests_tenant_read on public.fleet_data_requests for select to authenticated using(organisation_id=public.fleet_current_organisation_id());
create policy offboarding_tenant_read on public.fleet_offboarding_requests for select to authenticated using(organisation_id=public.fleet_current_organisation_id());

create or replace function public.fleet_list_current_legal_documents() returns setof public.fleet_legal_documents language sql security definer set search_path=public as $$
 select * from public.fleet_legal_documents where active order by kind,effective_at desc;
$$;
create or replace function public.fleet_required_legal_acceptances() returns table(required_key text) language sql security definer set search_path=public as $$
 select d.kind||':'||d.version from public.fleet_legal_documents d where d.active and d.requires_acceptance and not exists(
  select 1 from public.fleet_legal_acceptances a where a.user_id=auth.uid() and a.kind=d.kind and a.version=d.version and a.organisation_id is not distinct from public.fleet_current_organisation_id());
$$;
create or replace function public.fleet_accept_legal_document(p_kind text,p_version text) returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.fleet_legal_documents where kind=p_kind and version=p_version and active and requires_acceptance) then raise exception 'Legal document version is not active'; end if;
 insert into public.fleet_legal_acceptances(user_id,organisation_id,kind,version) values(auth.uid(),public.fleet_current_organisation_id(),p_kind,p_version) on conflict do nothing;
end$$;
create or replace function public.fleet_create_data_request(p_request_type text,p_details text default '') returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_org uuid:=public.fleet_current_organisation_id(); begin
 if v_org is null then raise exception 'Active organisation required'; end if;
 insert into public.fleet_data_requests(organisation_id,requested_by,request_type,details) values(v_org,auth.uid(),p_request_type,coalesce(p_details,'')) returning id into v_id; return v_id; end$$;
create or replace function public.fleet_create_offboarding_request(p_request_export boolean default true,p_details text default '') returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_org uuid:=public.fleet_current_organisation_id(); begin
 if v_org is null then raise exception 'Active organisation required'; end if;
 if not exists(select 1 from public.organisation_memberships where organisation_id=v_org and user_id=auth.uid() and role='administrator' and active) then raise exception 'Administrator required'; end if;
 insert into public.fleet_offboarding_requests(organisation_id,requested_by,request_export,details) values(v_org,auth.uid(),coalesce(p_request_export,true),coalesce(p_details,'')) returning id into v_id; return v_id; end$$;

revoke all on function public.fleet_list_current_legal_documents() from public,anon;
revoke all on function public.fleet_required_legal_acceptances() from public,anon;
revoke all on function public.fleet_accept_legal_document(text,text) from public,anon;
revoke all on function public.fleet_create_data_request(text,text) from public,anon;
revoke all on function public.fleet_create_offboarding_request(boolean,text) from public,anon;
grant execute on function public.fleet_list_current_legal_documents() to authenticated;
grant execute on function public.fleet_required_legal_acceptances() to authenticated;
grant execute on function public.fleet_accept_legal_document(text,text) to authenticated;
grant execute on function public.fleet_create_data_request(text,text) to authenticated;
grant execute on function public.fleet_create_offboarding_request(boolean,text) to authenticated;

insert into public.fleet_legal_documents(kind,version,title,content,requires_acceptance) values
('privacy','2026-09-15','FleetIQ Privacy Notice','FleetIQ provides fleet-management software to customer organisations. Customer organisations generally determine the purposes for which driver, employee, vehicle and operational personal data are used and FleetIQ processes that data to provide the service. FleetIQ may separately act as controller for account administration, security, support and commercial records. Personal data may include account identity and contact details, driver and compliance records, vehicle assignments, inspection and workshop records, uploaded evidence, audit information and technical/security logs. We use appropriate access controls, tenant separation and security measures. Retention depends on the record, customer instructions, contractual needs and applicable law. Individuals may have rights including access, rectification, erasure, restriction, objection and portability where applicable. Requests can be submitted through the FleetIQ Legal & Privacy Centre. This notice must be completed with FleetIQ operator identity, registered/contact address, privacy email, lawful-basis schedule, final subprocessor/transfer details and complaint information before commercial launch.',true),
('terms','2026-09-15','FleetIQ SaaS Terms','These draft SaaS Terms govern authorised use of FleetIQ by subscribing organisations and their users. They cover account security, permitted use, customer responsibility for lawful fleet data, service availability, intellectual property, fees/subscription terms, suspension, termination, confidentiality, data protection, liability and support. Commercial figures, contracting entity details, governing-law wording, service levels and liability caps must be approved before launch. These terms are an implementation draft and require final UK legal review.',true),
('dpa','2026-09-15','FleetIQ Data Processing Addendum','Where FleetIQ processes personal data on behalf of a customer controller, FleetIQ will process on documented instructions; ensure authorised personnel are bound by confidentiality; apply appropriate security measures; control subprocessors under equivalent written obligations; assist with data-subject rights and relevant security, breach and DPIA obligations; and on termination return or delete personal data as agreed, subject to applicable law and protected backup cycles. FleetIQ will provide information reasonably necessary to demonstrate Article 28 compliance and support appropriate audits. The processing schedule and final subprocessor/international-transfer terms must be completed for each commercial contract.',false),
('security','2026-09-15','FleetIQ Security Overview','FleetIQ uses authenticated access, organisation-scoped tenancy, database row-level security, role and permission controls, tenant-scoped document paths, resilient central operations and audit-oriented records. Production operational controls must include managed secrets, backups and recovery testing, vulnerability/dependency management, incident response, access review, secure release practices and documented breach handling.',false),
('retention','2026-09-15','FleetIQ Retention & Deletion Policy','FleetIQ does not apply indiscriminate deletion to fleet compliance and audit records. Retention is determined by record purpose, customer instructions, contractual obligations and applicable legal requirements. Data-subject and offboarding requests are recorded for controlled review. At contract end, customer personal data is returned or deleted as agreed unless retention is required by law; protected backups may expire through documented deletion cycles while remaining beyond normal use.',false)
on conflict(kind,version) do nothing;
commit;
