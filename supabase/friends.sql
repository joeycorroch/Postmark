-- Postmark friends: public cards, friend codes and private postcards.
-- Run this once in the Supabase SQL Editor (after schema.sql).

-- 1. Each traveller's card: what friends see.
create table if not exists public.profiles (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  code       text not null,
  given      text,
  home       text,
  av         jsonb,
  cities     jsonb,
  updated_at timestamptz default now()
);
create index if not exists profiles_code_idx on public.profiles (code);
alter table public.profiles enable row level security;

-- You can read and write only your own card directly.
create policy "read own profile"   on public.profiles for select using (auth.uid() = user_id);
create policy "insert own profile" on public.profiles for insert with check (auth.uid() = user_id);
create policy "update own profile" on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Other people's cards are reached only through these two functions:
-- by friend code, or by ids you already hold (your friends).
create or replace function public.profile_by_code(p_code text)
returns table (user_id uuid, code text, given text, home text, av jsonb, cities jsonb)
language sql stable security definer set search_path = public as $$
  select p.user_id, p.code, p.given, p.home, p.av, p.cities
  from public.profiles p where p.code = upper(p_code) limit 1
$$;

create or replace function public.profiles_by_ids(p_ids uuid[])
returns table (user_id uuid, code text, given text, home text, av jsonb, cities jsonb)
language sql stable security definer set search_path = public as $$
  select p.user_id, p.code, p.given, p.home, p.av, p.cities
  from public.profiles p where p.user_id = any (p_ids) limit 200
$$;

revoke all on function public.profile_by_code(text) from public, anon;
revoke all on function public.profiles_by_ids(uuid[]) from public, anon;
grant execute on function public.profile_by_code(text) to authenticated;
grant execute on function public.profiles_by_ids(uuid[]) to authenticated;

-- 2. Postcards between travellers. Only the recipient can read or remove one.
create table if not exists public.postcards (
  id         bigint generated always as identity primary key,
  to_user    uuid not null references auth.users (id) on delete cascade,
  from_user  uuid not null references auth.users (id) on delete cascade,
  city       text not null,
  msg        text check (char_length(msg) <= 140),
  sent_on    text,
  env        text,
  created_at timestamptz default now()
);
create index if not exists postcards_to_idx on public.postcards (to_user);
alter table public.postcards enable row level security;

create policy "send a postcard as yourself" on public.postcards for insert with check (auth.uid() = from_user);
create policy "read postcards sent to you"  on public.postcards for select using (auth.uid() = to_user);
create policy "clear postcards sent to you" on public.postcards for delete using (auth.uid() = to_user);
