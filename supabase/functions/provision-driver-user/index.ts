import { createClient, type User } from 'npm:@supabase/supabase-js@2';

const jsonHeaders = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
};

type RequestBody = {
  driverId?: unknown;
  email?: unknown;
};

function response(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function normalizeEmail(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const email = value.trim().toLowerCase();
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return null;
  }
  return email;
}

async function findUserByEmail(
  admin: ReturnType<typeof createClient>,
  email: string,
): Promise<User | null> {
  for (let page = 1; page <= 100; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw new Error('identity_lookup_failed');
    const match = data.users.find((user) => user.email?.toLowerCase() === email);
    if (match) return match;
    if (data.users.length < 1000) return null;
  }
  throw new Error('identity_lookup_ambiguous');
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: jsonHeaders });
  }
  if (request.method !== 'POST') {
    return response(405, { ok: false, reason: 'method_not_allowed' });
  }

  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return response(401, { ok: false, reason: 'authentication_required' });
  }

  const url = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !anonKey || !serviceRoleKey) {
    return response(500, { ok: false, reason: 'server_configuration_error' });
  }

  const callerClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const admin = createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: callerData, error: callerError } = await callerClient.auth.getUser();
  if (callerError || !callerData.user) {
    return response(401, { ok: false, reason: 'authentication_failed' });
  }
  const actorId = callerData.user.id;

  const { data: actorProfile } = await admin
    .from('profiles')
    .select('role, is_active')
    .eq('id', actorId)
    .maybeSingle();
  if (actorProfile?.role !== 'administrator' || actorProfile.is_active !== true) {
    return response(403, { ok: false, reason: 'not_authorized' });
  }

  let body: RequestBody;
  try {
    body = await request.json() as RequestBody;
  } catch {
    return response(400, { ok: false, reason: 'invalid_request' });
  }
  const driverId = typeof body.driverId === 'string' ? body.driverId.toLowerCase() : '';
  const email = normalizeEmail(body.email);
  if (!isUuid(driverId) || email === null) {
    return response(400, { ok: false, reason: 'invalid_request' });
  }

  const { data: driver } = await admin
    .from('drivers')
    .select('id, username, is_active')
    .eq('id', driverId)
    .maybeSingle();
  if (!driver || driver.is_active !== true) {
    return response(409, { ok: false, reason: 'driver_unavailable' });
  }
  const { data: linkedProfile } = await admin
    .from('profiles')
    .select('id')
    .eq('driver_id', driverId)
    .maybeSingle();

  let existingUser: User | null;
  try {
    existingUser = await findUserByEmail(admin, email);
  } catch {
    return response(500, { ok: false, reason: 'identity_lookup_failed' });
  }

  if (existingUser) {
    if (existingUser.id === actorId) {
      return response(409, { ok: false, reason: 'self_link_denied' });
    }
    const { data: existingProfile } = await admin
      .from('profiles')
      .select('role, is_active, driver_id')
      .eq('id', existingUser.id)
      .maybeSingle();
    if (
      linkedProfile?.id === existingUser.id &&
      existingProfile?.driver_id === driverId &&
      existingProfile.role === 'driver' &&
      existingProfile.is_active === true
    ) {
      return response(200, {
        ok: true,
        status: 'idempotent',
        driverId,
        userId: existingUser.id,
      });
    }
    return response(409, { ok: false, reason: 'email_or_driver_already_linked' });
  }
  if (linkedProfile) {
    return response(409, { ok: false, reason: 'driver_already_linked' });
  }

  const redirectTo = Deno.env.get('FLEETIQ_INVITE_REDIRECT_URL');
  const { data: inviteData, error: inviteError } = await admin.auth.admin.inviteUserByEmail(
    email,
    {
      data: { username: driver.username ?? email },
      ...(redirectTo ? { redirectTo } : {}),
    },
  );
  if (inviteError || !inviteData.user) {
    return response(409, { ok: false, reason: 'invitation_failed' });
  }

  const invitedUserId = inviteData.user.id;
  const { data: finalizedProfile, error: finalizeError } = await admin
    .from('profiles')
    .update({
      role: 'driver',
      is_active: true,
      driver_id: driverId,
      updated_at: new Date().toISOString(),
    })
    .eq('id', invitedUserId)
    .is('driver_id', null)
    .select('id, driver_id')
    .maybeSingle();

  let failureCategory: string | null = null;
  if (finalizeError || finalizedProfile?.driver_id !== driverId) {
    failureCategory = 'link_failed';
  } else {
    const { error: auditError } = await admin.from('security_audit_events').insert({
      actor_profile_id: actorId,
      action: 'driver_user_provisioned',
      target_driver_id: driverId,
      target_profile_id: invitedUserId,
      outcome: 'success',
    });
    if (auditError) failureCategory = 'audit_failed';
  }

  if (failureCategory !== null) {
    if (finalizedProfile?.driver_id === driverId) {
      await admin
        .from('profiles')
        .update({ role: 'driver', is_active: false, driver_id: null })
        .eq('id', invitedUserId)
        .eq('driver_id', driverId);
    }
    const { error: cleanupError } = await admin.auth.admin.deleteUser(invitedUserId);
    await admin.from('security_audit_events').insert({
      actor_profile_id: actorId,
      action: 'driver_user_provisioned',
      target_driver_id: driverId,
      target_profile_id: invitedUserId,
      outcome: 'failed',
      failure_category: cleanupError
        ? `${failureCategory}_cleanup_required`
        : `${failureCategory}_compensated`,
    });
    return response(500, {
      ok: false,
      reason: cleanupError ? 'provisioning_recovery_required' : 'provisioning_failed',
    });
  }

  return response(201, {
    ok: true,
    status: 'success',
    driverId,
    userId: invitedUserId,
  });
});
