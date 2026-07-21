from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class DashboardPage(BasePage):
    TODAY_PLAN_CARD = (By.XPATH, "//*[contains(@aria-label, 'Today Plan') or contains(text(), 'Today Plan')]")
    TRACKERS_TAB_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Trackers') or contains(text(), 'Trackers')]")
    SHOP_TAB_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Shop') or contains(text(), 'Shop')]")
    PROFILE_TAB_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Profile') or contains(text(), 'Profile')]")
    AI_TRAINER_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'AI Trainer') or contains(text(), 'AI')]")

    def go_to_trackers(self):
        self.click(self.TRACKERS_TAB_BUTTON)

    def go_to_shop(self):
        self.click(self.SHOP_TAB_BUTTON)

    def go_to_profile(self):
        self.click(self.PROFILE_TAB_BUTTON)
