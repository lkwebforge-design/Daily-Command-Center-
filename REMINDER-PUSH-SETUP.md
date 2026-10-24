# Daily Command Center — iPhone reminder push setup

The reminders UI and database are connected to this app's own Supabase project. The Edge Function `send-reminder-push` is deployed, but push delivery will not run until its server secrets, browser public VAPID key, and scheduler are configured.

## 1. Add Edge Function secrets

Open Supabase Dashboard → Project `yqwdxfkjhvoidtwhntsu` → Edge Functions → Secrets. Add:

- `SUPABASE_SERVICE_ROLE_KEY`: the project's service-role/secret key (server-side only; never put this in the website).
- `CRON_SECRET`: a long random secret used only by the scheduler and Edge Function.
- `VAPID_PUBLIC_KEY`: the public key generated for Web Push.
- `VAPID_PRIVATE_KEY`: the matching private key. Keep it secret.
- `VAPID_SUBJECT`: `mailto:lkwebforge@gmail.com`

Generate a VAPID key pair using a trusted local Node.js environment with `web-push` installed: `npx web-push generate-vapid-keys`. Do not paste the private key into frontend code or commit it to GitHub.

## 2. Add the matching public key to the website

In `index.html`, set `VAPID_PUBLIC_KEY` to the VAPID public key from step 1. This public key is intentionally separate from the private key.

## 3. Schedule the sender

In Supabase SQL Editor, enable the `pg_cron`, `pg_net`, and `vault` extensions if they are not already enabled. Store the same `CRON_SECRET` in Supabase Vault as a secret named `dcc_cron_secret`. Then schedule a minute-by-minute call using the project's Edge Function URL:

```sql
select cron.schedule(
  'dcc-send-reminder-push-every-minute',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://yqwdxfkjhvoidtwhntsu.supabase.co/functions/v1/send-reminder-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'dcc_cron_secret' limit 1)
    ),
    body := '{}'::jsonb
  );
  $$
);
```

If the job already exists, inspect `cron.job` before creating another one. Do not put the cron secret directly in committed SQL or website code.

## 4. Test on iPhone

1. Open the site in Safari: https://lkwebforge-design.github.io/Daily-Command-Center-/
2. Use Share → Add to Home Screen.
3. Open the installed Home Screen app, sign in, open Reminders, and tap **Enable iPhone notifications**.
4. Create a reminder for 2–3 minutes in the future, allow notifications, and keep the device online.
5. Confirm a notification arrives; then test with the app closed.

iOS Web Push requires a Home Screen web app on iOS/iPadOS 16.4 or later. Scheduled notifications are not considered verified until the final test succeeds.
