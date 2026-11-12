-- Postmark: one saved passport per signed-in traveller.
-- Run this once in the Supabase SQL Editor.

create table if not exists public.passports (
  user_id  uuid primary key references auth.users (id) on delete cascade,
  state    jsonb not null,
  saved_at text  not null,
  dev      text
);

alter table public.passports enable row level security;

-- Each traveller can read and write only their own passport.
create policy "read own passport"   on public.passports for select using (auth.uid() = user_id);
create policy "insert own passport" on public.passports for insert with check (auth.uid() = user_id);
create policy "update own passport" on public.passports for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own passport" on public.passports for delete using (auth.uid() = user_id);
