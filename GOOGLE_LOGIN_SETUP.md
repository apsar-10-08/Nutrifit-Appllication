# Google Login Setup for NutriFit

NutriFit uses Supabase OAuth for Google Login.

## 1. Google Cloud Console

1. Open Google Cloud Console.
2. Create or select a project.
3. Configure OAuth consent screen.
4. Create OAuth credentials.

Android package name:

```text
com.nutrifit.app
```

Add debug/release SHA-1 fingerprints as required by Google.

## 2. Supabase Provider

1. Open Supabase Dashboard.
2. Go to Authentication > Providers > Google.
3. Enable Google.
4. Paste Google Client ID and Client Secret.
5. Save.

## 3. Redirect URLs

Add these in Supabase Authentication > URL Configuration:

```text
io.supabase.nutrifit://login-callback/
io.supabase.nutrifit://reset-callback/
```

AndroidManifest.xml already contains the `io.supabase.nutrifit` deep-link scheme.
