import os

BASE_URL = os.environ.get('BASE_URL', 'http://localhost:8081/').rstrip('/') + '/'
IMPLICIT_WAIT = int(os.environ.get('IMPLICIT_WAIT', '10'))
EXPLICIT_WAIT = int(os.environ.get('EXPLICIT_WAIT', '15'))
HEADLESS = os.environ.get('HEADLESS', 'true').lower() == 'true'
BROWSER = os.environ.get('BROWSER', 'chrome').lower()

SCREENSHOT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'reports', 'Screenshots')
LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'reports', 'Logs')
EXCEL_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'reports', 'Excel')
HTML_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'reports', 'HTML')
JSON_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'reports', 'JSON')
SUMMARY_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'reports', 'Summary')

# Create directories if they do not exist
for d in [SCREENSHOT_DIR, LOG_DIR, EXCEL_DIR, HTML_DIR, JSON_DIR, SUMMARY_DIR]:
    os.makedirs(d, exist_ok=True)
