from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class TrackersPage(BasePage):
    ADD_WATER_BUTTON = (By.XPATH, "//*[contains(@aria-label, '+250') or text()='+250ml']")
    CUSTOM_WATER_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Custom') or text()='Custom']")
    WATER_LOG_FIELD = (By.XPATH, "//input[contains(@type, 'number')]")
    SLEEP_LOG_TILE = (By.XPATH, "//*[contains(@aria-label, 'Sleep') or contains(text(), 'Sleep')]")
    STEPS_LOG_TILE = (By.XPATH, "//*[contains(@aria-label, 'Steps') or contains(text(), 'Steps')]")
    ADD_STEP_BUTTON = (By.XPATH, "//*[contains(@aria-label, '+1000') or text()='+1000']")

    def add_water_quick(self):
        self.click(self.ADD_WATER_BUTTON)

    def log_steps_quick(self):
        self.click(self.ADD_STEP_BUTTON)
