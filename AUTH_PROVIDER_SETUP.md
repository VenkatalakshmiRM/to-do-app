# OAuth provider setup

The app uses Supabase browser OAuth for Google and Apple. No provider IDs,
secrets, signing keys, or generated credential files are committed here.

The mobile callback URL is:

`com.venkatalakshmi.campustodo://auth-callback`

Add that exact URL to **Supabase Dashboard → Authentication → URL
Configuration → Redirect URLs**. The same value is recorded for local Supabase
CLI development in `supabase/config.toml`.

## Google

1. In Google Cloud Console, create/configure an OAuth consent screen and OAuth
   client for the Supabase project.
2. Add the Supabase callback URL shown by **Supabase Dashboard →
   Authentication → Providers → Google** to the Google OAuth client's
   authorized redirect URIs. This is the hosted Supabase callback, not the
   custom mobile URL above.
3. Enter the Google client ID and secret in the Supabase Google provider page.
4. Keep `google-services.json` out of source control. The current implementation
   uses browser OAuth and does not require Firebase's native Google Sign-In SDK.
   If native Google/Firebase services are added later, download the real file
   from the matching Firebase project, place it at
   `android/app/google-services.json`, and apply Google's Gradle plugin per the
   generated Firebase instructions. Never create a placeholder file.

## Apple

1. In Apple Developer, enable **Sign in with Apple** for the app's real App ID.
2. In Xcode, open `ios/Runner.xcworkspace`, select the Runner target, and add
   **Signing & Capabilities → Sign in with Apple**. Xcode will create/update the
   entitlement using the selected development team; no fake entitlement is
   committed here.
3. Create the required Services ID and Sign in with Apple key in Apple
   Developer. Configure its domain and return URL using the values shown by the
   Supabase Apple provider page.
4. Add the Services ID, Team ID, Key ID, and generated Apple secret to
   **Supabase Dashboard → Authentication → Providers → Apple**.
5. Keep the `.p8` private key and generated client secret outside the repository.

After either provider redirects to the mobile callback, `app_links` and
Supabase restore the session. `authSessionProvider` then switches the root from
Login to the existing app shell.
