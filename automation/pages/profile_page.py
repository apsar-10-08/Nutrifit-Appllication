from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class ProfilePage(BasePage):
    EDIT_DETAILS_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Edit Onboarding') or contains(text(), 'Edit Onboarding')]")
    LOGOUT_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Logout') or contains(text(), 'Logout')]")
    MY_ORDERS_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'My Orders') or contains(text(), 'My Orders')]")

    def edit_onboarding(self):
        self.click(self.EDIT_DETAILS_BUTTON)

    def trigger_logout(self):
        self.click(self.LOGOUT_BUTTON)

    def open_my_orders(self):
        self.click(self.MY_ORDERS_BUTTON)
