import os
import shutil
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

os.makedirs("testing-reports", exist_ok=True)

MODULES = [
    "Authentication", "Dashboard", "Workout", "Diet", "Budget Diet",
    "Stretching", "Water Tracker", "Sleep Tracker", "Step Tracker", "AI Trainer",
    "Shop", "Cart", "Checkout", "Address", "Orders", "Profile",
    "Notifications", "Settings", "Localization", "Supabase Integration",
    "Responsive Web", "Android UI"
]

COLUMNS = [
    "Test Case ID", "Module", "Scenario", "Test Title", "Objective",
    "Preconditions", "Detailed Test Steps", "Test Data", "Expected Result",
    "Actual Result", "Priority", "Severity", "Status",
    "Automation Script Path", "Evidence Path", "Remarks"
]

WORKBOOK_CONFIGS = [
    ("NutriFit_Selenium_Test_Report.xlsx", "Selenium Web UI Testing", "SEL", "automation/pages/test_selenium_web.py"),
    ("NutriFit_Appium_Test_Report.xlsx", "Appium Android E2E Testing", "APP", "test/e2e/run_appium_test.py"),
    ("NutriFit_E2E_Test_Report.xlsx", "End-to-End Workflow Testing", "E2E", "test/e2e/test_full_workflow.py"),
    ("NutriFit_Functional_Test_Report.xlsx", "Functional & Integration Testing", "FUN", "test/integration_test.dart"),
    ("NutriFit_Load_Test_Report.xlsx", "Load & Performance Testing", "LOD", "test/load/k6_load_test.js"),
    ("NutriFit_Vulnerability_Test_Report.xlsx", "Safe Vulnerability & Security Checks", "SEC", "test/e2e/generate_vulnerability_report.py")
]

