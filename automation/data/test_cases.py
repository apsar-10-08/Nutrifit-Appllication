def get_all_test_cases():
    categories = {
        'Authentication': (40, 'AUTH', 'Verify login, logout, password policies, onboarding completion, registration sync, password reset links, session persistence, and invalid logins.'),
        'Authorization': (40, 'AUTHZ', 'Verify guest guards, onboarding redirect guards, profile page restrictions, remote sync RLS policies, custom session lockouts, cache protection, and token validation.'),
        'Navigation': (30, 'NAV', 'Verify tab switching between Home, Plans, Trackers, Shop, Profile; deep links, browser back-button behavior, redirects, and navigation history states.'),
        'UI Validation': (50, 'UI', 'Verify dashboard Today Plan illustrations, text sizes, HSL green palette color contrast, progress ring graphs, bar chart renders, responsiveness of columns on mobile/web, typography, margins, and borders.'),
        'Forms': (50, 'FORM', 'Verify water log input popups, custom water target form, time pickers for sleep/wake, step count increment triggers, edit onboarding values, address input fields, state selection, payment cards format, and validation messages.'),
        'CRUD Operations': (50, 'CRUD', 'Verify save/delete addresses, update profile, add/remove cart items, adjust item quantities, place orders, cancel orders, buy again, and add/toggle tracker logs.'),
        'Input Validation': (40, 'VAL', 'Verify 10-digit mobile check, 6-digit Indian pincode bounds, non-numeric letters block in metrics, boundary age weights, long instructions truncation, and character escapes.'),
        'Error Handling': (20, 'ERR', 'Verify offline fallback notifications, empty states handling on My Orders, database query timeouts, missing product image display, invalid routes error screen, and alert alerts.'),
        'Session Management': (20, 'SESS', 'Verify token refresh, logout session clearing, cookie checks, storage isolation, and multi-tab state sync.'),
        'File Upload': (20, 'FILE', 'Verify profile picture upload formats (PNG/JPEG), size limit checks, upload cancellation, upload status loader, image preview update, and Supabase storage sync.'),
        'Accessibility': (20, 'ACC', 'Verify ARIA accessibility button roles, screen-reader text labels, visual color contrasts, keyboard tab-focus controls, and font scaling adapt.'),
        'Responsive Design': (20, 'RESP', 'Verify wrapping text, sidebar grid layout adjustment under 700px, hidden desktop assets, mobile touch target sizes (minimum 48px), and overflow scrolls.'),
        'Performance Smoke Tests': (20, 'PERF', 'Verify page load TTI benchmarks (< 3s), dynamic logs retrieval latency, image caching speed, local database write times, and frame rate smoothness.'),
        'Regression': (50, 'REG', 'Verify no regressions across onboarding, trackers, weekly sleep charts, cart checkout flow, payment forms, orders timeline cards, and cancellation options.')
    }

    test_cases = []

    for category, (count, prefix, desc) in categories.items():
        for i in range(1, count + 1):
            test_id = f"{prefix}-{i:03d}"
            priority = "High" if i <= (count // 4) else ("Medium" if i <= (count // 1.5) else "Low")
            
            # Formulate steps and expected results programmatically based on index
            preconditions = "Application launched, base URL loaded successfully."
            if category == 'Authentication':
                preconditions = "Application launched, guest state active."
                steps = [
                    f"1. Navigate to {BASE_URL}",
                    f"2. Trigger Auth sub-test case scenario {i}",
                    f"3. Submit email/password form inputs",
                    f"4. Verify application routing change"
                ]
                expected = "User authentication resolves correctly with corresponding home redirection or error validation banner."
            elif category == 'Authorization':
                preconditions = "User session active or guest access state active."
                steps = [
                    f"1. Navigate directly to secured route {test_id}",
                    f"2. Inspect console and local storage state",
                    f"3. Verify route guard behavior"
                ]
                expected = "Route guard deters unauthorized navigation, redirects to onboarding / login."
            elif category == 'Navigation':
                steps = [
                    f"1. Open main dashboard",
                    f"2. Tap tab index associated with navigation check {i}",
                    f"3. Verify URI route path matches active tab"
                ]
                expected = "Tab changes seamlessly with high performance and updates history state correctly."
            elif category == 'UI Validation':
                steps = [
                    f"1. View rendering elements in module {prefix}",
                    f"2. Compare computed CSS layout parameters against design requirements",
                    f"3. Verify alignment and boundaries"
                ]
                expected = "Layout matches NutriFit green design system without visual overflows or pixel misalignments."
            elif category == 'Forms':
                steps = [
                    f"1. Trigger form visibility for test case {test_id}",
                    f"2. Input test variables into form fields",
                    f"3. Submit form and verify validations"
                ]
                expected = "Form accepts compliant data, flags incorrect entries, and executes successful submission."
            elif category == 'CRUD Operations':
                steps = [
                    f"1. Query tracker list or address inventory",
                    f"2. Create/Update/Delete item details for CRUD case {i}",
                    f"3. Verify persistent storage update"
                ]
                expected = "Operation reflects immediately on user interface and local/Supabase storage."
            elif category == 'Input Validation':
                steps = [
                    f"1. Select validation input field",
                    f"2. Type edge-case characters or boundary values",
                    f"3. Click submit"
                ]
                expected = "Field blocks non-compliant characters or renders validation warning toast."
            elif category == 'Error Handling':
                steps = [
                    f"1. Simulates connection loss or service exception",
                    f"2. Trigger target action",
                    f"3. Verify screen response"
                ]
                expected = "Graceful error fallback alerts are shown, preventing app crash."
            elif category == 'Session Management':
                steps = [
                    f"1. Perform session state check {i}",
                    f"2. Close or reload browser tab context",
                    f"3. Verify authentication state retention"
                ]
                expected = "Session behaves as configured, maintaining login profile safely."
            elif category == 'File Upload':
                steps = [
                    f"1. Click avatar/upload element",
                    f"2. Select target dummy test file {i}",
                    f"3. Confirm upload completes"
                ]
                expected = "System checks file, uploads if valid, or blocks with proper warning."
            elif category == 'Accessibility':
                steps = [
                    f"1. Scan DOM structure of active screen",
                    f"2. Inspect elements for ARIA tags, tab indexes, alt tags",
                    f"3. Check compliance score"
                ]
                expected = "Screen layout satisfies accessibility criteria for screen reader support."
            elif category == 'Responsive Design':
                steps = [
                    f"1. Resize browser window to viewport width associated with check {i}",
                    f"2. Verify grid items wrap cleanly",
                    f"3. Check for overflows"
                ]
                expected = "UI shifts cleanly to suit viewport dimensions without cropping content."
            elif category == 'Performance Smoke Tests':
                steps = [
                    f"1. Measure startup load metrics or tab transition speeds",
                    f"2. Record results",
                    f"3. Verify against performance threshold"
                ]
                expected = "Action executes smoothly within defined duration limit."
            else: # Regression
                steps = [
                    f"1. Execute regression check {i} across shop cart onboarding",
                    f"2. Compare outcome state with historical baseline"
                ]
                expected = "Existing feature performs correctly without newly introduced code conflicts."

            test_cases.append({
                'id': test_id,
                'category': category,
                'priority': priority,
                'preconditions': preconditions,
                'steps': '\n'.join(steps),
                'expected': expected,
                'name': f"Verify {category.lower()} scenario check {i:03d}",
                'actual': '',
                'status': 'Pending',
                'duration': 0.0,
                'failure_reason': ''
            })

    return test_cases

# Base URL constant lookup fallback
from automation.config.settings import BASE_URL
