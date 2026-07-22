import os
import shutil
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

os.makedirs("testing-reports", exist_ok=True)

# 35 Discovered Screens / Modules from lib/main.dart
MODULES = [
    "SplashScreen", "LoginScreen", "SignUpScreen", "ForgotScreen", "SelectScreen",
    "GoalScreen", "GenderScreen", "FoodScreen", "LocationScreen", "NumberScreen",
    "DashboardScreen", "HomeTab", "HeroCard", "WorkoutDayCard", "WarmupCard",
    "DietDayCard", "BudgetFoodSection", "PlansTab", "TrackersTab", "WaterTrackerSection",
    "SleepTrackerSection", "StepTrackerSection", "AITrainerScreen", "ShopTab", "BudgetProductCard",
    "CartScreen", "CheckoutScreen", "AddressManagementSection", "OrderConfirmationScreen", "MyOrdersScreen",
    "OrderTrackingTimeline", "ProfileTab", "RemindersNotificationModule", "SettingsLocalizationModule", "SupabaseIntegrationModule"
]

COLUMNS = [
    "Test Case ID", "Module", "Test Scenario", "Test Steps",
    "Expected Result", "Actual Result", "Status", "Priority"
]

WORKBOOK_CONFIGS = [
    ("NutriFit_Selenium_Test_Report.xlsx", "Selenium Web UI Testing", "SEL", "Staging / Web Chrome", "Chrome v126 / Edge v126"),
    ("NutriFit_Appium_Test_Report.xlsx", "Appium Android E2E Testing", "APP", "Android 14 Emulator", "Android Pixel 6 (API 34)"),
    ("NutriFit_E2E_Test_Report.xlsx", "End-to-End Workflow Testing", "E2E", "Integration Environment", "Cross-Platform Web & Android"),
    ("NutriFit_Functional_Test_Report.xlsx", "Functional & Integration Testing", "FUN", "Unit / Flutter Test Suite", "Dart VM / Flutter SDK"),
    ("NutriFit_Load_Test_Report.xlsx", "Load & Performance Testing", "LOD", "Locust / k6 Load Environment", "Distributed Load Generator Nodes"),
    ("NutriFit_Vulnerability_Test_Report.xlsx", "Safe Vulnerability & Security Checks", "SEC", "Security Audit Sandbox", "Defensive Security Audit Engine")
]

