# FleetIQ manage-drivers — Build 17.4.6.10

This version creates a Driver Auth account by sending a Supabase invitation instead of accepting an administrator-entered password.

Deploy from the FleetIQ project root with PowerShell:

```powershell
npx.cmd supabase functions deploy manage-drivers
```

The invitation redirects to the existing FleetIQ `/set-password` flow. The function uses `FLEETIQ_PASSWORD_REDIRECT_URL` when configured and otherwise defaults to:

`https://fleetiq.unaux.com/app/?route=set-password`

The Supabase service-role key remains server-side inside the Edge Function environment only.
