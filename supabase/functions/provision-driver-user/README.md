# provision-driver-user

Authenticated active Administrators may invoke this function with only a
central `driverId` and an invitation `email`. Authorization is derived from
the caller JWT. The service-role credential is supplied by the Supabase Edge
Function runtime and is never accepted in the request.

The function rejects inactive/missing/already-linked Drivers, non-Administrator
callers, self-link attempts, and any existing email unless that Auth identity
already has the exact active Driver linkage. Repeating that exact successful
request returns `idempotent` and does not create another identity or invitation.

For a new email, Supabase Auth sends its normal invitation/password-setup flow.
After the profile trigger creates the safe inactive Driver profile, the function
sets `role=driver`, `is_active=true`, and `driver_id`, then writes the central
security audit event.

If linkage or audit creation fails, the function restores the profile to an
inactive unlinked Driver state where applicable and deletes the newly invited
Auth identity. A cleanup failure returns `provisioning_recovery_required` and
records a safe failure category for trusted operator reconciliation. Retrying
an ambiguous existing-email state is deliberately rejected until that state is
reviewed; it is never silently linked.

Set `FLEETIQ_INVITE_REDIRECT_URL` as an Edge Function secret when a specific
password-setup redirect is required. Never place the service-role key in
Flutter, repository files, or function request data.
