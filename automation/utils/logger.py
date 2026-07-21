import os
import logging
from datetime import datetime
from automation.config import settings

class Logger:
    _initialized = False

    @classmethod
    def setup(cls):
        if cls._initialized:
            return
        
        log_file = os.path.join(settings.LOG_DIR, 'automation.log')
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s [%(levelname)s] %(message)s',
            handlers=[
                logging.FileHandler(log_file, mode='w', encoding='utf-8'),
                logging.StreamHandler()
            ]
        )
        cls._initialized = True

    @classmethod
    def info(cls, msg):
        cls.setup()
        logging.info(msg)

    @classmethod
    def warning(cls, msg):
        cls.setup()
        logging.warning(msg)

    @classmethod
    def error(cls, msg):
        cls.setup()
        logging.error(msg)
