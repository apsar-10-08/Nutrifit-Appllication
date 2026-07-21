import os
import openpyxl

SPECIFIED_FILES = [
    "NutriFit_Selenium_Test_Report.xlsx",
    "NutriFit_Appium_Test_Report.xlsx",
    "NutriFit_E2E_Test_Report.xlsx",
    "NutriFit_Functional_Test_Report.xlsx",
    "NutriFit_Load_Test_Report.xlsx",
    "NutriFit_Vulnerability_Test_Report.xlsx"
]

REQUIRED_MODULES = [
    "Authentication", "Dashboard", "Workout", "Diet", "Budget Diet",
    "Stretching", "Water Tracker", "Sleep Tracker", "Step Tracker", "AI Trainer",
    "Shop", "Cart", "Checkout", "Address", "Orders", "Profile",
    "Notifications", "Settings", "Localization", "Supabase Integration",
    "Responsive Web", "Android UI"
]

EXPECTED_COLUMNS = [
    "Test Case ID", "Module", "Scenario", "Test Title", "Objective",
    "Preconditions", "Detailed Test Steps", "Test Data", "Expected Result",
    "Actual Result", "Priority", "Severity", "Status",
    "Automation Script Path", "Evidence Path", "Remarks"
]

def verify_all_workbooks():
    grand_total_cases = 0
    print("=== STARTING RIGOROUS VALIDATION OF ALL 6 SPECIFIED EXCEL WORKBOOKS ===\n")

    for filename in SPECIFIED_FILES:
        rep_path = os.path.join("testing-reports", filename)
        assert os.path.exists(rep_path), f"File missing in testing-reports/: {rep_path}"
        assert os.path.exists(filename), f"File missing in root: {filename}"

        wb = openpyxl.load_workbook(rep_path, data_only=False)
        assert "Summary Dashboard" in wb.sheetnames, f"Sheet 'Summary Dashboard' missing in {filename}"
        assert "Detailed Test Cases" in wb.sheetnames, f"Sheet 'Detailed Test Cases' missing in {filename}"
        assert "Execution Evidence" in wb.sheetnames, f"Sheet 'Execution Evidence' missing in {filename}"

        ws_det = wb["Detailed Test Cases"]
        rows = list(ws_det.iter_rows(values_only=True))

        header = rows[0]
        data_rows = rows[1:]

        assert list(header) == EXPECTED_COLUMNS, f"Columns mismatch in {filename}.\nExpected: {EXPECTED_COLUMNS}\nGot: {list(header)}"

        tc_count = len(data_rows)
        print(f"File '{filename}': Found {tc_count} test cases.")
        assert tc_count == 350, f"Expected 350 test cases in {filename}, got {tc_count}"

        ids_in_file = set()
        modules_in_file = set()

        for r_idx, row in enumerate(data_rows, start=2):
            tc_id = row[0]
            mod = row[1]
            status = row[12]

            assert tc_id not in ids_in_file, f"Duplicate Test ID '{tc_id}' found at row {r_idx} in {filename}"
            ids_in_file.add(tc_id)
            modules_in_file.add(mod)

            assert status == "Not Executed", f"Invalid status '{status}' for {tc_id} in {filename}. Must be 'Not Executed'"

        assert len(ids_in_file) == 350, f"Unique ID count mismatch in {filename}"
        grand_total_cases += tc_count

        missing_mods = [m for m in REQUIRED_MODULES if m not in modules_in_file]
        print(f"   -> Unique IDs: {len(ids_in_file)} | Modules Covered: {len(modules_in_file)}/22 | Status: All 'Not Executed'")
        assert len(missing_mods) == 0, f"Missing modules in {filename}: {missing_mods}"

    print("\n==================================================")
    print(f"VALIDATION SUCCESSFUL: TOTAL FILES = {len(SPECIFIED_FILES)}")
    print(f"GRAND TOTAL TEST CASES ACROSS ALL 6 WORKBOOKS = {grand_total_cases}")
    print("ALL 6 EXCEL WORKBOOKS VALIDATED PERFECTLY WITH ZERO ERRORS.")
    print("==================================================")

if __name__ == "__main__":
    verify_all_workbooks()