TEMPLATES = {
    "SEL": [
        ("Web UI Layout & DOM Grid Scaling", "Launch Web Chrome/Edge driver at viewport resolution, verify container grid, element alignments and navbar collapse state.", "Viewport: {detail}", "UI layout scales cleanly without horizontal scrollbars or clipping."),
        ("Web Login & User Registration Flow", "Fill web login form with email and password, submit form and verify dashboard redirection.", "Form Input: {detail}", "Login authenticates successfully and renders user dashboard view."),
        ("Navigation Bar & Deep Linking", "Click navbar menu links and verify active route state and browser URL updates.", "Route Path: {detail}", "Navigation updates route path smoothly without page reloads."),
        ("Forms Validation & Error Badges", "Focus input element, enter invalid boundary value, trigger blur event, inspect validation error badge.", "Input value: {detail}", "Validation hint appears immediately with accessible aria warning."),
        ("Responsive Layout & Viewport Adaptability", "Resize browser window across Mobile, Tablet, and Desktop breakpoints.", "Screen Width: {detail}", "UI components re-align dynamically without overlapping elements."),
        ("Cross-Browser Compatibility", "Execute web test suite on Chrome, Firefox, Safari, and Microsoft Edge.", "Browser Engine: {detail}", "All interactive controls render identically across browser engines."),
        ("Localization & Language Translation", "Toggle application language between English and target locale in header dropdown.", "Locale Code: {detail}", "All string resources render correctly in selected language."),
        ("Arabic Right-to-Left (RTL) Layout", "Switch application locale to Arabic (ar_SA) and inspect layout direction.", "RTL Config: {detail}", "UI flips to right-to-left layout with mirrored icons and aligned Arabic text."),
        ("Dashboard Analytics & Telemetry Cards", "Inspect dashboard metric cards, charts, and daily summary widgets.", "Widget Spec: {detail}", "Dashboard widgets display accurate aggregated user metrics."),
        ("Diet & Workout Module Interaction", "Navigate to workout and diet modules, interact with daily meal and exercise logs.", "Module Action: {detail}", "Meal and exercise items update in real time with correct calorie totals."),
        ("Shop Catalog & Cart Management", "Browse shop products, apply category filter, and add selected item to cart.", "Cart Action: {detail}", "Cart counter badge increments and item reflects in cart drawer."),
        ("Checkout Wizard & Payment Form", "Proceed to checkout form, enter delivery address, select payment method, submit order.", "Checkout Data: {detail}", "Order processes cleanly with valid order summary and total calculation."),
        ("Orders List & Invoice Verification", "Open My Orders view, filter by order status, and inspect invoice details.", "Order Ref: {detail}", "Order details display complete item breakdown and downloadable invoice link.")
    ],
    "APP": [
        ("Android Native UI & Component Bounds", "Launch Appium driver on target Android emulator/device, inspect UI widget boundaries.", "Screen Name: {detail}", "Native Android components render within safe area margins without clipping."),
        ("Touch Interaction & Tap Response", "Perform tap and double-tap gestures on interactive UI buttons and cards.", "Touch Target: {detail}", "Button triggers immediate touch feedback animation and dispatches event."),
        ("Gestures: Swipe, Scroll & Drag-Drop", "Execute vertical scroll, horizontal swipe, and drag-and-drop gestures.", "Gesture Type: {detail}", "ListView/RecyclerView scrolls smoothly at 60fps without gesture drag locking."),
        ("Device Resolution & Screen Density", "Execute mobile UI suite across diverse Android screen densities (hdpi to xxxhdpi).", "Screen Density: {detail}", "UI assets scale crisp and clear without pixelation or layout shifts."),
        ("Screen Orientation (Portrait/Landscape)", "Rotate device orientation 90 degrees to landscape and back to portrait.", "Device Rotation: {detail}", "App layout adapts responsively to landscape orientation without clipping."),
        ("System Permissions (Camera/Storage/Biometrics)", "Trigger feature requiring permission, verify native Android permission dialog handling.", "Permission Type: {detail}", "System dialog triggers appropriately; granting permission enables feature."),
        ("Native Push Notifications & Shade Routing", "Trigger local push notification alert, open shade, tap notification banner.", "Payload ID: {detail}", "App opens target screen specified in push notification payload."),
        ("Offline Behavior & Flight Mode Caching", "Enable Airplane mode, navigate screens, and verify local Hive database caching.", "Network State: {detail}", "App displays offline warning banner while serving cached local data cleanly."),
        ("Mobile Authentication & Biometrics", "Trigger Biometrics unlock prompt, verify fingerprint/face auth flow.", "Auth Spec: {detail}", "Native BiometricPrompt triggers and unlocks app upon success."),
        ("Navigation & Android Hardware Back Button", "Navigate deep into screen hierarchy, press physical/software Android Back button.", "Back Key Code 4: {detail}", "App pops top route cleanly and returns to previous view without crash."),
        ("App Lifecycle (Pause/Resume/Background)", "Press Home button to send app to background for 30 seconds, then resume.", "Lifecycle State: {detail}", "App restores view state intact without memory leak or session loss.")
    ],
    "E2E": [
        ("End-to-End User Journey: Registration to Dashboard", "Execute full flow from user registration, email verification, onboarding survey to dashboard.", "Journey Data: {detail}", "User account created, preferences saved, and dashboard loaded cleanly."),
        ("End-to-End User Journey: Goal Selection to Workout", "Select fitness goal (Weight Loss/Muscle Gain), generate custom workout plan, log first workout set.", "Workout Journey: {detail}", "Custom workout plan generated and completed sets persist in history."),
        ("End-to-End User Journey: Diet Plan & Meal Tracker", "Choose diet preference (Keto/Balanced), customize daily calories, log breakfast and lunch items.", "Diet Journey: {detail}", "Daily macros update dynamically and calorie bar reflects consumed totals."),
        ("End-to-End User Journey: Budget Diet Calculation", "Set weekly food budget, calculate cost-optimized meal plan, export shopping list.", "Budget Journey: {detail}", "Budget meal plan generated within target cost with itemized ingredients."),
        ("End-to-End User Journey: Shop Catalog to Cart", "Browse shop, search product, select quantity, add to cart, and verify subtotal.", "Shop Journey: {detail}", "Cart updates with item details, correct price, and tax calculations."),
        ("End-to-End User Journey: Checkout to Order Confirmation", "Enter shipping address, apply promo code, select payment gateway, complete order.", "Checkout Journey: {detail}", "Order confirmation screen displays order ID and estimated delivery date."),
        ("End-to-End User Journey: Order Tracking & Stepper", "Navigate to active order tracking, observe status stepper progression from Placed to Delivered.", "Tracking Journey: {detail}", "Status stepper updates accurately as order status changes."),
        ("End-to-End User Journey: Profile & Locale Switch", "Open profile settings, update demographics, switch language from EN to AR, verify UI update.", "Profile Journey: {detail}", "Profile details persist and entire UI translates to Arabic seamlessly.")
    ],
    "FUN": [
        ("Feature Logic: Input Boundary & Validation", "Submit form fields with min, max, empty, and special character strings.", "Field Rule: {detail}", "Input handler enforces constraints and returns precise error messages."),
        ("Feature Logic: BMI Formula & Classification Math", "Supply weight and height values, verify BMI calculation `weight / height^2` and category label.", "BMI Input: {detail}", "Calculates exact BMI value and assigns correct category (Normal, Overweight, etc.)."),
        ("Feature Logic: Hydration Target & Intake Logging", "Log water cup entries, verify total volume accumulated against daily target goal.", "Water Log: {detail}", "Water intake progress bar updates correctly with percentage target achieved."),
        ("Feature Logic: Sleep Score & REM Stage Calculation", "Log sleep start/end times and awakenings, verify calculated sleep efficiency score.", "Sleep Data: {detail}", "Computes accurate sleep duration and sleep quality score percentage."),
        ("Feature Logic: Step Tracker Stride & Calorie Conversion", "Feed accelerometer step count sensor data, calculate distance walked and active calories burned.", "Step Payload: {detail}", "Converts steps to distance and calories using user body weight metrics."),
        ("Feature Logic: Workout Set & Rep Tracking State", "Record set weight and rep count, trigger rest countdown timer.", "Workout Log: {detail}", "Set values persist in active workout session and timer counts down."),
        ("Feature Logic: Diet Calorie & Macro Distribution Math", "Log food item with protein, carbs, and fat grams, verify macro calorie breakdown.", "Macro Input: {detail}", "Calculates total calories `(P*4 + C*4 + F*9)` and macro percentages."),
        ("Feature Logic: AI Fitness Trainer Prompt Context Engine", "Trigger AI recommendation, verify prompt builder aggregates user goals and workout history.", "AI Context: {detail}", "AI service constructs valid prompt payload and parses structured response."),
        ("Feature Logic: User Profile Management & Avatar Crop", "Update profile bio, height/weight metrics, and select new avatar image.", "Profile Payload: {detail}", "Profile changes persist locally and sync to Supabase database."),
        ("Feature Logic: Shop Inventory & Coupon Code Math", "Apply percentage discount coupon to shopping cart subtotal.", "Coupon Code: {detail}", "Subtotal reduces by exact percentage and tax recalculates accurately."),
        ("Feature Logic: Order Invoice Generation & State Machine", "Trigger order status transition (Pending -> Processing -> Completed).", "Order Transition: {detail}", "Order state machine validates allowed state transitions without invalid skips.")
    ],
    "LOD": [
        ("Load Benchmark: Concurrent User Load (50-1000 VUs)", "Run load test generator with concurrent virtual users, measure system throughput.", "VU Scalability: {detail}", "System maintains stable throughput with P95 latency below SLA threshold."),
        ("Load Benchmark: Login & Auth Token Endpoint", "Simulate 200 concurrent user login requests per second targeting auth API.", "Auth Latency: {detail}", "Auth API processes login requests with zero 5xx server errors."),
        ("Load Benchmark: Dashboard Metrics Fetch Throughput", "Execute continuous read requests targeting aggregated dashboard summary endpoint.", "Dashboard Load: {detail}", "Dashboard endpoint returns response in < 250ms under peak load."),
        ("Load Benchmark: REST & Supabase API Load", "Fire concurrent API GET/POST requests targeting Supabase REST endpoints.", "API RPS: {detail}", "Supabase API handles requests without connection pool exhaustion."),
        ("Load Benchmark: Database Query Execution & Connection Sizing", "Run heavy relational query suite targeting Supabase PostgreSQL instance under load.", "DB Query Load: {detail}", "Query execution time remains under 100ms with connection pool active."),
        ("Load Benchmark: Supabase Realtime Subscription Load", "Open 300 active WebSocket connections for live order tracking updates.", "WebSocket Concurrency: {detail}", "Realtime channel broadcasts updates reliably to all connected clients."),
        ("Load Benchmark: Product Catalog Search & Pagination", "Execute search and paginated requests on shop catalog database containing 10,000 items.", "Catalog Search Load: {detail}", "Catalog search returns paginated results in < 200ms."),
        ("Load Benchmark: Cart Concurrent Addition & Optimistic Lock", "Simulate 150 users simultaneously adding low-stock items to cart.", "Cart Concurrency: {detail}", "Inventory locks prevent over-selling and maintain stock count integrity."),
        ("Load Benchmark: Checkout Payment Endpoint Throughput", "Submit concurrent checkout transactions to simulated payment gateway.", "Checkout RPS: {detail}", "Checkout service processes payments smoothly with 0.0% failure rate."),
        ("Load Benchmark: Order Creation Batch & Lock Contention", "Insert 500 order records simultaneously into database table.", "Batch Insert: {detail}", "Batch insertion completes without deadlocks or primary key collision errors."),
        ("Load Benchmark: Stress Testing Saturation Limits", "Increase VU count gradually until system resources reach 90% CPU/RAM saturation.", "Stress Saturation: {detail}", "System gracefully degrades latency without sudden service crash."),
        ("Load Benchmark: Spike Testing (10x Surge in 10s)", "Inject sudden burst of 500 VUs over a 5-second interval.", "Traffic Spike: {detail}", "System absorbs traffic spike without dropping incoming HTTP connections."),
        ("Load Benchmark: Endurance Testing (Sustained Load)", "Maintain 80% maximum capacity load over continuous extended test duration.", "Endurance Duration: {detail}", "Memory usage remains steady without progressive memory leaks.")
    ],
    "SEC": [
        ("Security Validation: Authentication & Password Policy", "Test login endpoint against brute-force attacks and password complexity rules.", "Auth Defense: {detail}", "Account locks after 5 failed attempts; weak passwords rejected."),
        ("Security Validation: Role-Based Authorization & IDOR Checks", "Attempt accessing secondary user's private data using non-owner JWT token.", "IDOR Check: {detail}", "Server rejects unauthorized data access with HTTP 403 Forbidden."),
        ("Security Validation: Session Token Management & Revocation", "Verify JWT expiry time, HTTP-only cookie flags, and token revocation on logout.", "Session Security: {detail}", "Expired or revoked JWT tokens are immediately rejected by API gateway."),
        ("Security Validation: Input Sanitization & SQL Injection Defense", "Submit safe SQLi payloads `' OR '1'='1` in search and login text fields.", "Safe SQLi Payload: {detail}", "Input is parameterized/escaped cleanly; no raw SQL execution occurs."),
        ("Security Validation: Cross-Site Scripting (XSS) DOM Escaping", "Submit safe script payload `<script>alert(1)</script>` into profile name input.", "Safe XSS Payload: {detail}", "Input is sanitized and rendered as plain text string; script does not execute."),
        ("Security Validation: Data Encryption at Rest & In-Transit (TLS 1.3)", "Audit transport security protocols and database storage encryption settings.", "Encryption Audit: {detail}", "All outbound connections enforce TLS 1.3; database columns use AES-256."),
        ("Security Validation: API Rate Limiting & Abuse Prevention", "Send 100 rapid requests within 5 seconds to public API endpoints.", "Rate Limit Check: {detail}", "API gateway returns HTTP 429 Too Many Requests after threshold."),
        ("Security Validation: Supabase Row Level Security (RLS) Audit", "Query Supabase tables without valid JWT authorization headers.", "RLS Enforcement: {detail}", "Supabase RLS policies block unauthorized row queries for all tables."),
        ("Security Validation: Access Control & Privileged Route Guard", "Attempt navigating directly to admin routes as standard user role.", "Route Guard: {detail}", "Router blocks navigation and redirects user to permission denied view."),
        ("Security Validation: Error Handling & Stack Trace Suppression", "Trigger runtime exception and inspect HTTP 500 error response payload.", "Error Payload: {detail}", "Error response contains clean message without internal stack traces."),
        ("Security Validation: Sensitive Data Exposure & PII Masking", "Audit log files and API response bodies for raw password or credit card data.", "PII Audit: {detail}", "Sensitive user fields are masked or omitted entirely from logs."),
        ("Security Validation: HTTP Security Headers Configuration", "Inspect HTTP response headers for security hardening directives.", "Security Headers: {detail}", "Headers include CSP, HSTS, X-Frame-Options, and X-Content-Type-Options."),
        ("Security Validation: Dependency Vulnerability Audit", "Scan project dependencies and configuration files for known CVE vulnerabilities.", "Dependency Audit: {detail}", "Zero high or critical severity vulnerabilities detected in dependencies.")
    ]
}

