# Postmark on the App Store and Google Play

The app is wrapped with [Capacitor](https://capacitorjs.com), which runs the same web app inside a native iPhone and Android app. Everything native lives in the `native/` folder; the website on Vercel is unchanged.

## What the app already does when it runs natively
- **Location:** “Stamp here” uses the phone’s own location service (Capacitor Geolocation) instead of the browser’s.
- **Haptics:** a firm tap when Pip’s stamp lands.
- **Account deletion:** Passport → Account → “Delete my account” (Apple requires this). Run `supabase/account.sql` once in the Supabase SQL Editor first.
- **Privacy policy:** `privacy.html`, linked from the Account section. Replace the placeholder contact email before submitting.

## One-time setup (on a Mac for iPhone; any computer for Android)
1. Install [Node.js](https://nodejs.org) (LTS), Xcode (Mac App Store) and/or Android Studio.
2. In a terminal:
   ```
   cd native
   npm install
   npm run build:web
   npx cap add ios
   npx cap add android
   ```
3. Change `appId` in `native/capacitor.config.json` to your own reverse-domain ID (for example `com.yourname.postmark`) **before** step 2 if you can. It must match the bundle ID you create in App Store Connect.

## Permissions text (needed or Apple will reject the build)
In Xcode, open `ios/App/App/Info.plist` and add:
| Key | Text |
|---|---|
| `NSLocationWhenInUseUsageDescription` | Postmark checks your location when you tap “Stamp here”, to confirm you’re really in that city. |
| `NSPhotoLibraryUsageDescription` | Choose travel photos to add to your passport. Postmark reads where each was taken to file it under the right city. |
| `NSCameraUsageDescription` | Take a photo to add to your passport. |

For Android, `@capacitor/geolocation` adds the location permissions automatically when you run `npx cap sync`.

## Every time you update the app
```
cd native
npm run ios       # copies the latest web app, syncs, opens Xcode
npm run android   # same for Android Studio
```
In Xcode: choose your team under Signing & Capabilities, pick “Any iOS Device”, then Product → Archive → Distribute App → App Store Connect. Test it with TestFlight before submitting for review.

## Store listing checklist
- App icon 1024×1024 (from `icon-512.png`’s artwork; no transparency for iOS)
- Screenshots: 1290×2796 (iPhone 6.9"/6.7") and 1284×2778 (6.5"); Google Play 1080×1920
- App preview video: 15–30 seconds, 886×1920 portrait
- Privacy policy URL: `https://postmark-lyart.vercel.app/privacy.html`
- Privacy labels: Email (account), Precise location (app functionality, not linked to tracking), Photos (app functionality), User content (postcards)
- Age rating questionnaire, description, keywords and support URL
