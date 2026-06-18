import os
import time
from datetime import datetime
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
from appium.options.android import UiAutomator2Options
import openpyxl

def log_step(ws, step_name, status, error=""):
    timestamp = datetime.now().isoformat()
    print(f"[{status}] {step_name} at {timestamp}")
    ws.append([step_name, status, timestamp, str(error)])

def run_test():
    print("Starting Comprehensive Appium Test...")

    # Initialize Excel Workbook
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "E2E Test Results"
    ws.append(["Step", "Status", "Timestamp", "Error/Details"])

    # Path to the debug APK
    app_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../build/app/outputs/flutter-apk/app-debug.apk'))
    
    options = UiAutomator2Options()
    options.platform_name = 'Android'
    options.automation_name = 'UiAutomator2'
    options.app = app_path
    options.auto_grant_permissions = True
    options.new_command_timeout = 300

    driver = None
    try:
        print("Connecting to local Appium server at http://127.0.0.1:4723/...")
        # Start Appium session
        driver = webdriver.Remote('http://127.0.0.1:4723/', options=options)
        log_step(ws, 'Initialize Driver & Launch App', 'Passed')
        
        # Wait helper
        def wait_and_click(selector, by=AppiumBy.XPATH, timeout=10):
            driver.implicitly_wait(timeout)
            el = driver.find_element(by, selector)
            el.click()

        # 1. Splash Screen -> Login
        try:
            driver.implicitly_wait(15)
            driver.find_element(AppiumBy.XPATH, '//*[@text="Login" or @content-desc="Login"]')
            log_step(ws, 'Splash Screen -> Login Screen', 'Passed')
        except Exception as e:
            log_step(ws, 'Splash Screen -> Login Screen', 'Failed', e)
            raise

        # 2. Navigate to Sign Up
        try:
            wait_and_click('//*[@text="Sign Up" or @content-desc="Sign Up"]')
            driver.implicitly_wait(5)
            driver.find_element(AppiumBy.XPATH, '//*[@text="Create your NutriFit account" or @content-desc="Create your NutriFit account"]')
            log_step(ws, 'Navigate to Sign Up Screen', 'Passed')
        except Exception as e:
            log_step(ws, 'Navigate to Sign Up Screen', 'Failed', e)
            raise

        # 3. Fill Sign Up Form
        try:
            driver.implicitly_wait(5)
            inputs = driver.find_elements(AppiumBy.CLASS_NAME, 'android.widget.EditText')
            if len(inputs) >= 3:
                inputs[0].send_keys('Test User')
                inputs[1].send_keys(f'test{int(time.time())}@example.com')
                inputs[2].send_keys('password123')
                if driver.is_keyboard_shown():
                    driver.hide_keyboard()
            else:
                raise Exception("Could not find all 3 EditText fields for signup")
            
            time.sleep(1)
            wait_and_click('//android.widget.Button[@content-desc="Sign Up" or @text="Sign Up"]')
            log_step(ws, 'Fill Sign Up Form and Submit', 'Passed')
        except Exception as e:
            log_step(ws, 'Fill Sign Up Form and Submit', 'Failed', e)
            raise

        # 4. Onboarding - Goal
        try:
            driver.implicitly_wait(15)
            driver.find_element(AppiumBy.XPATH, '//*[@text="Choose your fitness goal" or @content-desc="Choose your fitness goal"]')
            wait_and_click('//*[@text="General Fitness" or @content-desc="General Fitness"]')
            log_step(ws, 'Onboarding - Goal Selection', 'Passed')
        except Exception as e:
            log_step(ws, 'Onboarding - Goal Selection', 'Failed', e)
            raise

        # 5. Onboarding - Gender
        try:
            driver.implicitly_wait(5)
            wait_and_click('//*[@text="Male" or @content-desc="Male"]')
            log_step(ws, 'Onboarding - Gender Selection', 'Passed')
        except Exception as e:
            log_step(ws, 'Onboarding - Gender Selection', 'Failed', e)
            raise

        # 6. Onboarding - Age Input
        try:
            driver.implicitly_wait(5)
            age_input = driver.find_element(AppiumBy.CLASS_NAME, 'android.widget.EditText')
            age_input.send_keys('25')
            if driver.is_keyboard_shown():
                driver.hide_keyboard()
            wait_and_click('//android.widget.Button[@content-desc="Continue" or @text="Continue"]')
            log_step(ws, 'Onboarding - Age Input', 'Passed')
        except Exception as e:
            log_step(ws, 'Onboarding - Age Input', 'Failed', e)
            raise

        # 7. Onboarding - Height Input
        try:
            driver.implicitly_wait(5)
            h_input = driver.find_element(AppiumBy.CLASS_NAME, 'android.widget.EditText')
            h_input.send_keys('175')
            if driver.is_keyboard_shown():
                driver.hide_keyboard()
            wait_and_click('//android.widget.Button[@content-desc="Continue" or @text="Continue"]')
            log_step(ws, 'Onboarding - Height Input', 'Passed')
        except Exception as e:
            log_step(ws, 'Onboarding - Height Input', 'Failed', e)
            raise

        # 8. Onboarding - Weight Input
        try:
            driver.implicitly_wait(5)
            w_input = driver.find_element(AppiumBy.CLASS_NAME, 'android.widget.EditText')
            w_input.send_keys('70')
            if driver.is_keyboard_shown():
                driver.hide_keyboard()
            wait_and_click('//android.widget.Button[@content-desc="Continue" or @text="Continue"]')
            log_step(ws, 'Onboarding - Weight Input', 'Passed')
        except Exception as e:
            log_step(ws, 'Onboarding - Weight Input', 'Failed', e)
            raise

        # 9. Onboarding - Food
        try:
            driver.implicitly_wait(5)
            wait_and_click('//*[@text="Vegetarian" or @content-desc="Vegetarian"]')
            log_step(ws, 'Onboarding - Food Preference', 'Passed')
        except Exception as e:
            log_step(ws, 'Onboarding - Food Preference', 'Failed', e)
            raise

        # 10. Onboarding - Location
        try:
            driver.implicitly_wait(5)
            wait_and_click('//*[@text="Home Workout" or @content-desc="Home Workout"]')
            log_step(ws, 'Onboarding - Workout Location', 'Passed')
        except Exception as e:
            log_step(ws, 'Onboarding - Workout Location', 'Failed', e)
            raise

        # 11. Verify Dashboard Home Tab
        try:
            driver.implicitly_wait(15)
            driver.find_element(AppiumBy.XPATH, '//*[@text="Dashboard" or @content-desc="Dashboard"]')
            driver.find_element(AppiumBy.XPATH, '//*[contains(@text, "Ready for") or contains(@content-desc, "Ready for")]')
            log_step(ws, 'Verify Dashboard Home Tab', 'Passed')
        except Exception as e:
            log_step(ws, 'Verify Dashboard Home Tab', 'Failed', e)
            raise

        # 12. Dashboard - Plans Tab
        try:
            wait_and_click('//*[@text="Plans" or @content-desc="Plans"]')
            driver.implicitly_wait(5)
            driver.find_element(AppiumBy.XPATH, '//*[@text="Weekly Workout Split" or @content-desc="Weekly Workout Split"]')
            wait_and_click('//*[@text="Monday" or @content-desc="Monday"]') # Expand a card
            log_step(ws, 'Dashboard - Plans Tab Verified', 'Passed')
        except Exception as e:
            log_step(ws, 'Dashboard - Plans Tab Verified', 'Failed', e)
            raise

        # 13. Dashboard - Trackers Tab
        try:
            wait_and_click('//*[@text="Trackers" or @content-desc="Trackers"]')
            driver.implicitly_wait(5)
            # Add Water
            wait_and_click('//*[@text="+250 ml" or @content-desc="+250 ml"]')
            # Add Steps
            wait_and_click('//*[@text="+500" or @content-desc="+500"]')
            # Toggle Habit
            wait_and_click('//*[@text="Drink 3L water" or @content-desc="Drink 3L water"]')
            log_step(ws, 'Dashboard - Trackers Tab Verified', 'Passed')
        except Exception as e:
            log_step(ws, 'Dashboard - Trackers Tab Verified', 'Failed', e)
            raise

        # 14. Dashboard - Shop Tab & Add to Cart
        try:
            wait_and_click('//*[@text="Shop" or @content-desc="Shop"]')
            driver.implicitly_wait(5)
            # Find the first 'Add' button to add a product to the cart
            wait_and_click('//*[@text="Add" or @content-desc="Add"]')
            log_step(ws, 'Dashboard - Shop Tab & Add to Cart', 'Passed')
        except Exception as e:
            log_step(ws, 'Dashboard - Shop Tab & Add to Cart', 'Failed', e)
            raise

        # 15. Cart Screen & Checkout
        try:
            # We can click the cart icon via content-desc if not text, or we can just tap the text that says '(Tap to view Cart)'
            wait_and_click('//*[contains(@text, "Tap to view Cart") or contains(@content-desc, "Tap to view Cart")]')
            driver.implicitly_wait(5)
            driver.find_element(AppiumBy.XPATH, '//*[@text="My Cart" or @content-desc="My Cart"]')
            wait_and_click('//*[@text="Proceed to Checkout" or @content-desc="Proceed to Checkout"]')
            
            driver.implicitly_wait(5)
            # Click Done on Dialog
            wait_and_click('//*[@text="Done" or @content-desc="Done"]')
            log_step(ws, 'Cart Screen & Checkout Verified', 'Passed')
        except Exception as e:
            log_step(ws, 'Cart Screen & Checkout Verified', 'Failed', e)
            raise

        # 16. Dashboard - Profile Tab & Logout
        try:
            wait_and_click('//*[@text="Profile" or @content-desc="Profile"]')
            driver.implicitly_wait(5)
            driver.find_element(AppiumBy.XPATH, '//*[@text="Settings" or @content-desc="Settings"]')
            wait_and_click('//*[@text="Logout" or @content-desc="Logout"]')
            
            driver.implicitly_wait(5)
            driver.find_element(AppiumBy.XPATH, '//*[@text="Login" or @content-desc="Login"]')
            log_step(ws, 'Profile Tab & Logout Verified', 'Passed')
        except Exception as e:
            log_step(ws, 'Profile Tab & Logout Verified', 'Failed', e)
            raise

    except Exception as err:
        print("Test execution error:", err)
        log_step(ws, 'Global Error', 'Failed', err)
    finally:
        if driver:
            driver.quit()
        
        # Save Excel file to the requested location
        report_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../'))
        if not os.path.exists(report_dir):
            os.makedirs(report_dir)
        file_path = os.path.join(report_dir, 'A_to_Z_Test_Report.xlsx')
        wb.save(file_path)
        print(f"Excel report generated at: {file_path}")

if __name__ == '__main__':
    run_test()
