# Email sign-in (passwordless links)

9 October 2026. The app side is built: "Continue with email" in onboarding's
sign-in scene, the "I already have an account" sheet and Profile. It's
hidden until the steps below are done and the app is built with
`--dart-define=TRAVARY_EMAIL_LINKS=true`.

**No domain needs buying.** Since Dynamic Links shut down (25 August 2025),
Firebase builds email links on the project's own Hosting domain,
`travary-444.firebaseapp.com`, the same host Apple sign-in already returns
to. Firebase serves the iOS association file there itself. A custom domain
(e.g. `travary.app`) is optional, for nicer-looking links. If you add one,
connect it in Firebase Hosting and build with
`--dart-define=TRAVARY_EMAIL_LINK_DOMAIN=travary.app` as well.

## How it works

1. The traveller types an address; `FirebaseAuthService.sendSignInLink`
   asks Firebase to email a link, and keeps the address on this phone only
   (`Application Support/auth/pending_email.txt`) until the link is used.
   The screen says the link was sent, never that they're signed in.
2. Tapping the link in Mail opens Travary (Universal Link / App Link).
   `AppSession` hears it through `app_links` and calls `signInWithLink`:
   the guest is **linked** to that address (same account, same trips), or,
   if the address already has a Travary account (another phone), the app
   switches to it and `adoptGuestTrips` brings the guest's trips across,
   as for Apple and Google. Onboarding then goes on to the same holiday's
   pass desk.
3. An expired, reused, or other-phone link says so and offers "Send it
   again"; "Use a different email" and "Continue as a guest" stay available.

## To switch it on

1. **Firebase console** (dreamprayer.dev login) → Authentication → Sign-in
   method → **Email/Password** → enable, and enable **Email link
   (passwordless sign-in)**. Optionally, under Templates, set the sender
   name ("Travary") and the email's wording.
2. **Firebase console** → Project settings → the iOS app `com.travary.app`
   → make sure the **Team ID** is filled in (Firebase uses it for the
   association file).
3. **Apple Developer** → Identifiers → `com.travary.app` → enable
   **Associated Domains**, then regenerate the provisioning profiles (or let
   Xcode's automatic signing do it).
4. **iOS app** (Claude can do this): add to `ios/Runner/Runner.entitlements`
   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
     <string>applinks:travary-444.firebaseapp.com</string>
   </array>
   ```
5. **Android app** (Claude can do this): in `MainActivity`'s entry in
   `android/app/src/main/AndroidManifest.xml`
   ```xml
   <intent-filter android:autoVerify="true">
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="https" android:host="travary-444.firebaseapp.com"
           android:pathPrefix="/__/auth/links" />
   </intent-filter>
   ```
   The app's SHA-256 fingerprints (debug, upload, Play App Signing) are
   already registered in Firebase for Google sign-in, which App Links need.
6. Build with `--dart-define=TRAVARY_EMAIL_LINKS=true` (add it to the
   release build command too).

## Checks on a device

Universal Links only open apps on a real device after a fresh install (iOS
caches the association file), so test there:

- Send a link, open it from Mail on the same phone: the app opens and says
  "Signed in". Onboarding continues to the pass desk.
- The same with an address that already has a Travary account: the app
  switches to it and opens the same holiday's desk.
- Open an old link: "That sign-in link has expired or was already used."
- Kill the app after sending; open the link: it starts, then signs in.
- If links open Safari instead of the app, check
  `https://travary-444.firebaseapp.com/.well-known/apple-app-site-association`
  lists `<TeamID>.com.travary.app`.

Not yet verified live: whether a link whose address already has an account
can still be used after the first link attempt fails (Firebase's one-time
codes). The code retries with `signInWithEmailLink`; check it in step 2
above before release.

Sources: [Firebase email link sign-in (iOS)](https://firebase.google.com/docs/auth/ios/email-link-auth),
[(Android)](https://firebase.google.com/docs/auth/android/email-link-auth),
[migrating off Dynamic Links](https://firebase.google.com/docs/auth/ios/email-link-migration).
