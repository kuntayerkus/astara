-- Astara v2 — Friend System schema + RLS
-- Apply via Supabase CLI: `supabase db push` or MCP tool.
-- Project: astara-prod (eu-central-1).

-- Extensions
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
-- One row per authenticated iOS user. Mirrors a subset of the local SwiftData
-- `User` model (only fields needed server-side for social features).
-- `handle` is the user-visible @tag for QR payloads and friend search.
create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  apple_user_id text unique,
  email text,
  handle text unique not null check (handle ~ '^[a-z0-9_]{3,20}$'),
  birth_date date,
  birth_time time,
  birth_lat numeric(9,6),
  birth_lng numeric(9,6),
  birth_timezone text,
  locale text not null default 'tr',
  created_at timestamptz not null default now()
);

create index if not exists users_apple_user_id_idx on public.users(apple_user_id);
create index if not exists users_handle_idx on public.users(handle);

-- ---------------------------------------------------------------------------
-- friendships
-- ---------------------------------------------------------------------------
-- Directional: `user_a` is the sender, `user_b` is the target. Status moves
-- pending → accepted → (optionally) blocked. One row per ordered pair.
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.users(id) on delete cascade,
  user_b uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  unique (user_a, user_b),
  check (user_a <> user_b)
);

create index if not exists friendships_user_a_idx on public.friendships(user_a);
create index if not exists friendships_user_b_idx on public.friendships(user_b);

-- ---------------------------------------------------------------------------
-- daily_energy_snapshots
-- ---------------------------------------------------------------------------
-- Per-day per-user snapshot pushed from the iOS app after `loadDailyData`.
-- Friends read each other's rows via RLS policy.
create table if not exists public.daily_energy_snapshots (
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null,
  energy int not null check (energy between 0 and 100),
  theme text,
  lucky_color_hex text,
  updated_at timestamptz not null default now(),
  primary key (user_id, date)
);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.users enable row level security;
alter table public.friendships enable row level security;
alter table public.daily_energy_snapshots enable row level security;

-- users: owner can read/write own row.
drop policy if exists "users_self_read" on public.users;
create policy "users_self_read" on public.users
  for select using (auth.uid() = id);

drop policy if exists "users_self_write" on public.users;
create policy "users_self_write" on public.users
  for insert with check (auth.uid() = id);

drop policy if exists "users_self_update" on public.users;
create policy "users_self_update" on public.users
  for update using (auth.uid() = id);

-- users: accepted friends can see a public subset (handle, birth_date, locale).
-- We expose the full row — app code should only read the needed fields;
-- finer-grained column-level security would require a view, out of scope v2.0.
drop policy if exists "users_friend_read" on public.users;
create policy "users_friend_read" on public.users
  for select using (
    exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
          (f.user_a = auth.uid() and f.user_b = public.users.id)
          or (f.user_b = auth.uid() and f.user_a = public.users.id)
        )
    )
  );

-- friendships: either side can read.
drop policy if exists "friendships_participant_read" on public.friendships;
create policy "friendships_participant_read" on public.friendships
  for select using (auth.uid() = user_a or auth.uid() = user_b);

-- friendships: only sender (user_a) can insert.
drop policy if exists "friendships_sender_insert" on public.friendships;
create policy "friendships_sender_insert" on public.friendships
  for insert with check (auth.uid() = user_a);

-- friendships: either side can update status (accept, block, unblock).
drop policy if exists "friendships_participant_update" on public.friendships;
create policy "friendships_participant_update" on public.friendships
  for update using (auth.uid() = user_a or auth.uid() = user_b);

-- friendships: either side can delete (== unfriend).
drop policy if exists "friendships_participant_delete" on public.friendships;
create policy "friendships_participant_delete" on public.friendships
  for delete using (auth.uid() = user_a or auth.uid() = user_b);

-- daily_energy_snapshots: owner writes.
drop policy if exists "energy_owner_write" on public.daily_energy_snapshots;
create policy "energy_owner_write" on public.daily_energy_snapshots
  for insert with check (auth.uid() = user_id);

drop policy if exists "energy_owner_update" on public.daily_energy_snapshots;
create policy "energy_owner_update" on public.daily_energy_snapshots
  for update using (auth.uid() = user_id);

-- daily_energy_snapshots: owner + accepted friends can read.
drop policy if exists "energy_owner_read" on public.daily_energy_snapshots;
create policy "energy_owner_read" on public.daily_energy_snapshots
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
          (f.user_a = auth.uid() and f.user_b = public.daily_energy_snapshots.user_id)
          or (f.user_b = auth.uid() and f.user_a = public.daily_energy_snapshots.user_id)
        )
    )
  );

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------
-- Enable realtime so the iOS client can subscribe to friends' energy updates
-- without polling. The `supabase_realtime` publication is created by default
-- on managed Supabase projects.
alter publication supabase_realtime add table public.daily_energy_snapshots;
alter publication supabase_realtime add table public.friendships;