def generate_400_cases_for_prefix(prefix, cat_title, default_script_path):
    cases = []
    scenarios = TEMPLATES[prefix]

    for i in range(1, 401):
        tc_id = f"TC-{i:03d}"
        mod = MODULES[(i - 1) % len(MODULES)]
        scen_tpl = scenarios[(i - 1) % len(scenarios)]

        detail_variant = f"Variant #{i} ({mod})"
        title = f"{cat_title} - {mod} - {scen_tpl[0]} (#{i})"
        scenario = f"{scen_tpl[0]} for {mod}"
        obj = f"Ensure {mod} module satisfies quality criteria for {cat_title} category."
        pre = f"Test environment active, NutriFit app launched on local test setup for {mod}."
        steps = f"1. Launch test runner.\n2. Navigate to {mod} view.\n3. {scen_tpl[1]}\n4. Validate assertions."
        data = f"Module: {mod}, Data Detail: {scen_tpl[2].format(detail=detail_variant)}"
        exp = f"{scen_tpl[3]} for module {mod}."

        prio = "High" if i % 3 == 0 else ("Low" if i % 5 == 0 else "Medium")
        sev = "Critical" if i % 7 == 0 else ("Major" if i % 2 == 0 else "Moderate")

        cases.append({
            "Test Case ID": tc_id,
            "Module": mod,
            "Scenario": scenario,
            "Test Title": title,
            "Objective": obj,
            "Preconditions": pre,
            "Detailed Test Steps": steps,
            "Test Data": data,
            "Expected Result": exp,
            "Actual Result": "Pending Execution",
            "Priority": prio,
            "Severity": sev,
            "Status": "Not Executed",
            "Automation Script Path": default_script_path,
            "Evidence Path": f"testing-reports/evidence/{prefix.lower()}_tc_{i:03d}.png",
            "Remarks": f"Automated baseline case for {cat_title}"
        })

    return cases

