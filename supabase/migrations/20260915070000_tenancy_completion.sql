-- FleetIQ Build 17.4.6.19.4
-- Final tenancy completion: explicit, auditable organisation ownership transfer.
-- Billing/subscription ownership remains a separate commercial concern.

create or replace function public.fleet_transfer_current_organisation_ownership(
  p_new_owner_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user uuid := auth.uid();
  v_org uuid;
  v_owner uuid;
  v_target_role text;
  v_target_active boolean;
begin
  if v_user is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  v_org := public.fleet_current_organisation_id();

  -- Ownership transfer is deliberately stricter than ordinary Administrator
  -- management. Only the current protected owner can transfer ownership.
  select o.owner_user_id
    into v_owner
    from public.organisations o
   where o.id = v_org
   for update;

  if v_owner is distinct from v_user then
    raise exception 'Only the current company owner can transfer ownership.'
      using errcode = '42501';
  end if;

  if p_new_owner_user_id is null or p_new_owner_user_id = v_user then
    raise exception 'Choose another active Administrator.' using errcode = '22023';
  end if;

  select m.role, m.is_active
    into v_target_role, v_target_active
    from public.organisation_memberships m
   where m.organisation_id = v_org
     and m.user_id = p_new_owner_user_id;

  if not found or not coalesce(v_target_active, false)
     or v_target_role <> 'administrator' then
    raise exception 'The new owner must be an active Administrator of this company.'
      using errcode = '42501';
  end if;

  update public.organisations
     set owner_user_id = p_new_owner_user_id,
         updated_at = now()
   where id = v_org;

  -- Keep both old and new owner memberships active Administrators at the
  -- instant of transfer. The former owner can be changed later by normal
  -- membership management; the new owner is protected by the existing trigger.
  update public.organisation_memberships
     set role = 'administrator',
         custom_role_id = null,
         is_active = true,
         updated_at = now()
   where organisation_id = v_org
     and user_id in (v_user, p_new_owner_user_id);
end;
$$;

revoke all on function public.fleet_transfer_current_organisation_ownership(uuid)
  from public;
grant execute on function public.fleet_transfer_current_organisation_ownership(uuid)
  to authenticated;
