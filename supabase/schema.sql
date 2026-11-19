-- OUTFITI order storage with administrator-only access.
-- Run this file in the Supabase SQL Editor as the project owner.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id text primary key,
  customer text not null,
  contact text not null default '',
  channel text not null default 'Manual',
  status text not null check (status in ('new','confirmed','preparing','shipped','delivered','cancelled')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  delivered_at timestamptz,
  items jsonb not null check (jsonb_typeof(items) = 'array'),
  total numeric(12,2) not null check (total >= 0),
  gross_profit numeric(12,2) not null
);

create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists orders_status_idx on public.orders (status);

alter table public.admin_users enable row level security;
alter table public.orders enable row level security;

revoke all on table public.admin_users from anon, authenticated;
grant select on table public.admin_users to authenticated;

revoke all on table public.orders from anon, authenticated;
grant select, insert, update, delete on table public.orders to authenticated;

drop policy if exists "Admins can read their own membership" on public.admin_users;
create policy "Admins can read their own membership"
on public.admin_users
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Only OUTFITI admins can manage orders" on public.orders;
create policy "Only OUTFITI admins can manage orders"
on public.orders
for all
to authenticated
using (
  (select auth.uid()) is not null
  and exists (
    select 1
    from public.admin_users as admins
    where admins.user_id = (select auth.uid())
  )
)
with check (
  (select auth.uid()) is not null
  and exists (
    select 1
    from public.admin_users as admins
    where admins.user_id = (select auth.uid())
  )
);

-- Realtime refreshes dashboards after order changes. The app also supports manual refresh.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'orders'
     ) then
    execute 'alter publication supabase_realtime add table public.orders';
  end if;
end $$;

-- After creating an admin account in Supabase Auth, add its user ID to the allowlist.
-- Run a separate seed command from the setup guide using the actual login email.
