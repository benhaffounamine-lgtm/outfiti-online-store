# OUTFITI Database Sync

The static GitHub Pages admin connects to Supabase for shared order storage. The browser uses the Supabase anon/publishable key and Supabase Auth; database Row Level Security restricts order access to user IDs explicitly added to public.admin_users.

## One-time Supabase setup

1. Create a Supabase project.
2. In Supabase SQL Editor, run schema.sql.
3. In Authentication → Users, create or invite each admin account. Public sign-up is not used by the OUTFITI dashboard.
4. For each authorized admin, copy this SQL into SQL Editor, replace the email, and run it:

   ~~~sql
   insert into public.admin_users (user_id)
   select id from auth.users where email = 'ADMIN_EMAIL_HERE'
   on conflict (user_id) do nothing;
   ~~~

5. From Supabase Project Settings → API, copy the Project URL and anon/publishable key. Never use a service_role key in the browser or commit it to GitHub.

## Connect the dashboard

1. Open admin.html on the deployed storefront and choose “Database: Local only”.
2. Enter the Project URL, anon/publishable key, and an authorized admin email/password.
3. Select “Sign in & sync”. Existing browser-local orders are uploaded when their IDs are not already in the database.
4. To connect another device or browser, repeat the connection step there. Orders then sync through the same database; the browser still keeps a local cache and retries queued changes on sync.

The Project URL and anon/publishable key are saved in that browser's local storage. Passwords are not stored. Admin access is enforced by database policies, not by hiding the dashboard page.

## Profit and data notes

- Sales and gross-profit cards include delivered orders only. Gross profit is the recorded unit sale price minus unit cost, multiplied by quantity. It does not subtract delivery, payment, tax, or other overhead.
- The CMS cost field provides the default unit cost when present. For older products without a cost value, enter each line's unit cost when recording a sale.
- The order table stores customer contact details and line-item snapshots. Keep Supabase access limited to trusted admins.
- JSON backup controls remain available for recovery or transferring browser-local orders.
- Product catalog data continues to load from content/products.json; this database sync is for orders only.
