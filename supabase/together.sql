-- Postmark: mutual friends and trips planned together.
-- Run this once in the Supabase SQL Editor (after schema.sql and friends.sql).

-- 1. Adding someone's code tells them, and they add you back automatically.
create table if not exists public.friend_links (
  id         bigint generated always as identity primary key,
  from_user  uuid not null references auth.users (id) on delete cascade,
  to_user    uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz default now(),
  unique (from_user, to_user)
);
alter table public.friend_links enable row level security;
create policy "add a friend as yourself" on public.friend_links for insert with check (auth.uid() = from_user);
create policy "see your friend links"    on public.friend_links for select using (auth.uid() = to_user or auth.uid() = from_user);
create policy "clear links sent to you"  on public.friend_links for delete using (auth.uid() = to_user);

-- 2. Shared trips and who is on them.
create table if not exists public.shared_trips (
  id         uuid primary key,
  owner      uuid not null references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz default now(),
  updated_by uuid
);
create table if not exists public.trip_members (
  trip_id    uuid not null references public.shared_trips (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  status     text not null default 'invited' check (status in ('invited', 'joined')),
  invited_by uuid,
  created_at timestamptz default now(),
  primary key (trip_id, user_id)
);
create index if not exists trip_members_user_idx on public.trip_members (user_id);
alter table public.shared_trips enable row level security;
alter table public.trip_members enable row level security;

-- Your relationship to a trip: 'owner', 'joined', 'invited' or nothing.
create or replace function public.trip_status(t uuid)
returns text language sql stable security definer set search_path = public as $$
  select case
    when exists (select 1 from shared_trips s where s.id = t and s.owner = auth.uid()) then 'owner'
    else (select m.status from trip_members m where m.trip_id = t and m.user_id = auth.uid())
  end
$$;
revoke all on function public.trip_status(uuid) from public, anon;
grant execute on function public.trip_status(uuid) to authenticated;

create policy "create your own trip"         on public.shared_trips for insert with check (auth.uid() = owner);
create policy "people on the trip can see it" on public.shared_trips for select using (auth.uid() = owner or public.trip_status(id) is not null);
create policy "people on the trip can edit"   on public.shared_trips for update using (public.trip_status(id) in ('owner', 'joined')) with check (public.trip_status(id) in ('owner', 'joined'));
create policy "the planner can delete it"     on public.shared_trips for delete using (auth.uid() = owner);

create policy "see who is on your trips" on public.trip_members for select using (user_id = auth.uid() or public.trip_status(trip_id) in ('owner', 'joined'));
create policy "invite people to a trip"  on public.trip_members for insert with check (public.trip_status(trip_id) in ('owner', 'joined') and (status = 'invited' or user_id = auth.uid()));
create policy "accept your own invite"   on public.trip_members for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "decline, leave or remove" on public.trip_members for delete using (user_id = auth.uid() or public.trip_status(trip_id) = 'owner');

-- Only these columns can ever be changed after a row is created.
revoke update on public.shared_trips from authenticated, anon;
grant update (data, updated_at, updated_by) on public.shared_trips to authenticated;
revoke update on public.trip_members from authenticated, anon;
grant update (status) on public.trip_members to authenticated;
