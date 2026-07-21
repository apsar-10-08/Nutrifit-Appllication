from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class ShopPage(BasePage):
    # Tab filters
    GNC_FILTER = (By.XPATH, "//*[contains(@aria-label, 'GNC') or text()='GNC']")
    ADD_TO_CART_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Add') or text()='Add']")
    ORDER_NOW_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Order Now') or text()='Order Now']")
    CART_ICON = (By.XPATH, "//*[contains(@aria-label, 'shopping_cart') or @role='button']")

    # Checkout fields
    NAME_FIELD = (By.XPATH, "//input[contains(@aria-label, 'Full Name') or contains(@label, 'Name')]")
    MOBILE_FIELD = (By.XPATH, "//input[contains(@aria-label, 'Mobile') or contains(@type, 'phone')]")
    HOUSE_FIELD = (By.XPATH, "//input[contains(@aria-label, 'House') or contains(@aria-label, 'Flat')]")
    STREET_FIELD = (By.XPATH, "//input[contains(@aria-label, 'Street')]")
    LANDMARK_FIELD = (By.XPATH, "//input[contains(@aria-label, 'Landmark')]")
    CITY_FIELD = (By.XPATH, "//input[contains(@aria-label, 'City')]")
    DISTRICT_FIELD = (By.XPATH, "//input[contains(@aria-label, 'District')]")
    STATE_FIELD = (By.XPATH, "//input[contains(@aria-label, 'State')]")
    PINCODE_FIELD = (By.XPATH, "//input[contains(@aria-label, 'Pincode') or contains(@type, 'number')]")
    INSTRUCTIONS_FIELD = (By.XPATH, "//input[contains(@aria-label, 'Instructions')]")

    # Checkout operations
    ADD_NEW_ADDRESS_CHIP = (By.XPATH, "//*[contains(@aria-label, 'Add New Address') or text()='+ Add New Address']")
    PLACE_ORDER_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Place Order') or text()='Place Order']")
    COD_PAYMENT_RADIO = (By.XPATH, "//*[contains(@aria-label, 'Cash on Delivery') or contains(text(), 'Cash on Delivery')]")

    # Order tracking
    MY_ORDERS_LINK = (By.XPATH, "//*[contains(@aria-label, 'My Orders') or text()='My Orders']")
    VIEW_DETAILS_LINK = (By.XPATH, "//*[contains(@aria-label, 'View Order Details') or text()='View Order Details']")
    CANCEL_ORDER_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Cancel Order') or text()='Cancel Order']")
    BUY_AGAIN_BUTTON = (By.XPATH, "//*[contains(@aria-label, 'Buy Again') or text()='Buy Again']")

    def fill_address(self, name, mobile, house, street, city, district, state, pincode):
        self.type_text(self.NAME_FIELD, name)
        self.type_text(self.MOBILE_FIELD, mobile)
        self.type_text(self.HOUSE_FIELD, house)
        self.type_text(self.STREET_FIELD, street)
        self.type_text(self.CITY_FIELD, city)
        self.type_text(self.DISTRICT_FIELD, district)
        self.type_text(self.STATE_FIELD, state)
        self.type_text(self.PINCODE_FIELD, pincode)

    def select_cod_and_place_order(self):
        self.click(self.COD_PAYMENT_RADIO)
        self.click(self.PLACE_ORDER_BUTTON)
