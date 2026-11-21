-- Postmark: back up travel photos to your account.
-- Run this once in the Supabase SQL Editor (after schema.sql).
-- Photos are kept in a private bucket, one folder per traveller (named after their user id).
-- Only the owner can read, add, change or delete the files in their own folder.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 5242880, array['image/jpeg'])
on conflict (id) do nothing;

drop policy if exists "photos: read own" on storage.objects;
create policy "photos: read own" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "photos: add own" on storage.objects;
create policy "photos: add own" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "photos: change own" on storage.objects;
create policy "photos: change own" on storage.objects for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "photos: delete own" on storage.objects;
create policy "photos: delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- Part 2 (run after together.sql): share photos with friends on trips you plan together,
-- and put your own photo on the front of a postcard.

-- Which of your photos you share with a trip. The app adds and removes rows for you:
-- photos taken in the trip's cities during its dates, unless you mark a photo private.
create table if not exists public.trip_photos (
  trip_id    uuid not null references public.shared_trips (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  photo_id   text not null check (photo_id ~ '^[a-z0-9]{6,32}$'),
  city       text not null,
  taken      text,
  created_at timestamptz default now(),
  primary key (trip_id, user_id, photo_id)
);
alter table public.trip_photos enable row level security;

drop policy if exists "people on the trip see its photos" on public.trip_photos;
create policy "people on the trip see its photos" on public.trip_photos for select
  using (public.trip_status(trip_id) in ('owner', 'joined'));
drop policy if exists "share your own photos with your trips" on public.trip_photos;
create policy "share your own photos with your trips" on public.trip_photos for insert
  with check (user_id = auth.uid() and public.trip_status(trip_id) in ('owner', 'joined'));
drop policy if exists "unshare your own photos" on public.trip_photos;
create policy "unshare your own photos" on public.trip_photos for delete using (user_id = auth.uid());

-- Can the person asking open this photo file because it is shared with a trip they are on?
create or replace function public.trip_photo_visible(object_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from trip_photos tp
    where tp.user_id::text = split_part(object_name, '/', 1)
      and object_name in (tp.user_id::text || '/' || tp.photo_id || '.jpg', tp.user_id::text || '/' || tp.photo_id || '_t.jpg')
      and public.trip_status(tp.trip_id) in ('owner', 'joined')
  )
$$;
revoke all on function public.trip_photo_visible(text) from public, anon;
grant execute on function public.trip_photo_visible(text) to authenticated;

drop policy if exists "photos: friends on the trip" on storage.objects;
create policy "photos: friends on the trip" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and public.trip_photo_visible(name));

-- Postcard photos: the sender uploads a copy to <sender>/pc/<recipient>/<photo>.jpg, which only the recipient can open.
alter table public.postcards add column if not exists photo text;
drop policy if exists "photos: postcards sent to you" on storage.objects;
create policy "photos: postcards sent to you" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[2] = 'pc' and (storage.foldername(name))[3] = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- Part 3 (run after together.sql): friends see each other's stamp photos.
-- Each traveller's card lists the stamp photo of every city they've stamped (private photos are left out).
alter table public.profiles add column if not exists covers jsonb;

-- Two people are friends when either has added the other.
create or replace function public.are_friends(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from friend_links where (from_user = a and to_user = b) or (from_user = b and to_user = a))
$$;
revoke all on function public.are_friends(uuid, uuid) from public, anon;
grant execute on function public.are_friends(uuid, uuid) to authenticated;

-- Stamp photo lists, only for people you're friends with.
create or replace function public.friend_covers(p_ids uuid[])
returns table (user_id uuid, covers jsonb)
language sql stable security definer set search_path = public as $$
  select p.user_id, p.covers from profiles p
  where p.user_id = any (p_ids) and p.covers is not null and public.are_friends(auth.uid(), p.user_id)
  limit 200
$$;
revoke all on function public.friend_covers(uuid[]) from public, anon;
grant execute on function public.friend_covers(uuid[]) to authenticated;

-- A friend can open a photo file only while it is one of your listed stamp photos.
create or replace function public.friend_cover_visible(object_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles p, jsonb_each_text(coalesce(p.covers, '{}'::jsonb)) c
    where p.user_id::text = split_part(object_name, '/', 1)
      and object_name in (p.user_id::text || '/' || c.value || '.jpg', p.user_id::text || '/' || c.value || '_t.jpg')
      and public.are_friends(auth.uid(), p.user_id)
  )
$$;
revoke all on function public.friend_cover_visible(text) from public, anon;
grant execute on function public.friend_cover_visible(text) to authenticated;

drop policy if exists "photos: friends' stamp photos" on storage.objects;
create policy "photos: friends' stamp photos" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and public.friend_cover_visible(name));
