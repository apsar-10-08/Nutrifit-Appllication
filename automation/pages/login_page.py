from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class LoginPage(BasePage):
    EMAIL_INPUT = (By.XPATH, "//input[@type='email' or contains(@aria-label, 'Email')]")
    PASSWORD_INPUT = (By.XPATH, "//input[@type='password' or contains(@aria-label, 'Password')]")
    LOGIN_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Login') or contains(@aria-label, 'Sign In') or text()='Login']")
    SIGNUP_LINK = (By.XPATH, "//*[contains(@aria-label, 'Sign Up') or text()='Sign Up']")
    GOOGLE_LOGIN = (By.XPATH, "//*[contains(@aria-label, 'Google') or contains(text(), 'Google')]")

    def perform_login(self, email, password):
        self.type_text(self.EMAIL_INPUT, email)
        self.type_text(self.PASSWORD_INPUT, password)
        self.click(self.LOGIN_BUTTON)

    def trigger_google_login(self):
        self.click(self.GOOGLE_LOGIN)
