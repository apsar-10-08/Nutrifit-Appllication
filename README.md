# NutriFit

**Tagline:** Your Health, Your Care  
**Frontend:** Flutter  
**Backend:** Supabase  
**Database:** Supabase PostgreSQL  
**Authentication:** Supabase Auth + Google OAuth  
**Android Min SDK:** 26  
**IDE:** Antigravity IDE

## What is included

This zip contains a complete Flutter project with Android folder, `pubspec.yaml`, full source code, assets, Supabase integration, setup documentation, `.env.example`, and `supabase_schema.sql`.

Features included:

- Splash Screen
- Login
- Sign Up
- Google Login
- Forgot Password
- Email Verification support through Supabase
- Logout
- Goal Selection
- Gender Selection
- Age Input
- Height Input
- Weight Input
- Food Preference
- Workout Location
- Dashboard
- Weekly Workout Split
- Weekly Diet Plan
- Hydration Tracking
- Sleep Tracking
- Walking Step Counter
- AI Trainer
- Calorie Calculator
- Stretching & Warm-up
- Daily Habit Tracker
- Meal Reminder
- Workout Timer
- Rest Timer
- Budget Diet Plan
- Progress Tracking
- Shopping Module
- Wishlist
- Cart
- Profile
- Settings
- English & Tamil language support
- Shopping brands: GNC, MuscleBlaze, YouWeFit

## Run in Antigravity IDE

1. Extract `NutriFit_Flutter_Supabase.zip`.
2. Open the extracted `NutriFit_Flutter_Supabase` folder in Antigravity IDE.
3. Make sure Flutter stable SDK is installed and selected.
4. Run `flutter pub get`.
5. Add your Supabase URL and anon key inside `.env`.
6. Run `flutter run`.

The app has demo mode when `.env` is empty, so the UI can open without Supabase credentials. Real login/database saving needs Supabase setup.

## Android details

- Application ID: `com.nutrifit.app`
- Min SDK: 26
- Deep link scheme: `io.supabase.nutrifit`

## Important files

- `lib/main.dart` - complete app source code
- `supabase_schema.sql` - complete database schema and RLS policies
- `SUPABASE_SETUP.md` - Supabase setup guide
- `GOOGLE_LOGIN_SETUP.md` - Google login setup guide
- `.env.example` - environment variable template
