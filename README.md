# Postmark

Stamp the world, one city at a time. A playful travel app: explore a hand-drawn map, stamp the cities you visit, fill your passport and send postcards to friends.

## Status

Phase 1 of the standalone app plan. `index.html` is the working prototype as a single self-contained page, so the site can be published straight away. Later phases split it into a structured project with its own sign-in, database and server-side location checks.

## Live site

Published automatically by Vercel each time `main` changes.

## Running it

Open `index.html` in a browser, or publish the repository as a static site (no build step).

Outside the Claude page it was prototyped on, the app saves to the browser only. Accounts, cross-device sync and real friends return in Phase 3 and Phase 5.

## Plan

1. Setup: repository, hosting, first live page
2. Move the prototype into a structured project
3. Accounts and saving
4. Trusted, server-checked stamps
5. Friends and postcards
6. Polish and beta

## Photos

Travellers can add photos from their device. Postmark reads each photo's saved location and date and files it under the nearest city (within 60 km), falling back to the dates of their trips, or lets them pick a city. Photos are resized (1600 px, plus a 420 px thumbnail) and kept on the device in IndexedDB.

When signed in on the live site, photos also back up to a private Supabase Storage bucket. Run `supabase/photos.sql` once in the Supabase SQL Editor to create the bucket and its access rules. Until then, photos stay on the device and upload automatically once the bucket exists.

Part 2 of the same file (run it after `together.sql`) lets friends on a shared trip see each other's trip photos (any photo can be marked private) and lets postcards carry your own photo on the front. Without it, trips show only your own photos and postcards are sent with the drawn front.

Part 3 lets friends see each other's stamp photos on their friend card and passport page (private photos are never shared).

Every "been there" memory stamp shows the city's chosen stamp photo, and stamp photos appear as pins on the world map when you zoom in.

## App Store and Google Play

See `NATIVE.md`. The native apps are built with Capacitor from the `native/` folder. Run `supabase/account.sql` once so travellers can delete their account in the app, and replace the placeholder contact email in `privacy.html`.
