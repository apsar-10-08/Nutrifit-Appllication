create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  gender text check (gender in ('Male','Female','Other','')) default '',
  age int check (age is null or age between 5 and 100),
  height_cm numeric(5,2) check (height_cm is null or height_cm between 50 and 260),
  weight_kg numeric(5,2) check (weight_kg is null or weight_kg between 15 and 300),
  food_preference text check (food_preference in ('Vegetarian','Non-Vegetarian','Eggetarian','')) default '',
  workout_location text check (workout_location in ('Gym Workout','Home Workout','')) default '',
  preferred_language text check (preferred_language in ('en','ta')) default 'en',
  reminders_json jsonb,
  ai_history_json jsonb,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  goal text not null check (goal in ('Weight Loss','Weight Gain','Increase Height','Calisthenics','Maintain Weight','Improve Stamina','General Fitness')),
  target_weight_kg numeric(5,2),
  target_height_cm numeric(5,2),
  start_date date not null default current_date,
  target_date date,
  status text not null default 'active' check (status in ('active','completed','paused')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists trg_goals_updated_at on public.goals;
create trigger trg_goals_updated_at before update on public.goals for each row execute function public.set_updated_at();

create table if not exists public.diet_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  goal_id uuid references public.goals(id) on delete cascade,
  title text not null,
  food_preference text not null,
  total_calories int,
  total_protein_g numeric(6,2),
  budget_level text default 'standard' check (budget_level in ('budget','standard','premium')),
  is_template boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists trg_diet_plans_updated_at on public.diet_plans;
create trigger trg_diet_plans_updated_at before update on public.diet_plans for each row execute function public.set_updated_at();

create table if not exists public.diet_items (
  id uuid primary key default gen_random_uuid(),
  diet_plan_id uuid not null references public.diet_plans(id) on delete cascade,
  day_of_week int not null check (day_of_week between 1 and 7),
  meal_time text not null check (meal_time in ('Breakfast','Snack','Lunch','Pre Workout','Post Workout','Dinner')),
  food_name text not null,
  quantity text,
  calories int,
  protein_g numeric(6,2),
  created_at timestamptz not null default now()
);

create table if not exists public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  goal_id uuid references public.goals(id) on delete cascade,
  title text not null,
  workout_location text not null,
  difficulty text default 'beginner' check (difficulty in ('beginner','intermediate','advanced')),
  is_template boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists trg_workout_plans_updated_at on public.workout_plans;
create trigger trg_workout_plans_updated_at before update on public.workout_plans for each row execute function public.set_updated_at();

create table if not exists public.workout_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  day_of_week int not null check (day_of_week between 1 and 7),
  exercise_name text not null,
  sets int,
  reps text,
  duration_minutes int,
  rest_seconds int default 60,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.progress_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  log_date date not null default current_date,
  weight_kg numeric(5,2),
  height_cm numeric(5,2),
  body_fat_percent numeric(5,2),
  steps int default 0,
  calories_burned int default 0,
  workout_minutes int default 0,
  notes text,
  created_at timestamptz not null default now(),
  unique(user_id, log_date)
);

create table if not exists public.hydration_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  log_date date not null default current_date,
  water_ml int not null default 0,
  target_ml int not null default 3000,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, log_date)
);

create table if not exists public.sleep_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  log_date date not null default current_date,
  sleep_hours numeric(4,2) not null default 0,
  sleep_quality text default 'Good' check (sleep_quality in ('Poor','Average','Good','Excellent')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, log_date)
);

create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  habit_name text not null,
  log_date date not null default current_date,
  is_done boolean not null default false,
  created_at timestamptz not null default now(),
  unique(user_id, habit_name, log_date)
);

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  reminder_type text not null check (reminder_type in ('meal','workout','water','sleep','habit')),
  reminder_time time not null,
  repeat_days text[] default array['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  brand text not null check (brand in ('GNC','MuscleBlaze','YouWeFit')),
  name text not null,
  category text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  image_url text,
  stock int not null default 0,
  rating numeric(3,2) default 4.5,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, product_id)
);

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity int not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, product_id)
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  full_name text not null,
  mobile text not null,
  house_no text not null,
  street text not null,
  landmark text,
  city text not null,
  district text not null,
  state text not null,
  pincode text not null,
  instructions text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  total_amount numeric(10,2) not null default 0,
  status text not null default 'pending' check (status in ('pending','paid','cancelled','delivered')),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  quantity int not null check (quantity > 0),
  price numeric(10,2) not null,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.goals enable row level security;
alter table public.diet_plans enable row level security;
alter table public.diet_items enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.progress_logs enable row level security;
alter table public.hydration_logs enable row level security;
alter table public.sleep_logs enable row level security;
alter table public.habit_logs enable row level security;
alter table public.reminders enable row level security;
alter table public.products enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.cart_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "goals_all_own" on public.goals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "diet_plans_select" on public.diet_plans for select using (is_template = true or auth.uid() = user_id);
create policy "diet_plans_modify_own" on public.diet_plans for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "diet_items_select" on public.diet_items for select using (exists (select 1 from public.diet_plans d where d.id = diet_plan_id and (d.is_template = true or d.user_id = auth.uid())));
create policy "workout_plans_select" on public.workout_plans for select using (is_template = true or auth.uid() = user_id);
create policy "workout_plans_modify_own" on public.workout_plans for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "workout_exercises_select" on public.workout_exercises for select using (exists (select 1 from public.workout_plans w where w.id = workout_plan_id and (w.is_template = true or w.user_id = auth.uid())));
create policy "progress_all_own" on public.progress_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "hydration_all_own" on public.hydration_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "sleep_all_own" on public.sleep_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "habit_all_own" on public.habit_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "reminders_all_own" on public.reminders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "products_public_select" on public.products for select using (is_active = true);
create policy "wishlist_all_own" on public.wishlist_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "cart_select_own" on public.cart_items for select using (auth.uid() = user_id);
create policy "cart_insert_own" on public.cart_items for insert with check (auth.uid() = user_id);
create policy "cart_update_own" on public.cart_items for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "cart_delete_own" on public.cart_items for delete using (auth.uid() = user_id);
create policy "orders_all_own" on public.orders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "order_items_select_own" on public.order_items for select using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));

insert into public.products (brand, name, category, description, price, image_url, stock, rating) values
('GNC', 'GNC Whey Protein Starter', 'Protein', 'Protein support for muscle recovery and daily fitness.', 2499, 'assets/images/product_gnc.png', 25, 4.6),
('GNC', 'GNC Multivitamin Active', 'Wellness', 'Daily wellness support for active lifestyle.', 1299, 'assets/images/product_gnc.png', 40, 4.5),
('MuscleBlaze', 'MuscleBlaze Biozyme Whey', 'Protein', 'Recovery protein for strength and weight gain.', 2199, 'assets/images/product_mb.png', 35, 4.7),
('MuscleBlaze', 'MuscleBlaze Creatine', 'Performance', 'Performance support for intense workouts.', 899, 'assets/images/product_mb.png', 50, 4.4),
('YouWeFit', 'YouWeFit Resistance Band', 'Equipment', 'Home workout band for strength and calisthenics.', 499, 'assets/images/product_ywf.png', 75, 4.3),
('YouWeFit', 'YouWeFit Shaker Bottle', 'Accessories', 'Fitness shaker for protein and water.', 299, 'assets/images/product_ywf.png', 100, 4.2)
on conflict do nothing;
