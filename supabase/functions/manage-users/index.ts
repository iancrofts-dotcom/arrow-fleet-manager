import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const allowedRoles = new Set([
  'administrator',
  'manager',
  'workshop',
  'technician',
  'driver',
]);

const allowedCustomPermissions = new Set([
  'view_vehicles', 'manage_vehicles', 'view_drivers', 'manage_drivers',
  'view_compliance', 'manage_compliance', 'access_calendar',
  'access_workshop', 'operate_workshop', 'manage_workshop',
  'signoff_inspection', 'manage_inspection_templates', 'view_reports',
  'view_documents', 'manage_documents', 'view_kpis',
]);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function text(value: unknown) {
  return typeof value === 'string' ? value.trim() : '';
}

function bool(value: unknown, fallback = false) {
  return typeof value === 'boolean' ? value : fallback;
}

function role(value: unknown) {
  const parsed = text(value);
  if (!allowedRoles.has(parsed)) throw new Error('Invalid FleetIQ role.');
  return parsed;
}

function customPermissions(value: unknown) {
  if (!Array.isArray(value)) throw new Error('Custom role permissions are required.');
  const values = value.map((item) => text(item)).filter(Boolean);
  if (values.length === 0) throw new Error('Select at least one custom-role permission.');
  for (const permission of values) {
    if (!allowedCustomPermissions.has(permission)) {
      throw new Error('Invalid custom-role permission.');
    }
  }
  return [...new Set(values)];
}

async function profileFor(admin: ReturnType<typeof createClient>, id: string) {
  const { data, error } = await admin
    .from('profiles')
    .select('id, username, role, is_active, driver_id, created_at, active_organisation_id, custom_role_id')
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function findAuthUserByEmail(
  admin: ReturnType<typeof createClient>,
  email: string,
) {
  let page = 1;
  while (true) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw error;
    const found = data.users.find(
      (user) => (user.email ?? '').trim().toLowerCase() === email,
    );
    if (found) return found;
    if (data.users.length < 1000) return null;
    page++;
  }
}

async function ensureAdministrator(
  admin: ReturnType<typeof createClient>,
  authorization: string,
  supabaseUrl: string,
  anonKey: string,
) {
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await callerClient.auth.getUser();
  if (error || !data.user) throw new Error('Authentication required.');
  const profile = await profileFor(admin, data.user.id);
  if (!profile || !profile.is_active) throw new Error('Administrator access required.');
  const organisationId = profile.active_organisation_id;
  if (!organisationId) throw new Error('Select an active FleetIQ organisation first.');
  const { data: membership, error: membershipError } = await admin
    .from('organisation_memberships')
    .select('organisation_id, role, custom_role_id, is_active')
    .eq('organisation_id', organisationId)
    .eq('user_id', data.user.id)
    .eq('is_active', true)
    .maybeSingle();
  if (membershipError) throw membershipError;
  if (!membership || membership.role !== 'administrator') {
    throw new Error('Administrator access required.');
  }
  return { user: data.user, profile, membership, organisationId };
}

async function validateCustomRole(
  admin: ReturnType<typeof createClient>,
  organisationId: string,
  customRoleId: string | null,
) {
  if (!customRoleId) return;
  const { data, error } = await admin
    .from('custom_roles')
    .select('id, is_active')
    .eq('id', customRoleId)
    .eq('organisation_id', organisationId)
    .maybeSingle();
  if (error) throw error;
  if (!data?.is_active) throw new Error('Selected custom role is not available.');
}

async function ensureAdministratorRemains(
  admin: ReturnType<typeof createClient>,
  targetId: string,
  organisationId: string,
  nextRole: string | null,
  nextActive: boolean | null,
) {
  const { data: target, error: targetError } = await admin
    .from('organisation_memberships')
    .select('user_id, role, custom_role_id, is_active')
    .eq('organisation_id', organisationId)
    .eq('user_id', targetId)
    .maybeSingle();
  if (targetError) throw targetError;
  if (!target) throw new Error('User is not in the active FleetIQ company.');

  const removesActiveAdministrator = target.role === 'administrator' &&
    target.is_active === true &&
    ((nextRole !== null && nextRole !== 'administrator') || nextActive === false);
  if (!removesActiveAdministrator) return target;

  const { count, error } = await admin
    .from('organisation_memberships')
    .select('user_id', { count: 'exact', head: true })
    .eq('organisation_id', organisationId)
    .eq('role', 'administrator')
    .eq('is_active', true)
    .neq('user_id', targetId);
  if (error) throw error;
  if ((count ?? 0) < 1) {
    throw new Error('At least one active Administrator is required.');
  }
  return target;
}

