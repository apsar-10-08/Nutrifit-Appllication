const { remote } = require('webdriverio');
const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

async function runTest() {
    console.log('Starting Appium Test...');
    
    // Initialize Excel Workbook
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('E2E Test Results');
    worksheet.columns = [
        { header: 'Step', key: 'step', width: 40 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Timestamp', key: 'timestamp', width: 30 },
        { header: 'Error/Details', key: 'error', width: 50 },
    ];

    function logStep(stepName, status, error = '') {
        const time = new Date().toISOString();
        console.log(`[${status}] ${stepName} at ${time}`);
        worksheet.addRow({ step: stepName, status, timestamp: time, error });
    }

    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:app': path.resolve(__dirname, '../../build/app/outputs/flutter-apk/app-debug.apk'),
        'appium:autoGrantPermissions': true,
        'appium:newCommandTimeout': 300,
    };

    const wdioOptions = {
        hostname: '127.0.0.1',
        port: 4723,
        path: '/',
        logLevel: 'error',
        capabilities,
    };

    let driver;
    try {
        driver = await remote(wdioOptions);
        logStep('Initialize Driver & Launch App', 'Passed');

        // Wait helper
        const waitAndClick = async (selector, timeout = 10000) => {
            const el = await driver.$(selector);
            await el.waitForDisplayed({ timeout });
            await el.click();
        };

        const waitAndSetValue = async (selector, value, timeout = 10000) => {
            const el = await driver.$(selector);
            await el.waitForDisplayed({ timeout });
            await el.click();
            await el.clearValue();
            await el.setValue(value);
            // Hide keyboard if it obscures buttons
            if (await driver.isKeyboardShown()) {
                await driver.hideKeyboard();
            }
        };

        const waitForElement = async (selector, timeout = 10000) => {
            const el = await driver.$(selector);
            await el.waitForDisplayed({ timeout });
        };

        // Splash Screen and Login Load
        try {
            await waitForElement('//*[@text="Login" or @content-desc="Login"]', 15000);
            logStep('Splash Screen -> Login Screen', 'Passed');
        } catch (e) {
            logStep('Splash Screen -> Login Screen', 'Failed', e.message);
            throw e;
        }

        // Navigate to Sign Up
        try {
            await waitAndClick('//*[@text="Sign Up" or @content-desc="Sign Up"]');
            await waitForElement('//*[@text="Create your NutriFit account" or @content-desc="Create your NutriFit account"]', 5000);
            logStep('Navigate to Sign Up Screen', 'Passed');
        } catch (e) {
            logStep('Navigate to Sign Up Screen', 'Failed', e.message);
            throw e;
        }

        // Fill Sign Up Form
        try {
            // Note: In Flutter, TextFields might have hint text mapped to android 'text' or 'content-desc'.
            // Let's use class android.widget.EditText
            const inputs = await driver.$$('android.widget.EditText');
            if (inputs.length >= 3) {
                await inputs[0].setValue('Test User');
                await inputs[1].setValue(`test${Date.now()}@example.com`);
                await inputs[2].setValue('password123');
                if (await driver.isKeyboardShown()) {
                    await driver.hideKeyboard();
                }
            } else {
                throw new Error("Could not find all 3 EditText fields for signup");
            }
            
            // Wait a bit for flutter to process inputs
            await driver.pause(1000);
            
            // Click Sign Up button
            await waitAndClick('//android.widget.Button[@content-desc="Sign Up" or @text="Sign Up"]');
            logStep('Fill Sign Up Form and Submit', 'Passed');
        } catch (e) {
            logStep('Fill Sign Up Form and Submit', 'Failed', e.message);
            throw e;
        }

        // Onboarding: Goal
        try {
            await waitForElement('//*[@text="Choose your fitness goal" or @content-desc="Choose your fitness goal"]', 15000);
            await waitAndClick('//*[@text="General Fitness" or @content-desc="General Fitness"]');
            logStep('Onboarding - Goal Selection', 'Passed');
        } catch (e) {
            logStep('Onboarding - Goal Selection', 'Failed', e.message);
            throw e;
        }

        // Onboarding: Gender
        try {
            await waitForElement('//*[@text="Select your gender" or @content-desc="Select your gender"]', 5000);
            await waitAndClick('//*[@text="Male" or @content-desc="Male"]');
            logStep('Onboarding - Gender Selection', 'Passed');
        } catch (e) {
            logStep('Onboarding - Gender Selection', 'Failed', e.message);
            throw e;
        }

        // Onboarding: Age
        try {
            await waitForElement('//*[@text="Enter your age" or @content-desc="Enter your age"]', 5000);
            const ageInput = await driver.$('android.widget.EditText');
            await ageInput.setValue('25');
            if (await driver.isKeyboardShown()) await driver.hideKeyboard();
            await waitAndClick('//android.widget.Button[@content-desc="Continue" or @text="Continue"]');
            logStep('Onboarding - Age Input', 'Passed');
        } catch (e) {
            logStep('Onboarding - Age Input', 'Failed', e.message);
            throw e;
        }

        // Onboarding: Height
        try {
            await waitForElement('//*[@text="Enter your height" or @content-desc="Enter your height"]', 5000);
            const hInput = await driver.$('android.widget.EditText');
            await hInput.setValue('175');
            if (await driver.isKeyboardShown()) await driver.hideKeyboard();
            await waitAndClick('//android.widget.Button[@content-desc="Continue" or @text="Continue"]');
            logStep('Onboarding - Height Input', 'Passed');
        } catch (e) {
            logStep('Onboarding - Height Input', 'Failed', e.message);
            throw e;
        }

        // Onboarding: Weight
        try {
            await waitForElement('//*[@text="Enter your weight" or @content-desc="Enter your weight"]', 5000);
            const wInput = await driver.$('android.widget.EditText');
            await wInput.setValue('70');
            if (await driver.isKeyboardShown()) await driver.hideKeyboard();
            await waitAndClick('//android.widget.Button[@content-desc="Continue" or @text="Continue"]');
            logStep('Onboarding - Weight Input', 'Passed');
        } catch (e) {
            logStep('Onboarding - Weight Input', 'Failed', e.message);
            throw e;
        }

        // Onboarding: Food
        try {
            await waitForElement('//*[@text="Choose food preference" or @content-desc="Choose food preference"]', 5000);
            await waitAndClick('//*[@text="Vegetarian" or @content-desc="Vegetarian"]');
            logStep('Onboarding - Food Preference', 'Passed');
        } catch (e) {
            logStep('Onboarding - Food Preference', 'Failed', e.message);
            throw e;
        }

        // Onboarding: Location
        try {
            await waitForElement('//*[@text="Where will you workout?" or @content-desc="Where will you workout?"]', 5000);
            await waitAndClick('//*[@text="Home Workout" or @content-desc="Home Workout"]');
            logStep('Onboarding - Workout Location', 'Passed');
        } catch (e) {
            logStep('Onboarding - Workout Location', 'Failed', e.message);
            throw e;
        }

        // Verify Dashboard
        try {
            await waitForElement('//*[@text="Dashboard" or @content-desc="Dashboard"]', 15000);
            logStep('Verify Dashboard Loaded', 'Passed');
        } catch (e) {
            logStep('Verify Dashboard Loaded', 'Failed', e.message);
            throw e;
        }

    } catch (err) {
        console.error('Test execution error:', err.message);
        logStep('Global Error', 'Failed', err.message);
    } finally {
        if (driver) {
            await driver.deleteSession();
        }
        
        // Save Excel file to the requested location
        const reportDir = path.resolve(__dirname, '../');
        if (!fs.existsSync(reportDir)){
            fs.mkdirSync(reportDir, { recursive: true });
        }
        const filePath = path.join(reportDir, 'A_to_Z_Test_Report.xlsx');
        await workbook.xlsx.writeFile(filePath);
        console.log(`Excel report generated at: ${filePath}`);
    }
}

runTest();