CATEGORY_SCENARIOS = {
    "SEL": [
        ("Verify web page layout rendering and DOM container grid alignment on {module}", "Launch browser in 1920x1080 resolution.\nNavigate to {module} web view.\nInspect grid container margins and CSS alignment.\nVerify zero scrollbar clipping."),
        ("Validate form input fields and error highlight badges on {module}", "Focus input fields on {module}.\nEnter invalid boundary character string.\nTrigger blur event.\nInspect field validation error badge."),
        ("Verify viewport responsiveness across mobile, tablet and desktop on {module}", "Resize browser window across 320px, 768px, 1024px, and 1440px breakpoints.\nObserve {module} layout adaptation.\nVerify text wrapping and element alignment."),
        ("Verify keyboard tab focus order and ARIA accessibility roles on {module}", "Press TAB key repeatedly from top of {module}.\nVerify focus ring sequence on interactive nodes.\nCheck ARIA label attributes."),
        ("Verify cross-browser rendering parity across Chrome, Edge and Firefox on {module}", "Execute test automation on {module} in Chrome, Firefox, and Edge.\nCompare visual screenshots and element bounds.\nConfirm identical rendering behavior."),
        ("Verify Arabic Right-to-Left (RTL) layout mirroring on {module}", "Switch application language to Arabic (ar_SA).\nNavigate to {module}.\nVerify layout flips to right-to-left.\nCheck text alignment and icon mirroring."),
        ("Verify localization string translation switching on {module}", "Select language from header dropdown on {module}.\nVerify all UI labels update to target locale.\nConfirm no missing translation keys."),
        ("Verify interactive button click response and hover state transitions on {module}", "Hover cursor over primary CTA buttons on {module}.\nVerify hover transition effects.\nTrigger click action.\nConfirm expected event dispatch."),
        ("Verify modal backdrop blur, focus trap, and Escape key close on {module}", "Trigger pop-up dialog/modal on {module}.\nAttempt TAB navigation outside modal.\nPress ESC key.\nConfirm modal closes smoothly."),
        ("Verify network error banner and offline UI recovery fallback on {module}", "Simulate network offline condition on {module}.\nAttempt data fetch or submit action.\nInspect error notification banner.\nClick Retry button after reconnect.")
    ],
    "APP": [
        ("Verify native Android touch tap and button ripple effect on {module}", "Launch app on Android emulator.\nNavigate to {module}.\nTap interactive buttons.\nVerify Material ripple effect animation."),
        ("Verify vertical swipe gesture and list scrolling velocity on {module}", "Perform vertical swipe gesture on {module} list container.\nObserve scroll physics and frame rate.\nVerify smooth 60fps scrolling without jank."),
        ("Verify screen orientation transition from Portrait to Landscape on {module}", "Rotate Android device to landscape mode on {module}.\nInspect UI element re-alignment.\nRotate back to portrait.\nVerify safe area bounds."),
        ("Verify hardware Back button stack navigation on {module}", "Navigate deep into {screen_route} via {module}.\nPress physical Android Back button (KeyCode 4).\nVerify app returns to previous screen cleanly."),
        ("Verify system permission dialog request and user grant handling on {module}", "Trigger feature requiring permission on {module}.\nHandle native Android permission dialog.\nGrant permission.\nVerify feature unlocks successfully."),
        ("Verify native push notification banner alert and shade routing to {module}", "Send local push notification targeting {module}.\nPull down Android notification shade.\nTap notification banner.\nVerify direct navigation to {module}."),
        ("Verify offline flight mode operation and Hive local cache on {module}", "Enable Airplane Mode on device.\nNavigate to {module}.\nInspect displayed content.\nVerify cached Hive data renders with offline badge."),
        ("Verify Android BiometricPrompt fingerprint and face unlock on {module}", "Trigger security confirmation on {module}.\nSimulate fingerprint match in emulator.\nVerify BiometricPrompt success.\nConfirm view unlock."),
        ("Verify app backgrounding, pause state, and resume restoration on {module}", "Press Home button while viewing {module}.\nWait 30 seconds in background.\nRe-open app from task manager.\nVerify state and scroll position restored."),
        ("Verify Android Multi-Window split screen layout scaling on {module}", "Activate Multi-Window split screen on Android.\nSet app viewport to 50% screen height.\nInspect {module} UI layout.\nVerify responsive container resizing.")
    ],
    "E2E": [
        ("Verify end-to-end onboarding and initial user navigation to {module}", "Complete registration and onboarding survey.\nNavigate to {module}.\nVerify initial state setup.\nConfirm user profile preferences loaded."),
        ("Verify cross-module data synchronization between {module} and primary dashboard", "Mutate user data records on {module}.\nNavigate to primary dashboard.\nVerify updated data metrics reflect immediately without manual refresh."),
        ("Verify multi-step wizard forward navigation starting from {module}", "Fill required form fields on {module}.\nClick Next step button.\nVerify form data validation.\nConfirm progression to next wizard screen."),
        ("Verify wizard backward navigation and input state retention on {module}", "Advance to step 3 in workflow.\nClick Back button returning to {module}.\nInspect form input fields.\nConfirm all entered data remains intact."),
        ("Verify transactional data submission and Supabase database sync from {module}", "Submit data transaction on {module}.\nInspect local database cache.\nQuery Supabase PostgreSQL table.\nVerify record created with matching ID."),
        ("Verify error boundary handling and state rollback on transaction failure on {module}", "Simulate server 500 error during submission on {module}.\nObserve UI error boundary alert.\nInspect form state.\nVerify state rolls back safely without corruption."),
        ("Verify multi-window session state synchronization for {module}", "Open secondary app view on {module}.\nPerform state mutation.\nSwitch back to primary view.\nVerify session state stays synchronized."),
        ("Verify payment gateway checkout integration flow involving {module}", "Initiate order process passing through {module}.\nEnter delivery and payment details.\nSubmit transaction.\nVerify payment gateway confirmation token."),
        ("Verify active order status tracking stepper progression on {module}", "Navigate to order status view on {module}.\nTrigger status updates from backend.\nObserve status stepper UI.\nVerify sequential transition to Delivered."),
        ("Verify complete profile preference update and locale transition on {module}", "Navigate from {module} to profile settings.\nUpdate language preference.\nReturn to {module}.\nVerify screen re-renders in target locale.")
    ],
    "FUN": [
        ("Verify input field boundary rules and error handling on {module}", "Submit form fields on {module} with min, max, empty, and special character strings.\nInspect validation response.\nVerify precise error message returned."),
        ("Verify business calculation engine logic and math outputs on {module}", "Supply test dataset to calculation engine on {module}.\nExecute calculation logic.\nCompare engine output against domain formula.\nVerify exact match."),
        ("Verify asynchronous service invocation and JSON model parsing on {module}", "Trigger async service request on {module}.\nAwait Future completion.\nParse JSON response payload.\nVerify clean instantiation of Dart domain model."),
        ("Verify reactive state provider listener callbacks and UI rebuild count on {module}", "Mutate state property bound to {module}.\nCount listener callback invocations.\nVerify single UI widget rebuild triggered."),
        ("Verify role-based authorization guard rules and access restriction on {module}", "Attempt accessing feature on {module} using guest role credentials.\nInspect router response.\nVerify access blocked with permission alert."),
        ("Verify local data storage persistence and cache invalidation on {module}", "Save record on {module}.\nTrigger cache invalidation routine.\nReload {module} view.\nVerify stale cache cleared and fresh data fetched."),
        ("Verify unit conversion logic and metric calculation range on {module}", "Input metric values on {module}.\nToggle unit preference (metric/imperial).\nVerify unit conversion math.\nConfirm zero rounding drift."),
        ("Verify state machine valid transitions and illegal skip blocking on {module}", "Trigger state transition on {module}.\nAttempt illegal state skip (e.g. Draft -> Delivered).\nVerify state machine blocks invalid transition."),
        ("Verify event handler callback execution and argument passing on {module}", "Dispatch user interaction event on {module}.\nInspect callback handler parameters.\nVerify event payload passed accurately."),
        ("Verify controller memory release and resource disposal on {module}", "Mount {module} onto navigation stack.\nPop screen from stack.\nInspect memory profiler.\nVerify animation controllers disposed.")
    ],
    "LOD": [
        ("Verify API latency and throughput under 50 concurrent virtual users on {module}", "Run Locust load generator targeting {module} API.\nMaintain 50 VUs for 3 minutes.\nMeasure response time P95.\nVerify latency < 200ms with 0.0% error rate."),
        ("Verify throughput and endpoint stability under 100 concurrent virtual users on {module}", "Ramp up load generator to 100 VUs on {module}.\nSustain peak traffic for 5 minutes.\nInspect HTTP response codes.\nVerify 100% successful 200 OK responses."),
        ("Verify database connection pool efficiency under 250 concurrent requests on {module}", "Inject 250 concurrent read requests to {module} endpoints.\nMonitor PostgreSQL connection pool.\nVerify query response time < 150ms."),
        ("Verify heavy stress handling and connection stability under 500 virtual users on {module}", "Scale load to 500 VUs on {module}.\nMonitor server CPU and memory usage.\nVerify system handles stress without crashing."),
        ("Verify saturation breaking point and graceful error response under 1000 VUs on {module}", "Push load to 1000 VUs on {module}.\nIdentify resource saturation limits.\nVerify system returns 429/503 gracefully without crash."),
        ("Verify system recovery from 10x traffic spike surge on {module}", "Inject sudden 10x burst traffic surge on {module} within 5 seconds.\nMonitor queue processing.\nVerify system recovers baseline latency in < 10s."),
        ("Verify long-duration memory stability under 1-hour sustained load on {module}", "Maintain 80% capacity load on {module} for 60 minutes.\nInspect memory profiler telemetry.\nVerify flat memory line with zero leaks."),
        ("Verify database write transaction throughput under 200 concurrent updates on {module}", "Execute 200 concurrent write transactions on {module} tables.\nInspect transaction log.\nVerify zero deadlock or lock timeout errors."),
        ("Verify Realtime WebSocket message broadcast delivery speed on {module}", "Open 300 active WebSocket subscriptions for {module}.\nBroadcast updates from server.\nMeasure delivery latency.\nVerify P95 latency < 50ms."),
        ("Verify media asset loading speed and CDN caching efficiency on {module}", "Request 50 media assets associated with {module} under throttled network.\nMeasure cache hit response time.\nVerify CDN cache hit speed < 30ms.")
    ],
    "SEC": [
        ("Verify brute-force defense and authentication lockout rules on {module}", "Submit 10 rapid invalid login/auth attempts on {module}.\nInspect response headers.\nVerify account locks after 5 attempts with 429 status."),
        ("Verify role-based access control (RBAC) and IDOR vulnerability defense on {module}", "Attempt accessing secondary user private resource on {module} using non-owner JWT.\nInspect server response.\nVerify access denied with 403 Forbidden."),
        ("Verify session JWT token expiration and invalidation handling on {module}", "Present expired JWT token to {module} API endpoint.\nInspect response.\nVerify session invalidated and redirected to login."),
        ("Verify input sanitization and SQL injection defense on {module}", "Submit safe SQLi test string `' OR '1'='1` into input fields on {module}.\nInspect database query log.\nVerify query parameterized without syntax error."),
        ("Verify Cross-Site Scripting (XSS) DOM escaping and sanitization on {module}", "Submit safe script tag `<script>alert(1)</script>` into {module} input fields.\nInspect rendered DOM node.\nVerify string rendered as literal text without execution."),
        ("Verify TLS 1.3 transport layer encryption enforcement on {module}", "Inspect network connection parameters for {module} using security audit proxy.\nVerify TLS 1.3/1.2 cipher suite.\nConfirm insecure HTTP blocked."),
        ("Verify API rate limiting 429 Too Many Requests response on {module}", "Send 100 rapid requests within 5 seconds to {module} public API endpoint.\nInspect response status.\nVerify HTTP 429 rate limit error returned."),
        ("Verify Supabase Row Level Security (RLS) policy enforcement on {module}", "Execute direct database query on {module} table without authorization header.\nInspect PostgreSQL response.\nVerify RLS policy blocks unauthorized row access."),
        ("Verify privileged route guard interception on unauthenticated access to {module}", "Attempt deep linking directly to protected route for {module} without auth token.\nInspect router behavior.\nVerify request intercepted and redirected."),
        ("Verify sensitive data masking and log exposure prevention for {module}", "Inspect application log output during operations on {module}.\nCheck password, token, and PII fields.\nVerify sensitive fields masked or omitted.")
    ]
}

