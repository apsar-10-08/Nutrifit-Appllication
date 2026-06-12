# Supabase Setup for NutriFit

## 1. Create a Supabase project

Create a Supabase project and copy:

- Project URL
- anon public key

## 2. Configure environment

Open `.env` and fill:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-public-key
SUPABASE_REDIRECT_URL=io.supabase.nutrifit://login-callback/
APP_ENV=development
```

## 3. Create tables

Open Supabase SQL Editor, paste the full contents of `supabase_schema.sql`, and run it.

The schema creates:

- profiles
- goals
- diet_plans
- diet_items
- workout_plans
- workout_exercises
- progress_logs
- hydration_logs
- sleep_logs
- habit_logs
- reminders
- products
- wishlist_items
- cart_items
- orders
- order_items

It also enables Row Level Security and adds policies so users can only access their own data.

## 4. Enable email auth

Go to Authentication > Providers > Email and enable Email provider. Enable email confirmation if you want email verification.

## 5. Redirect URLs

Add these in Authentication > URL Configuration:

```text
io.supabase.nutrifit://login-callback/
io.supabase.nutrifit://reset-callback/
```

## 6. Product seed data

The SQL file inserts sample products for GNC, MuscleBlaze, and YouWeFit.
