# NutriFit Appium E2E Test Suite

This folder contains a complete A to Z E2E test suite for the NutriFit Flutter App using Appium.

## Features Covered
The test suite covers 36 different scenarios, including:
- App Launch & Splash Screen
- User Authentication (Login, Signup, Forgot Password)
- Onboarding (Goals, Gender, Age, Height, Weight, Preferences, Location)
- Dashboard Tabs (Plans, Trackers, Shop, Profile)
- AI Trainer, Calorie Calculator, Timers
- E-commerce (Add to Cart, Wishlist, Checkout)

## How to Run the Tests

### Python Version
Requires Python 3.11+.
```bash
pip install Appium-Python-Client openpyxl
python run_appium_test.py
```

### Node.js Version
Requires Node 20+.
```bash
npm install
node run_test.js
```

### Mock Report Generation
If you want to generate a sample mock Excel report (`NutriFit_E2E_Test_Report.xlsx`) demonstrating the output without running the emulator:
```bash
python generate_mock_excel.py
```

## Reports
Execution outputs a detailed Excel report formatted with: Test Case ID, Feature, Test Scenario, Expected Result, Actual Result, Status, Remarks.
