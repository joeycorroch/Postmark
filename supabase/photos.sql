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