def build_workbook(filename, cat_title, cases):
    wb = openpyxl.Workbook()
    wb.remove(wb.active) # remove default sheet

    font_family = "Segoe UI"
    header_font = Font(name=font_family, size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="10A866", end_color="10A866", fill_type="solid") # Emerald Green

    title_font = Font(name=font_family, size=15, bold=True, color="0A5C36")
    subtitle_font = Font(name=font_family, size=10, italic=True, color="555555")
    section_font = Font(name=font_family, size=12, bold=True, color="0A5C36")

    thin_border = Border(
        left=Side(style='thin', color='E0E0E0'),
        right=Side(style='thin', color='E0E0E0'),
        top=Side(style='thin', color='E0E0E0'),
        bottom=Side(style='thin', color='E0E0E0')
    )

    card_border = Border(
        left=Side(style='medium', color='10A866'),
        right=Side(style='medium', color='10A866'),
        top=Side(style='medium', color='10A866'),
        bottom=Side(style='medium', color='10A866')
    )

    status_styles = {
        "Passed": (PatternFill(start_color="E8F8F0", end_color="E8F8F0", fill_type="solid"), Font(name=font_family, color="10A866", bold=True)),
        "Failed": (PatternFill(start_color="FCE8E6", end_color="FCE8E6", fill_type="solid"), Font(name=font_family, color="D93025", bold=True)),
        "Skipped": (PatternFill(start_color="FEF7E0", end_color="FEF7E0", fill_type="solid"), Font(name=font_family, color="B06000", bold=True)),
        "Blocked": (PatternFill(start_color="FFEFE6", end_color="FFEFE6", fill_type="solid"), Font(name=font_family, color="D9530F", bold=True)),
        "Not Executed": (PatternFill(start_color="F1F3F4", end_color="F1F3F4", fill_type="solid"), Font(name=font_family, color="5F6368", bold=True))
    }

    # ----------------------------------------------------
    # Sheet 1: Summary Dashboard
    # ----------------------------------------------------
    ws_sum = wb.create_sheet(title="Summary Dashboard")
    ws_sum.views.sheetView[0].showGridLines = True

    ws_sum["A1"] = f"NutriFit QA Report - {cat_title}"
    ws_sum["A1"].font = title_font
    ws_sum["A2"] = f"Report File: {filename} | Total Test Cases: 400 | Status: 100% Not Executed Baseline"
    ws_sum["A2"].font = subtitle_font

    ws_sum.row_dimensions[1].height = 24
    ws_sum.row_dimensions[2].height = 18

    # KPI Summary Cards
    kpis = [
        ("Total Test Cases", "=COUNT('Detailed Test Cases'!A:A)"),
        ("Passed", '=COUNTIF(\'Detailed Test Cases\'!M:M, "Passed")'),
        ("Failed", '=COUNTIF(\'Detailed Test Cases\'!M:M, "Failed")'),
        ("Skipped", '=COUNTIF(\'Detailed Test Cases\'!M:M, "Skipped")'),
        ("Blocked", '=COUNTIF(\'Detailed Test Cases\'!M:M, "Blocked")'),
        ("Not Executed", '=COUNTIF(\'Detailed Test Cases\'!M:M, "Not Executed")'),
        ("Pass Rate %", '=IF(B4=0, "0%", TEXT(B5/B4, "0.0%"))')
    ]

    for col_idx, (hdr, form) in enumerate(kpis, start=1):
        c_hdr = ws_sum.cell(row=4, column=col_idx, value=hdr)
        c_hdr.font = Font(name=font_family, size=9, bold=True, color="555555")
        c_hdr.alignment = Alignment(horizontal='center', vertical='center')
        c_hdr.fill = PatternFill(start_color="F5F7FA", end_color="F5F7FA", fill_type="solid")

        c_val = ws_sum.cell(row=5, column=col_idx, value=form)
        c_val.font = Font(name=font_family, size=14, bold=True, color="0A5C36")
        c_val.alignment = Alignment(horizontal='center', vertical='center')
        c_val.border = card_border

    # Module Coverage Breakdown Table
    ws_sum["A7"] = "Module-Wise Test Coverage Breakdown (All 22 Modules)"
    ws_sum["A7"].font = section_font

    mod_headers = ["Module Name", "Total Cases", "Passed", "Failed", "Skipped", "Blocked", "Not Executed"]
    ws_sum.append(mod_headers)
    ws_sum.row_dimensions[8].height = 24

    for c_idx in range(1, len(mod_headers) + 1):
        cell = ws_sum.cell(row=8, column=c_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')

    for r_offset, mod in enumerate(MODULES, start=9):
        ws_sum.cell(row=r_offset, column=1, value=mod)
        ws_sum.cell(row=r_offset, column=2, value=f'=COUNTIF(\'Detailed Test Cases\'!B:B, A{r_offset})')
        ws_sum.cell(row=r_offset, column=3, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!M:M, "Passed")')
        ws_sum.cell(row=r_offset, column=4, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!M:M, "Failed")')
        ws_sum.cell(row=r_offset, column=5, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!M:M, "Skipped")')
        ws_sum.cell(row=r_offset, column=6, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!M:M, "Blocked")')
        ws_sum.cell(row=r_offset, column=7, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!M:M, "Not Executed")')

        for c_idx in range(1, 8):
            cell = ws_sum.cell(row=r_offset, column=c_idx)
            cell.font = Font(name=font_family, size=9)
            cell.border = thin_border
            if c_idx >= 2:
                cell.alignment = Alignment(horizontal='center', vertical='center')

    # Total Row
    tot_row = 9 + len(MODULES)
    ws_sum.cell(row=tot_row, column=1, value="Total Suite").font = Font(name=font_family, size=10, bold=True)
    for c_idx in range(2, 8):
        col_let = get_column_letter(c_idx)
        cell = ws_sum.cell(row=tot_row, column=c_idx, value=f"=SUM({col_let}9:{col_let}{tot_row-1})")
        cell.font = Font(name=font_family, size=10, bold=True)
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = thin_border
        cell.fill = PatternFill(start_color="F0F9F4", end_color="F0F9F4", fill_type="solid")

    ws_sum.column_dimensions['A'].width = 30
    for c in ['B', 'C', 'D', 'E', 'F', 'G']:
        ws_sum.column_dimensions[c].width = 16

    # ----------------------------------------------------
    # Sheet 2: Detailed Test Cases
    # ----------------------------------------------------
    ws_det = wb.create_sheet(title="Detailed Test Cases")
    ws_det.views.sheetView[0].showGridLines = True
    ws_det.append(COLUMNS)
    ws_det.row_dimensions[1].height = 28
    ws_det.freeze_panes = "A2"

    for c_idx in range(1, len(COLUMNS) + 1):
        cell = ws_det.cell(row=1, column=c_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')

    for r_idx, tc in enumerate(cases, start=2):
        row_vals = [tc[c] for c in COLUMNS]
        ws_det.append(row_vals)
        ws_det.row_dimensions[r_idx].height = 36

        for c_idx in range(1, len(COLUMNS) + 1):
            cell = ws_det.cell(row=r_idx, column=c_idx)
            cell.font = Font(name=font_family, size=9)
            cell.border = thin_border
            cell.alignment = Alignment(vertical='top', wrap_text=True)

            if c_idx in [1, 11, 12, 13]: # ID, Priority, Severity, Status
                cell.alignment = Alignment(horizontal='center', vertical='top', wrap_text=True)

            # Apply Status Style (13th column)
            if c_idx == 13:
                status_val = cell.value
                if status_val in status_styles:
                    fill, font = status_styles[status_val]
                    cell.fill = fill
                    cell.font = font

    ws_det.auto_filter.ref = f"A1:{get_column_letter(len(COLUMNS))}{len(cases) + 1}"

    col_widths = {
        "Test Case ID": 14,
        "Module": 20,
        "Scenario": 28,
        "Test Title": 35,
        "Objective": 35,
        "Preconditions": 30,
        "Detailed Test Steps": 45,
        "Test Data": 28,
        "Expected Result": 35,
        "Actual Result": 20,
        "Priority": 12,
        "Severity": 12,
        "Status": 15,
        "Automation Script Path": 30,
        "Evidence Path": 30,
        "Remarks": 25
    }

    for c_idx, c_name in enumerate(COLUMNS, start=1):
        ws_det.column_dimensions[get_column_letter(c_idx)].width = col_widths.get(c_name, 20)

    # ----------------------------------------------------
    # Sheet 3: Execution Evidence
    # ----------------------------------------------------
    ws_ev = wb.create_sheet(title="Execution Evidence")
    ws_ev.views.sheetView[0].showGridLines = True
    ev_cols = ["Test Case ID", "Module", "Scenario", "Status", "Evidence Path", "Automation Script Path", "Timestamp", "Verification Notes"]
    ws_ev.append(ev_cols)
    ws_ev.row_dimensions[1].height = 28
    ws_ev.freeze_panes = "A2"

    for c_idx in range(1, len(ev_cols) + 1):
        cell = ws_ev.cell(row=1, column=c_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')

    for idx, tc in enumerate(cases[:20], start=2):
        ws_ev.append([
            tc["Test Case ID"],
            tc["Module"],
            tc["Scenario"],
            tc["Status"],
            tc["Evidence Path"],
            tc["Automation Script Path"],
            "2026-07-22 00:00:00 UTC",
            "Baseline execution artifact initialized"
        ])
        for c_idx in range(1, len(ev_cols) + 1):
            cell = ws_ev.cell(row=idx, column=c_idx)
            cell.font = Font(name=font_family, size=9)
            cell.border = thin_border
            cell.alignment = Alignment(vertical='top', wrap_text=True)

    ws_ev.auto_filter.ref = f"A1:{get_column_letter(len(ev_cols))}21"
    for c_idx in range(1, len(ev_cols) + 1):
        ws_ev.column_dimensions[get_column_letter(c_idx)].width = 25

    # Save to testing-reports/ AND root directory
    rep_path = os.path.join("testing-reports", filename)
    wb.save(rep_path)
    shutil.copy(rep_path, filename)
    print(f"SUCCESS: Saved '{rep_path}' and '{filename}' with 400 test cases.")

def main():
    total_cases_all = 0
    for filename, cat_title, prefix, script_path in WORKBOOK_CONFIGS:
        cases = generate_400_cases_for_prefix(prefix, cat_title, script_path)
        assert len(cases) == 400, f"Error generating 400 cases for {filename}"
        build_workbook(filename, cat_title, cases)
        total_cases_all += len(cases)

    print("\n==================================================")
    print(f"GENERATION COMPLETE! TOTAL TEST CASES = {total_cases_all}")
    print("==================================================")

if __name__ == "__main__":
    main()
