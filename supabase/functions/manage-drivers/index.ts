import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function text(value: unknown) {
  return typeof value === 'string' ? value.trim() : '';
}

function nullable(value: unknown) {
  const parsed = text(value);
  return parsed.length === 0 ? null : parsed;
}

function bool(value: unknown, fallback = true) {
  return typeof value === 'boolean' ? value : fallback;
}

async function callerProfile(admin: any, req: Request, url: string, anon: string) {
  const auth = req.headers.get('Authorization') ?? '';
  const caller = createClient(url, anon, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await caller.auth.getUser();
  if (error || !data.user) throw new Error('Authentication required.');
  const { data: profile, error: profileError } = await admin
    .from('profiles')
    .select('id, role, is_active, active_organisation_id, custom_role_id')
    .eq('id', data.user.id)
    .maybeSingle();
  if (profileError) throw profileError;
  if (!profile || !profile.is_active || !['administrator', 'manager'].includes(profile.role)) {
    throw new Error('Fleet Manager or Administrator access required.');
  }
  if (profile.custom_role_id) {
    const { data: customRole, error: customRoleError } = await admin
      .from('custom_roles')
      .select('permissions, is_active')
      .eq('id', profile.custom_role_id)
      .maybeSingle();
    if (customRoleError) throw customRoleError;
    const permissions = Array.isArray(customRole?.permissions) ? customRole.permissions : [];
    if (!customRole?.is_active || !permissions.includes('manage_drivers')) {
      throw new Error('Driver management permission required.');
    }
  }
  const organisationId = profile.active_organisation_id;
  if (!organisationId) throw new Error('Select an active FleetIQ organisation first.');
  const { data: membership, error: membershipError } = await admin
    .from('organisation_memberships')
    .select('organisation_id')
    .eq('organisation_id', organisationId)
    .eq('user_id', data.user.id)
    .eq('is_active', true)
    .maybeSingle();
  if (membershipError) throw membershipError;
  if (!membership) throw new Error('Active FleetIQ organisation membership required.');
  return { ...profile, organisation_id: organisationId };
}

async function driverRow(admin: any, id: string, organisationId: string) {
  const { data, error } = await admin
    .from('drivers')
    .select('id, legacy_id, first_name, last_name, licence_number, licence_expiry, phone, email, username, is_active, created_at, updated_at')
    .eq('id', id)
    .eq('organisation_id', organisationId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function linkedProfile(admin: any, driverId: string, organisationId: string) {
  const { data, error } = await admin
    .from('profiles')
    .select('id, username, role, is_active, driver_id')
    .eq('driver_id', driverId)
    .maybeSingle();
  if (error) throw error;
  if (!data) return null;
  const { data: membership, error: membershipError } = await admin
    .from('organisation_memberships')
    .select('organisation_id')
    .eq('organisation_id', organisationId)
    .eq('user_id', data.id)
    .eq('is_active', true)
    .maybeSingle();
  if (membershipError) throw membershipError;
  return membership ? data : null;
}

function validate(body: Record<string, unknown>) {
  const firstName = text(body.first_name);
  const lastName = text(body.last_name);
  const licenceNumber = text(body.licence_number);
  const email = text(body.email).toLowerCase();
  const username = text(body.username);
  if (!firstName || !lastName || !licenceNumber) {
    throw new Error('Driver name and licence number are required.');
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new Error('A valid Driver login email is required.');
  }
  if (!username) throw new Error('A Driver username is required.');
  return {
    first_name: firstName,
    last_name: lastName,
    licence_number: licenceNumber,
    licence_expiry: nullable(body.licence_expiry),
    phone: nullable(body.phone),
    email,
    username,
    is_active: bool(body.is_active, true),
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  try {
    const url = Deno.env.get('SUPABASE_URL') ?? '';
    const anon = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    if (!url || !anon || !service) throw new Error('Driver management service is not configured.');
    const admin = createClient(url, service, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const caller = await callerProfile(admin, req, url, anon);
    const body = await req.json().catch(() => ({}));
    const operation = text(body.operation);

    if (operation === 'create') {
      const values = validate(body);
      let driverId: string | null = null;
      let authUserId: string | null = null;
      try {
        const { data: driver, error: driverError } = await admin
          .from('drivers')
          .insert({
            first_name: values.first_name,
            last_name: values.last_name,
            licence_number: values.licence_number,
            licence_expiry: values.licence_expiry,
            phone: values.phone,
            email: values.email,
            username: values.username,
            is_active: values.is_active,
            organisation_id: caller.organisation_id,
          })
          .select('id')
          .single();
        if (driverError || !driver) throw driverError ?? new Error('Unable to create Driver.');
        driverId = driver.id;

        const inviteRedirect = Deno.env.get('FLEETIQ_PASSWORD_REDIRECT_URL') ??
          'https://fleetiq.unaux.com/app/?route=set-password';
        const { data: authData, error: authError } = await admin.auth.admin.inviteUserByEmail(
          values.email,
          {
            redirectTo: inviteRedirect,
            data: { username: values.username, driver_id: driverId, organisation_id: caller.organisation_id },
          },
        );
        if (authError || !authData.user) {
          throw authError ?? new Error('Unable to send the Driver invitation.');
        }
        authUserId = authData.user.id;

        const { error: profileError } = await admin
          .from('profiles')
          .update({
            username: values.username,
            role: 'driver',
            is_active: values.is_active,
            driver_id: driverId,
            updated_at: new Date().toISOString(),
          })
          .eq('id', authUserId);
        if (profileError) throw profileError;
        const { error: membershipError } = await admin
          .from('organisation_memberships')
          .upsert({
            organisation_id: caller.organisation_id,
            user_id: authUserId,
            is_active: values.is_active,
            updated_at: new Date().toISOString(),
          });
        if (membershipError) throw membershipError;
        const { error: activeOrgError } = await admin
          .from('profiles')
          .update({ active_organisation_id: caller.organisation_id })
          .eq('id', authUserId);
        if (activeOrgError) throw activeOrgError;
        return json({ driver: await driverRow(admin, driverId, caller.organisation_id) }, 201);
      } catch (error) {
        if (authUserId) await admin.auth.admin.deleteUser(authUserId).catch(() => undefined);
        if (driverId) await admin.from('drivers').delete().eq('id', driverId);
        throw error;
      }
    }

    if (operation === 'update') {
      const id = text(body.id);
      if (!id) throw new Error('Driver ID is required.');
      const values = validate(body);
      const before = await driverRow(admin, id, caller.organisation_id);
      if (!before) throw new Error('Driver not found.');
      const profile = await linkedProfile(admin, id, caller.organisation_id);

      const { error: driverError } = await admin
        .from('drivers')
        .update({
          first_name: values.first_name,
          last_name: values.last_name,
          licence_number: values.licence_number,
          licence_expiry: values.licence_expiry,
          phone: values.phone,
          email: values.email,
          username: values.username,
          is_active: values.is_active,
        })
        .eq('id', id)
        .eq('organisation_id', caller.organisation_id);
      if (driverError) throw driverError;

      if (profile) {
        const { error: profileError } = await admin
          .from('profiles')
          .update({
            username: values.username,
            is_active: values.is_active,
            updated_at: new Date().toISOString(),
          })
          .eq('id', profile.id);
        if (profileError) throw profileError;
        const { error: membershipUpdateError } = await admin
          .from('organisation_memberships')
          .update({ is_active: values.is_active, updated_at: new Date().toISOString() })
          .eq('organisation_id', caller.organisation_id)
          .eq('user_id', profile.id);
        if (membershipUpdateError) throw membershipUpdateError;
        const { error: authError } = await admin.auth.admin.updateUserById(profile.id, {
          email: values.email,
          email_confirm: true,
          user_metadata: { username: values.username, organisation_id: caller.organisation_id },
        });
        if (authError) {
          await admin.from('drivers').update(before).eq('id', id);
          await admin.from('profiles').update({
            username: profile.username,
            is_active: profile.is_active,
          }).eq('id', profile.id);
          throw authError;
        }
      }
      return json({ driver: await driverRow(admin, id, caller.organisation_id) });
    }

    if (operation === 'deactivate') {
      const id = text(body.id);
      if (!id) throw new Error('Driver ID is required.');
      const { count, error: assignmentError } = await admin
        .from('driver_assignments')
        .select('id', { count: 'exact', head: true })
        .eq('driver_id', id)
        .eq('organisation_id', caller.organisation_id)
        .eq('is_active', true);
      if (assignmentError) throw assignmentError;
      if ((count ?? 0) > 0) {
        throw new Error('End the current vehicle assignment before deactivating this Driver.');
      }
      const { error } = await admin.from('drivers').update({ is_active: false }).eq('id', id).eq('organisation_id', caller.organisation_id);
      if (error) throw error;
      const profile = await linkedProfile(admin, id, caller.organisation_id);
      if (profile) {
        const { error: profileError } = await admin
          .from('profiles')
          .update({ is_active: false, updated_at: new Date().toISOString() })
          .eq('id', profile.id);
        if (profileError) throw profileError;
        const { error: membershipError } = await admin
          .from('organisation_memberships')
          .update({ is_active: false, updated_at: new Date().toISOString() })
          .eq('organisation_id', caller.organisation_id)
          .eq('user_id', profile.id);
        if (membershipError) throw membershipError;
      }
      return json({ driver: await driverRow(admin, id, caller.organisation_id) });
    }

    if (operation === 'delete') {
      if (caller.role !== 'administrator') {
        throw new Error('Administrator access required to delete a Driver.');
      }
      const id = text(body.id);
      if (!id) throw new Error('Driver ID is required.');
      const current = await driverRow(admin, id, caller.organisation_id);
      if (!current) throw new Error('Driver not found.');

      const { count, error: assignmentError } = await admin
        .from('driver_assignments')
        .select('id', { count: 'exact', head: true })
        .eq('driver_id', id)
        .eq('organisation_id', caller.organisation_id)
        .eq('is_active', true);
      if (assignmentError) throw assignmentError;
      if ((count ?? 0) > 0) {
        throw new Error('End the current vehicle assignment before deleting this Driver.');
      }

      const profile = await linkedProfile(admin, id, caller.organisation_id);
      if (profile) {
        const { error: authDeleteError } = await admin.auth.admin.deleteUser(profile.id);
        if (authDeleteError) throw authDeleteError;
      }

      const { error: deleteMarkError } = await admin
        .from('drivers')
        .update({
          is_active: false,
          deleted_at: new Date().toISOString(),
          deleted_by: caller.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id)
        .eq('organisation_id', caller.organisation_id);
      if (deleteMarkError) throw deleteMarkError;

      return json({ ok: true });
    }

    return json({ error: 'Unsupported Driver management operation.' }, 400);
  } catch (error) {
    console.error(error);
    return json({ error: error instanceof Error ? error.message : 'Unexpected error.' }, 400);
  }
});
