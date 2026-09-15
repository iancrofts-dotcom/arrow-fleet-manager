-- FleetIQ Build 17.4.6.19.3
-- Multi-company management completion.
-- Adds company identity/settings, explicit ownership and owner safeguards.

alter table public.organisations
  add column if not exists owner_user_id uuid references auth.users(id) on delete restrict,
  add column if not exists legal_name text,
  add column if not exists contact_email text,
  add column if not exists phone text,
  add column if not exists address_line1 text,
  add column if not exists address_line2 text,
  add column if not exists town_city text,
  add column if not exists postcode text,
  add column if not exists company_number text,
  add column if not exists report_footer text;

-- Backfill ownership from the creator where possible, otherwise prefer an
-- active Administrator membership, then any active member. This keeps the
-- Build 18 bootstrapped production organisation valid even though its creator
-- was intentionally null.
update public.organisations o
   set owner_user_id = coalesce(
     case when exists (
       select 1 from public.organisation_memberships m
       where m.organisation_id = o.id
         and m.user_id = o.created_by
         and m.is_active
     ) then o.created_by end,
     (
       select m.user_id
       from public.organisation_memberships m
       where m.organisation_id = o.id
         and m.is_active
         and m.role = 'administrator'
       order by m.created_at
       limit 1
     ),
     (
       select m.user_id
       from public.organisation_memberships m
       where m.organisation_id = o.id
         and m.is_active
       order by m.created_at
       limit 1
     )
   )
 where o.owner_user_id is null;

-- An owner must always remain an active Administrator of their company.
update public.organisation_memberships m
   set role = 'administrator',
       is_active = true,
       updated_at = now()
  from public.organisations o
 where o.id = m.organisation_id
   and o.owner_user_id = m.user_id
   and (m.role <> 'administrator' or not m.is_active);

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
  where m.user_id = v_user
    and m.organisation_id = v_current
    and m.is_active;

  if v_role <> 'administrator' then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_name, ''))) < 2 then
    raise exception 'Company name is required.' using errcode = '22023';
  end if;
  if coalesce(p_slug, '') !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' then
    raise exception 'Company code is invalid.' using errcode = '22023';
  end if;

  insert into public.organisations(name, slug, created_by, owner_user_id)
  values (trim(p_name), lower(trim(p_slug)), v_user, v_user)
  returning * into v_org;

  insert into public.organisation_memberships(
    organisation_id,
    user_id,
    is_active,
    role,
    custom_role_id
  ) values (
    v_org.id,
    v_user,
    true,
    'administrator',
    null
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

create or replace function public.fleet_get_current_organisation_settings()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_org uuid;
  v_role text;
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  where m.user_id = auth.uid()
    and m.organisation_id = v_org
    and m.is_active;
  if v_role <> 'administrator' then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'id', o.id,
    'name', o.name,
    'slug', o.slug,
    'owner_user_id', o.owner_user_id,
    'legal_name', coalesce(o.legal_name, ''),
    'contact_email', coalesce(o.contact_email, ''),
    'phone', coalesce(o.phone, ''),
    'address_line1', coalesce(o.address_line1, ''),
    'address_line2', coalesce(o.address_line2, ''),
    'town_city', coalesce(o.town_city, ''),
    'postcode', coalesce(o.postcode, ''),
    'company_number', coalesce(o.company_number, ''),
    'report_footer', coalesce(o.report_footer, '')
  ) into v_result
  from public.organisations o
  where o.id = v_org;

  if v_result is null then
    raise exception 'Active FleetIQ organisation not found.' using errcode = '42501';
  end if;
  return v_result;
end;
$$;

revoke all on function public.fleet_get_current_organisation_settings() from public;
grant execute on function public.fleet_get_current_organisation_settings() to authenticated;

create or replace function public.fleet_update_current_organisation_settings(
  p_name text,
  p_legal_name text,
  p_contact_email text,
  p_phone text,
  p_address_line1 text,
  p_address_line2 text,
  p_town_city text,
  p_postcode text,
  p_company_number text,
  p_report_footer text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_org uuid;
  v_role text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  v_org := public.fleet_current_organisation_id();
  select m.role into v_role
  from public.organisation_memberships m
  where m.user_id = auth.uid()
    and m.organisation_id = v_org
    and m.is_active;
  if v_role <> 'administrator' then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_name, ''))) < 2 then
    raise exception 'Company name is required.' using errcode = '22023';
  end if;
  if length(trim(coalesce(p_contact_email, ''))) > 0
     and trim(p_contact_email) !~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Company contact email is invalid.' using errcode = '22023';
  end if;

  update public.organisations
     set name = trim(p_name),
         legal_name = nullif(trim(coalesce(p_legal_name, '')), ''),
         contact_email = nullif(lower(trim(coalesce(p_contact_email, ''))), ''),
         phone = nullif(trim(coalesce(p_phone, '')), ''),
         address_line1 = nullif(trim(coalesce(p_address_line1, '')), ''),
         address_line2 = nullif(trim(coalesce(p_address_line2, '')), ''),
         town_city = nullif(trim(coalesce(p_town_city, '')), ''),
         postcode = nullif(upper(trim(coalesce(p_postcode, ''))), ''),
         company_number = nullif(upper(trim(coalesce(p_company_number, ''))), ''),
         report_footer = nullif(trim(coalesce(p_report_footer, '')), ''),
         updated_at = now()
   where id = v_org;

  return public.fleet_get_current_organisation_settings();
end;
$$;

revoke all on function public.fleet_update_current_organisation_settings(
  text, text, text, text, text, text, text, text, text, text
) from public;
grant execute on function public.fleet_update_current_organisation_settings(
  text, text, text, text, text, text, text, text, text, text
) to authenticated;

-- Defensive trigger: an organisation owner cannot silently lose the active
-- Administrator membership that anchors company administration.
create or replace function public.fleet_protect_organisation_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  select o.owner_user_id into v_owner
  from public.organisations o
  where o.id = case
    when tg_op = 'DELETE' then old.organisation_id
    else new.organisation_id
  end;

  if v_owner is not null and old.user_id = v_owner then
    if tg_op = 'DELETE' then
      raise exception 'Transfer company ownership before removing the owner.' using errcode = '42501';
    end if;
    if new.role <> 'administrator' or not new.is_active then
      raise exception 'The company owner must remain an active Administrator.' using errcode = '42501';
    end if;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists fleet_protect_organisation_owner_membership_trigger
  on public.organisation_memberships;
create trigger fleet_protect_organisation_owner_membership_trigger
before update or delete on public.organisation_memberships
for each row execute function public.fleet_protect_organisation_owner_membership();
