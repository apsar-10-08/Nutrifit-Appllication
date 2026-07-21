# NutriFit QA Specified 6-Category Excel Reports Documentation

Welcome to the **NutriFit QA Testing and Automation System** documentation. This directory contains all 6 specified Excel test case workbooks, executive summaries, and execution manuals.

---

## 📁 6 Specified Excel Workbooks (2,100 Total Test Cases)

```
testing-reports/
├── NutriFit_Selenium_Test_Report.xlsx       # 350 Selenium Web UI Test Cases
├── NutriFit_Appium_Test_Report.xlsx         # 350 Appium Android E2E Test Cases
├── NutriFit_E2E_Test_Report.xlsx            # 350 End-to-End Workflow Test Cases
├── NutriFit_Functional_Test_Report.xlsx     # 350 Functional & Integration Test Cases
├── NutriFit_Load_Test_Report.xlsx           # 350 Load & Performance Test Cases
├── NutriFit_Vulnerability_Test_Report.xlsx # 350 Safe Security & Config Test Cases
├── category-reports-summary.md              # 2,100 Test Cases Category Summary
└── README.md                                # Documentation Guide (This file)
```

---

## 📊 Summary of 6 Specified Excel Workbooks

Each workbook contains **350 unique test cases** defaulting to status **`Not Executed`** and covers all 22 NutriFit modules across 16 standard columns:

- `Test Case ID` | `Module` | `Scenario` | `Test Title` | `Objective` | `Preconditions` | `Detailed Test Steps` | `Test Data` | `Expected Result` | `Actual Result` | `Priority` | `Severity` | `Status` | `Automation Script Path` | `Evidence Path` | `Remarks`

---

## 🛠️ How to Regenerate & Verify

To generate or update all 6 specified Excel files programmatically:

```bash
python generate_specified_6_reports.py
python verify_specified_6_reports.py
```
