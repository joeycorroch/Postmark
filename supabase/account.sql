-- Postmark: let travellers delete their own account from inside the app (required by the App Store).
-- Run this once in the Supabase SQL Editor. The app removes the person's photo files first,
-- then calls this function, which deletes everything else and finally the sign-in itself.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
declare me uuid := auth.uid();
begin
  if me is null then raise exception 'not signed in'; end if;
  if to_regclass('public.trip_photos')  is not null then execute 'delete from public.trip_photos where user_id = $1' using me; end if;
  if to_regclass('public.trip_members') is not null then execute 'delete from public.trip_members where user_id = $1' using me; end if;
  if to_regclass('public.shared_trips') is not null then execute 'delete from public.shared_trips where owner = $1' using me; end if;
  if to_regclass('public.friend_links') is not null then execute 'delete from public.friend_links where from_user = $1 or to_user = $1' using me; end if;
  if to_regclass('public.postcards')    is not null then execute 'delete from public.postcards where from_user = $1 or to_user = $1' using me; end if;
  if to_regclass('public.profiles')     is not null then execute 'delete from public.profiles where user_id = $1' using me; end if;
  if to_regclass('public.passports')    is not null then execute 'delete from public.passports where user_id = $1' using me; end if;
  delete from auth.users where id = me;
end
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