async function ensureNotOwner(
  admin: ReturnType<typeof createClient>,
  targetId: string,
  organisationId: string,
) {
  const { data, error } = await admin
    .from('organisations')
    .select('owner_user_id')
    .eq('id', organisationId)
    .single();
  if (error) throw error;
  if (data.owner_user_id === targetId) {
    throw new Error('Transfer company ownership before removing or demoting the owner.');
  }
}

async function membershipFor(
  admin: ReturnType<typeof createClient>,
  organisationId: string,
  userId: string,
) {
  const { data, error } = await admin
    .from('organisation_memberships')
    .select('organisation_id, user_id, role, custom_role_id, is_active, created_at')
    .eq('organisation_id', organisationId)
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function combinedUser(
  admin: ReturnType<typeof createClient>,
  userId: string,
  organisationId: string,
) {
  const profile = await profileFor(admin, userId);
  if (!profile) throw new Error('FleetIQ profile not found.');
  const membership = await membershipFor(admin, organisationId, userId);
  if (!membership) throw new Error('FleetIQ membership not found.');
  const { data, error } = await admin.auth.admin.getUserById(userId);
  if (error || !data.user) throw error ?? new Error('Auth user not found.');
  let customRoleName: string | null = null;
  if (membership.custom_role_id) {
    const { data: customRole, error: customRoleError } = await admin
      .from('custom_roles')
      .select('name')
      .eq('id', membership.custom_role_id)
      .eq('organisation_id', organisationId)
      .maybeSingle();
    if (customRoleError) throw customRoleError;
    customRoleName = customRole?.name ?? null;
  }
  return {
    id: userId,
    email: data.user.email ?? '',
    username: profile.username ?? '',
    role: membership.role,
    custom_role_id: membership.custom_role_id,
    custom_role_name: customRoleName,
    is_active: membership.is_active && profile.is_active,
    driver_id: profile.driver_id,
    created_at: data.user.created_at ?? profile.created_at,
    last_sign_in_at: data.user.last_sign_in_at ?? null,
  };
}

async function syncProfileMirrorIfActiveOrganisation(
  admin: ReturnType<typeof createClient>,
  userId: string,
  organisationId: string,
) {
  const profile = await profileFor(admin, userId);
  if (!profile || profile.active_organisation_id !== organisationId) return;
  const membership = await membershipFor(admin, organisationId, userId);
  if (!membership) return;
  const { error } = await admin.from('profiles').update({
    role: membership.role,
    custom_role_id: membership.custom_role_id,
    updated_at: new Date().toISOString(),
  }).eq('id', userId);
  if (error) throw error;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const authorization = req.headers.get('Authorization') ?? '';
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return json({ error: 'FleetIQ user-management service is not configured.' }, 500);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const caller = await ensureAdministrator(
      admin,
      authorization,
      supabaseUrl,
      anonKey,
    );
    const body = await req.json().catch(() => ({}));
    const operation = text(body.operation);

    if (operation === 'list_roles') {
      const { data: roles, error } = await admin
        .from('custom_roles')
        .select('id, name, description, permissions, is_active, created_at, updated_at')
        .eq('organisation_id', caller.organisationId)
        .order('name');
      if (error) throw error;
      return json({ roles: roles ?? [] });
    }

    if (operation === 'create_role') {
      const name = text(body.name);
      const description = text(body.description);
      const permissions = customPermissions(body.permissions);
      if (name.length < 2) throw new Error('Custom role name is required.');
      const { data: saved, error } = await admin
        .from('custom_roles')
        .insert({
          organisation_id: caller.organisationId,
          name,
          description,
          permissions,
          is_active: true,
          created_by: caller.user.id,
        })
        .select('id, name, description, permissions, is_active, created_at, updated_at')
        .single();
      if (error || !saved) throw error ?? new Error('Unable to create custom role.');
      return json({ role: saved }, 201);
    }

    if (operation === 'update_role') {
      const id = text(body.id);
      const name = text(body.name);
      const description = text(body.description);
      const permissions = customPermissions(body.permissions);
      const isActive = bool(body.is_active, true);
      if (!id || name.length < 2) throw new Error('Custom role details are required.');
      const { data: saved, error } = await admin
        .from('custom_roles')
        .update({
          name,
          description,
          permissions,
          is_active: isActive,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id)
        .eq('organisation_id', caller.organisationId)
        .select('id, name, description, permissions, is_active, created_at, updated_at')
        .single();
      if (error || !saved) throw error ?? new Error('Unable to update custom role.');
      return json({ role: saved });
    }

    if (operation === 'delete_role') {
      const id = text(body.id);
      if (!id) throw new Error('Custom role ID is required.');
      const { count, error: assignmentError } = await admin
        .from('organisation_memberships')
        .select('user_id', { count: 'exact', head: true })
        .eq('organisation_id', caller.organisationId)
        .eq('custom_role_id', id);
      if (assignmentError) throw assignmentError;
      if ((count ?? 0) > 0) {
        throw new Error('Reassign users before deleting this custom role.');
      }
      const { error } = await admin
        .from('custom_roles')
        .delete()
        .eq('id', id)
        .eq('organisation_id', caller.organisationId);
      if (error) throw error;
      return json({ ok: true });
    }

    if (operation === 'list') {
      const { data: memberships, error: membershipError } = await admin
        .from('organisation_memberships')
        .select('user_id')
        .eq('organisation_id', caller.organisationId);
      if (membershipError) throw membershipError;
      const users = await Promise.all(
        (memberships ?? []).map((item) =>
          combinedUser(admin, item.user_id, caller.organisationId)
        ),
      );
      users.sort((a, b) => String(a.username || a.email).localeCompare(String(b.username || b.email)));
      return json({ users });
    }

    if (operation === 'invite_or_add') {
      const email = text(body.email).toLowerCase();
      const username = text(body.username);
      const nextRole = role(body.role);
      const customRoleId = text(body.custom_role_id) || null;
      const isActive = bool(body.is_active, true);
      if (!email.includes('@')) throw new Error('A valid login email is required.');
      if (!username) throw new Error('A display name is required.');
      if (nextRole === 'driver') {
        throw new Error('Driver accounts must be created through Driver Management.');
      }
      await validateCustomRole(admin, caller.organisationId, customRoleId);
      const effectiveRole = customRoleId ? 'manager' : nextRole;

      let authUser = await findAuthUserByEmail(admin, email);
      let invited = false;
      if (!authUser) {
        const inviteRedirect = Deno.env.get('FLEETIQ_PASSWORD_REDIRECT_URL') ??
          'https://fleetiq.unaux.com/app/?route=set-password';
        const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
          redirectTo: inviteRedirect,
          data: { username, organisation_id: caller.organisationId },
        });
        if (error || !data.user) {
          throw error ?? new Error('Unable to send the FleetIQ invitation.');
        }
        authUser = data.user;
        invited = true;
      }

      const profile = await profileFor(admin, authUser.id);
      if (!profile) throw new Error('FleetIQ profile was not created for this login.');
      if (profile.driver_id) {
        throw new Error('Driver-linked accounts must be managed through Driver Management.');
      }
      const existingMembership = await membershipFor(
        admin,
        caller.organisationId,
        authUser.id,
      );
      if (existingMembership?.is_active) {
        throw new Error('This user already belongs to the current company.');
      }

      const { error: membershipError } = await admin
        .from('organisation_memberships')
        .upsert({
          organisation_id: caller.organisationId,
          user_id: authUser.id,
          role: effectiveRole,
          custom_role_id: customRoleId,
          is_active: isActive,
          updated_at: new Date().toISOString(),
        });
      if (membershipError) throw membershipError;

      const profileChanges: Record<string, unknown> = {};
      if (!profile.username) profileChanges.username = username;
      if (!profile.active_organisation_id) {
        profileChanges.active_organisation_id = caller.organisationId;
        profileChanges.role = effectiveRole;
        profileChanges.custom_role_id = customRoleId;
      }
      if (Object.keys(profileChanges).length > 0) {
        profileChanges.updated_at = new Date().toISOString();
        const { error } = await admin.from('profiles').update(profileChanges).eq('id', authUser.id);
        if (error) throw error;
      }

      return json({
        user: await combinedUser(admin, authUser.id, caller.organisationId),
        invited,
      }, invited ? 201 : 200);
    }

    if (operation === 'update_membership') {
      const id = text(body.id);
      const nextRole = role(body.role);
      const customRoleId = text(body.custom_role_id) || null;
      const isActive = bool(body.is_active, true);
      if (!id) throw new Error('User ID is required.');
      if (nextRole === 'driver') {
        throw new Error('Driver-linked accounts are managed through Driver Management.');
      }
      await validateCustomRole(admin, caller.organisationId, customRoleId);
      const effectiveRole = customRoleId ? 'manager' : nextRole;
      const profile = await profileFor(admin, id);
      if (!profile) throw new Error('The user account no longer exists.');
      if (profile.driver_id) {
        throw new Error('Driver-linked accounts are managed through Driver Management.');
      }
      if (id === caller.user.id && (!isActive || effectiveRole !== 'administrator')) {
        throw new Error('You cannot deactivate or demote your own current-company membership.');
      }
      const current = await ensureAdministratorRemains(
        admin,
        id,
        caller.organisationId,
        effectiveRole,
        isActive,
      );
      if (current.role === 'administrator' && effectiveRole !== 'administrator') {
        await ensureNotOwner(admin, id, caller.organisationId);
      }

      const { error } = await admin
        .from('organisation_memberships')
        .update({
          role: effectiveRole,
          custom_role_id: customRoleId,
          is_active: isActive,
          updated_at: new Date().toISOString(),
        })
        .eq('organisation_id', caller.organisationId)
        .eq('user_id', id);
      if (error) throw error;
      await syncProfileMirrorIfActiveOrganisation(admin, id, caller.organisationId);
      return json({ user: await combinedUser(admin, id, caller.organisationId) });
    }

    if (operation === 'remove_membership') {
      const id = text(body.id);
      if (!id) throw new Error('User ID is required.');
      if (id === caller.user.id) {
        throw new Error('You cannot remove your own current-company membership.');
      }
      const profile = await profileFor(admin, id);
      if (!profile) throw new Error('The user account no longer exists.');
      if (profile.driver_id) {
        throw new Error('Driver-linked accounts are managed through Driver Management.');
      }
      await ensureNotOwner(admin, id, caller.organisationId);
      await ensureAdministratorRemains(
        admin,
        id,
        caller.organisationId,
        null,
        false,
      );

      const { error: deleteError } = await admin
        .from('organisation_memberships')
        .delete()
        .eq('organisation_id', caller.organisationId)
        .eq('user_id', id);
      if (deleteError) throw deleteError;

      const { data: remaining, error: remainingError } = await admin
        .from('organisation_memberships')
        .select('organisation_id, role, custom_role_id, is_active')
        .eq('user_id', id)
        .eq('is_active', true)
        .limit(1);
      if (remainingError) throw remainingError;
      if (!remaining || remaining.length === 0) {
        const { error } = await admin.auth.admin.deleteUser(id);
        if (error) throw error;
      } else if (profile.active_organisation_id === caller.organisationId) {
        const next = remaining[0];
        const { error } = await admin.from('profiles').update({
          active_organisation_id: next.organisation_id,
          role: next.role,
          custom_role_id: next.custom_role_id,
          updated_at: new Date().toISOString(),
        }).eq('id', id);
        if (error) throw error;
      }
      return json({ ok: true });
    }

    return json({ error: 'Unsupported user-management operation.' }, 400);
  } catch (error) {
    console.error(error);
    return json({ error: error instanceof Error ? error.message : 'Unexpected error.' }, 400);
  }
});
