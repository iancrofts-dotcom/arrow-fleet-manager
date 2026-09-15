# FleetIQ manage-users Edge Function

Deploy this function after applying the FleetIQ migrations:

```bash
supabase functions deploy manage-users
```

Supabase automatically supplies `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
`SUPABASE_SERVICE_ROLE_KEY` to hosted Edge Functions. The service-role key is
never embedded in the Flutter application.

The function authenticates the caller and independently verifies an active
`administrator` profile before any list/create/update/delete operation.