def generate_10_cases_per_module(cat_code, cat_title, env, dev):
    cases = []
    tc_counter = 1
    scenarios_tpl = CATEGORY_SCENARIOS[cat_code]

    for mod_name in MODULES:
        for idx in range(10):
            tc_id = f"TC_{tc_counter:03d}"
            scen_tpl = scenarios_tpl[idx]

            scen_title = scen_tpl[0].format(module=mod_name, screen_route=mod_name.lower())
            steps = scen_tpl[1].format(module=mod_name, screen_route=mod_name.lower())

            exp_result = f"Verify expected behavior for {mod_name} under {cat_title} scenario #{idx+1}."
            if "layout" in scen_title.lower() or "ui" in scen_title.lower():
                exp_result = f"UI elements on {mod_name} render cleanly with correct alignment and styling."
            elif "validation" in scen_title.lower() or "input" in scen_title.lower():
                exp_result = f"Input validation on {mod_name} correctly enforces rules and displays error hints."
            elif "gesture" in scen_title.lower() or "touch" in scen_title.lower():
                exp_result = f"Touch interactions on {mod_name} execute smoothly with appropriate visual feedback."
            elif "load" in scen_title.lower() or "users" in scen_title.lower() or "api" in scen_title.lower():
                exp_result = f"Endpoint for {mod_name} handles load within SLA response time limits with 0.0% errors."
            elif "security" in scen_title.lower() or "vulnerability" in scen_title.lower() or "auth" in scen_title.lower() or "rls" in scen_title.lower():
                exp_result = f"Security control for {mod_name} successfully blocks unauthorized access or malicious input."

            prio = "High" if (tc_counter % 3 == 0) else ("Low" if (tc_counter % 5 == 0) else "Medium")

            cases.append({
                "Test Case ID": tc_id,
                "Module": mod_name,
                "Test Scenario": f"{scen_title}",
                "Test Steps": steps,
                "Expected Result": exp_result,
                "Actual Result": "Not Executed",
                "Status": "Not Executed",
                "Priority": prio
            })
            tc_counter += 1

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

    total_module_count = len(MODULES)
    total_case_count = len(cases)

    # ----------------------------------------------------
    # Sheet 1: Summary Dashboard
    # ----------------------------------------------------
    ws_sum = wb.create_sheet(title="Summary Dashboard")
    ws_sum.views.sheetView[0].showGridLines = True

    ws_sum["A1"] = f"NutriFit QA Report - {cat_title}"
    ws_sum["A1"].font = title_font
    ws_sum["A2"] = f"Report File: {filename} | Total Modules: {total_module_count} | 10 Cases Per Module | Total: {total_case_count} Cases"
    ws_sum["A2"].font = subtitle_font

    ws_sum.row_dimensions[1].height = 24
    ws_sum.row_dimensions[2].height = 18

    # KPI Summary Cards
    kpis = [
        ("Total Test Cases", "=COUNT('Detailed Test Cases'!A:A)"),
        ("Passed", '=COUNTIF(\'Detailed Test Cases\'!G:G, "Passed")'),
        ("Failed", '=COUNTIF(\'Detailed Test Cases\'!G:G, "Failed")'),
        ("Skipped", '=COUNTIF(\'Detailed Test Cases\'!G:G, "Skipped")'),
        ("Blocked", '=COUNTIF(\'Detailed Test Cases\'!G:G, "Blocked")'),
        ("Not Executed", '=COUNTIF(\'Detailed Test Cases\'!G:G, "Not Executed")'),
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
    ws_sum["A7"] = f"Module-Wise Test Coverage Breakdown (All {total_module_count} Modules)"
    ws_sum["A7"].font = section_font

    mod_headers = ["Module", "Total Cases", "Passed", "Failed", "Skipped", "Blocked", "Not Executed"]
    ws_sum.append(mod_headers)
    ws_sum.row_dimensions[8].height = 24

    for c_idx in range(1, len(mod_headers) + 1):
        cell = ws_sum.cell(row=8, column=c_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')

    for r_offset, mod_name in enumerate(MODULES, start=9):
        ws_sum.cell(row=r_offset, column=1, value=mod_name)
        ws_sum.cell(row=r_offset, column=2, value=f'=COUNTIF(\'Detailed Test Cases\'!B:B, A{r_offset})')
        ws_sum.cell(row=r_offset, column=3, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!G:G, "Passed")')
        ws_sum.cell(row=r_offset, column=4, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!G:G, "Failed")')
        ws_sum.cell(row=r_offset, column=5, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!G:G, "Skipped")')
        ws_sum.cell(row=r_offset, column=6, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!G:G, "Blocked")')
        ws_sum.cell(row=r_offset, column=7, value=f'=COUNTIFS(\'Detailed Test Cases\'!B:B, A{r_offset}, \'Detailed Test Cases\'!G:G, "Not Executed")')

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

    ws_sum.column_dimensions['A'].width = 32
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
        ws_det.row_dimensions[r_idx].height = 42

        for c_idx in range(1, len(COLUMNS) + 1):
            cell = ws_det.cell(row=r_idx, column=c_idx)
            cell.font = Font(name=font_family, size=9)
            cell.border = thin_border
            cell.alignment = Alignment(vertical='top', wrap_text=True)

            if c_idx in [1, 7, 8]: # ID, Status, Priority
                cell.alignment = Alignment(horizontal='center', vertical='top', wrap_text=True)

            # Apply Status Style (7th column: Status)
            if c_idx == 7:
                status_val = cell.value
                if status_val in status_styles:
                    fill, font = status_styles[status_val]
                    cell.fill = fill
                    cell.font = font

    ws_det.auto_filter.ref = f"A1:{get_column_letter(len(COLUMNS))}{len(cases) + 1}"

    col_widths = {
        "Test Case ID": 14,
        "Module": 28,
        "Test Scenario": 35,
        "Test Steps": 45,
        "Expected Result": 35,
        "Actual Result": 18,
        "Status": 15,
        "Priority": 12
    }

    for c_idx, c_name in enumerate(COLUMNS, start=1):
        ws_det.column_dimensions[get_column_letter(c_idx)].width = col_widths.get(c_name, 20)

    # ----------------------------------------------------
    # Sheet 3: Execution Evidence
    # ----------------------------------------------------
    ws_ev = wb.create_sheet(title="Execution Evidence")
    ws_ev.views.sheetView[0].showGridLines = True
    ev_cols = ["Test Case ID", "Module", "Test Scenario", "Status", "Evidence Path", "Timestamp", "Verification Notes"]
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
            tc["Test Scenario"],
            tc["Status"],
            f"testing-reports/evidence/{tc['Test Case ID'].lower()}_proof.png",
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
    print(f"SUCCESS: Saved '{rep_path}' and '{filename}' with {total_case_count} test cases.")

def main():
    total_cases_all = 0
    num_modules = len(MODULES)
    print(f"=== GENERATING WORKBOOKS FOR {num_modules} DISCOVERED MODULES (10 CASES EACH) ===")

    for filename, cat_title, prefix, env, dev in WORKBOOK_CONFIGS:
        cases = generate_10_cases_per_module(prefix, cat_title, env, dev)
        expected_cases = num_modules * 10
        assert len(cases) == expected_cases, f"Error: expected {expected_cases} cases for {filename}, got {len(cases)}"
        build_workbook(filename, cat_title, cases)
        total_cases_all += len(cases)

    print("\n==================================================")
    print(f"GENERATION COMPLETE! TOTAL TEST CASES = {total_cases_all}")
    print(f"FILES GENERATED = {len(WORKBOOK_CONFIGS)}")
    print("==================================================")

if __name__ == "__main__":
    main()
