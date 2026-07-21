# NutriFit QA Testing & Report Documentation

Welcome to the **NutriFit QA Testing and Automation System** documentation. This directory contains all generated Excel test case workbooks, executive summaries, and execution manuals.

---

## 📁 Directory Contents & 6 Category Excel Reports

```
testing-reports/
├── Selenium_Web_Test_Cases.xlsx              # 350 Selenium Web UI Test Cases
├── Appium_Android_Test_Cases.xlsx            # 350 Appium Android E2E Test Cases
├── E2E_Test_Cases.xlsx                        # 350 End-to-End Workflow Test Cases
├── Functional_Test_Cases.xlsx                 # 350 Functional & Unit Test Cases
├── Load_Test_Cases.xlsx                       # 350 Load & Performance Test Cases
├── Safe_Code_and_Configuration_Checks.xlsx   # 350 Safe Security & Config Test Cases
├── NutriFit_360_Test_Cases.xlsx              # 360 Combined Master Test Cases
├── category-reports-summary.md                # 2,100 Test Cases Category Summary
├── test-summary.md                            # Executive QA Report
└── README.md                                  # Documentation Guide (This file)
```

---

## 📊 Summary of Category Excel Workbooks (Total 2,100 Test Cases)

Each file contains **350 unique test cases** defaulting to status **`Not Executed`** and covers all 22 NutriFit modules across 14 standard columns:

- `Test Case ID` | `Module` | `Test Scenario` | `Test Title` | `Objective` | `Preconditions` | `Test Steps` | `Test Data` | `Expected Result` | `Actual Result` | `Priority` | `Severity` | `Status` | `Remarks`

---

## 🛠️ How to Regenerate Category Workbooks

To generate or update all 6 category Excel files programmatically:

```bash
python generate_category_excel_reports.py
python verify_category_excel_reports.py
```


---

## 🚦 Permitted Status Values & Lifecycle Rules

The Excel report strictly enforces the following 5 status values:

- **`Not Executed`** *(Initial Baseline)*: Test case generated and ready for execution.
- **`Passed`**: Test executed and all assertions succeeded.
- **`Failed`**: Test executed and one or more assertions failed.
- **`Skipped`**: Test skipped due to environment configuration or prerequisite filter.
- **`Blocked`**: Test execution prevented due to a dependent blocking issue.

> **Important**: Unexecuted test cases are never marked as Passed. Initially, all 360 test cases are set to `Not Executed`.

---

## ⚙️ CI/CD GitHub Actions Integration

The workflow file `.github/workflows/nutrifit-testing-report.yml` automatically:
- Executes `flutter analyze` and `flutter test`.
- Builds the Flutter Web application (`flutter build web`).
- Runs `generate_360_test_cases.py` to keep test reports up to date.
- Uploads `NutriFit_360_Test_Cases.xlsx` and the `testing-reports/` directory as workflow artifacts.
- Renders the test totals and summary metrics directly in `$GITHUB_STEP_SUMMARY`.
