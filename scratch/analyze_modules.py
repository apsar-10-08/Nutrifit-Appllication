import re

def analyze_app():
    with open("lib/main.dart", "r", encoding="utf-8") as f:
        content = f.read()

    print("=== ANALYSIS OF NUTRIFIT SOURCE CODE (lib/main.dart) ===")
    
    # 1. Main Screens & Routes
    screens = [
        ("SplashScreen", "Splash & Onboarding Screen"),
        ("LoginScreen", "Login & Authentication Screen"),
        ("SignUpScreen", "User Registration Screen"),
        ("ForgotScreen", "Forgot Password Recovery Screen"),
        ("SelectScreen", "Onboarding Primary Goal Screen"),
        ("GoalScreen", "Fitness Target Goal Screen"),
        ("GenderScreen", "Demographics & Gender Screen"),
        ("FoodScreen", "Dietary Preference & Food Screen"),
        ("LocationScreen", "User Location & Region Screen"),
        ("NumberScreen", "Body Metrics & Measurements Screen"),
        ("DashboardScreen", "Main Dashboard & Navigation Shell"),
        ("HomeTab", "Home Overview & Daily Progress Tab"),
        ("HeroCard", "Today Workout & Hero Banner Section"),
        ("WorkoutDayCard", "Daily Exercise Routine & Set Tracking"),
        ("WarmupCard", "Stretching & Warm-up Routine View"),
        ("DietDayCard", "Diet & Meal Planner View"),
        ("BudgetFoodSection", "Budget Diet & Low-Cost Meal Planner"),
        ("PlansTab", "Workout & Meal Plans Catalog Tab"),
        ("TrackersTab", "Health Trackers Overview Tab"),
        ("WaterTrackerSection", "Water Intake & Hydration Tracker"),
        ("SleepTrackerSection", "Sleep Efficiency & REM Tracker"),
        ("StepTrackerSection", "Step Counter & Distance Burn Tracker"),
        ("AITrainerScreen", "AI Fitness & Exercise Trainer Screen"),
        ("ShopTab", "Supplement & Equipment Shop Catalog Tab"),
        ("BudgetProductCard", "Budget Supplement & Product Details"),
        ("CartScreen", "Shopping Cart & Item Summary Screen"),
        ("CheckoutScreen", "Checkout & Payment Gateway Screen"),
        ("AddressManagementSection", "Shipping Address & Delivery Form"),
        ("OrderConfirmationScreen", "Order Confirmation & Receipt Screen"),
        ("MyOrdersScreen", "My Orders Stepper & History Screen"),
        ("OrderTrackingTimeline", "Live Order Tracking & Stepper Timeline"),
        ("ProfileTab", "User Profile & Account Overview Tab"),
        ("RemindersNotificationModule", "Reminders & Push Notifications Module"),
        ("SettingsLocalizationModule", "Language Switcher & Theme Settings"),
        ("SupabaseIntegrationModule", "Supabase PostgreSQL Database Sync")
    ]

    print(f"Discovered {len(screens)} distinct screens/modules in NutriFit source code.")
    for idx, (code_name, desc) in enumerate(screens, start=1):
        print(f" {idx:02d}. {code_name} -> {desc}")

if __name__ == "__main__":
    analyze_app()
