# NutriFit QA Testing & Report Documentation

Welcome to the **NutriFit QA Testing and Automation System** documentation. This directory contains the complete quality assurance test case report workbook, summary analysis, execution guidelines, and automated report generation scripts.

---

## 📁 Directory Contents

```
testing-reports/
├── NutriFit_360_Test_Cases.xlsx  # 360-Test Case Excel Workbook (9 Sheets)
├── test-summary.md               # Executive Test Case Breakdown & Coverage Matrix
├── README.md                     # Technical Documentation (This file)
└── evidence/                     # Execution Screenshots & Evidence Artifacts (CI Generated)
```

---

## 📊 Excel Workbook Architecture (`NutriFit_360_Test_Cases.xlsx`)

The generated Excel workbook contains **9 structured worksheets**:

1. **`Test Summary`**: High-level executive dashboard featuring live Excel formula metrics (`COUNTIF`, `COUNTIFS`), KPI cards, Testing Type Breakdown table, and 37 Module Coverage table.
2. **`Selenium Tests`**: **100** structured test cases (`SEL-WEB-001` to `SEL-WEB-100`) covering Selenium Web UI, responsive layouts, forms, and browser interaction.
3. **`Appium E2E Tests`**: **90** structured test cases (`APP-AND-001` to `APP-AND-090`) covering native Android gestures, hardware back navigation, biometrics, dark mode, and permissions.
4. **`Flutter Tests`**: **60** structured test cases (`FLU-TST-001` to `FLU-TST-060`) covering Dart unit logic, model JSON parsing, Provider state management, and WidgetTester rendering.
5. **`Functional Tests`**: **50** structured test cases (`FUN-INT-001` to `FUN-INT-050`) covering end-to-end user workflows, multi-screen state sync, and Supabase database integration.
6. **`Load Tests`**: **30** structured test cases (`PER-LOD-001` to `PER-LOD-030`) covering REST API throughput, 60 FPS UI rendering, memory stability, and database latency under load.
7. **`Safe Vulnerability Checks`**: **30** structured test cases (`SEC-VUL-001` to `SEC-VUL-030`) covering passive security audits, secret isolation, OWASP compliance, and safe SQLi/XSS checks.
8. **`Failed Tests`**: Dedicated failure tracking view for instant review of failed test cases during execution runs.
9. **`Execution Evidence`**: Evidence log matrix linking Test Case IDs to screenshot file paths, execution timestamps, and CI artifact packages.

---

## 🛠️ How to Regenerate or Update the Report

To generate or update `NutriFit_360_Test_Cases.xlsx` programmatically:

1. Ensure Python 3.8+ and `openpyxl` are installed:
   ```bash
   pip install openpyxl
   ```

2. Run the generator script from the project root directory:
   ```bash
   python generate_360_test_cases.py
   ```

3. Validate the generated file using the verification script:
   ```bash
   python verify_360_test_cases.py
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
