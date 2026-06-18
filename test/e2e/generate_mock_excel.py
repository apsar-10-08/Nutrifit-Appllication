import openpyxl
import os
from datetime import datetime

def generate_mock_report():
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "E2E Test Results"
    ws.append(["Step", "Status", "Timestamp", "Error/Details"])

    steps = [
        "Initialize Driver & Launch App",
        "Splash Screen -> Login Screen",
        "Navigate to Sign Up Screen",
        "Fill Sign Up Form and Submit",
        "Onboarding - Goal Selection",
        "Onboarding - Gender Selection",
        "Onboarding - Age Input",
        "Onboarding - Height Input",
        "Onboarding - Weight Input",
        "Onboarding - Food Preference",
        "Onboarding - Workout Location",
        "Verify Dashboard Home Tab",
        "Dashboard - Plans Tab Verified",
        "Dashboard - Trackers Tab Verified",
        "Dashboard - Shop Tab & Add to Cart",
        "Cart Screen & Checkout Verified",
        "Profile Tab & Logout Verified"
    ]

    for step in steps:
        ws.append([step, "Passed (Mock)", datetime.now().isoformat(), ""])

    # Ensure test directory exists
    report_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../'))
    if not os.path.exists(report_dir):
        os.makedirs(report_dir)
        
    file_path = os.path.join(report_dir, 'A_to_Z_Test_Report.xlsx')
    wb.save(file_path)
    print(f"Generated comprehensive mock Excel report at: {file_path}")

if __name__ == '__main__':
    generate_mock_report()
