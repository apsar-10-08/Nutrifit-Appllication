import os
import openpyxl

SPECIFIED_FILES = [
    ("Selenium", "NutriFit_Selenium_Test_Report.xlsx"),
    ("Appium", "NutriFit_Appium_Test_Report.xlsx"),
    ("E2E", "NutriFit_E2E_Test_Report.xlsx"),
    ("Functional", "NutriFit_Functional_Test_Report.xlsx"),
    ("Load", "NutriFit_Load_Test_Report.xlsx"),
    ("Vulnerability", "NutriFit_Vulnerability_Test_Report.xlsx")
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
    total_duplicates = 0
    total_missing = 0
    grand_total_cases = 0
    file_counts = {}

    print("=== STARTING RIGOROUS VALIDATION OF ALL 6 EXCEL WORKBOOKS (400 CASES EACH) ===\n")

    for cat_label, filename in SPECIFIED_FILES:
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
        file_counts[cat_label] = tc_count

        if tc_count != 400:
            print(f"ERROR: {filename} contains {tc_count} test cases (Expected: 400)")
            total_missing += abs(400 - tc_count)
            assert tc_count == 400, f"Expected 400 test cases in {filename}, got {tc_count}"

        expected_ids = {f"TC-{i:03d}" for i in range(1, 401)}
        ids_in_file = set()
        duplicates_in_file = 0

        for r_idx, row in enumerate(data_rows, start=2):
            tc_id = row[0]
            status = row[12]

            if tc_id in ids_in_file:
                duplicates_in_file += 1
            else:
                ids_in_file.add(tc_id)

            assert status == "Not Executed", f"Invalid status '{status}' for {tc_id} in {filename}. Must be 'Not Executed'"

        missing_ids = expected_ids - ids_in_file
        total_duplicates += duplicates_in_file
        total_missing += len(missing_ids)

        assert duplicates_in_file == 0, f"Found {duplicates_in_file} duplicate IDs in {filename}"
        assert len(missing_ids) == 0, f"Missing IDs in {filename}: {missing_ids}"

        grand_total_cases += tc_count

    validation_passed = (
        grand_total_cases == 2400 and
        total_duplicates == 0 and
        total_missing == 0 and
        all(c == 400 for c in file_counts.values())
    )

    print("\n==================================================")
    for cat_label, _ in SPECIFIED_FILES:
        print(f"{cat_label}: {file_counts[cat_label]}")
    print(f"TOTAL: {grand_total_cases}")
    print(f"Duplicates: {total_duplicates}")
    print(f"Missing: {total_missing}")
    print(f"Validation: {'PASSED' if validation_passed else 'FAILED'}")
    print("==================================================")

    if not validation_passed:
        raise ValueError("Validation failed! Not all workbooks contain exactly 400 unique test cases.")

if __name__ == "__main__":
    verify_all_workbooks()
