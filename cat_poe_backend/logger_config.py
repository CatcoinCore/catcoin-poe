import logging
import os
from datetime import datetime

class DailyFileHandler(logging.FileHandler):
    """
    Custom handler that writes logs to a file named with the current date.
    Switches to a new file automatically when the date changes.
    Example: backend_log_2024-02-06.txt
    """
    def __init__(self, log_dir):
        self.log_dir = log_dir
        self.current_date = datetime.now().strftime("%Y-%m-%d")
        filename = self._get_filename()
        super().__init__(filename, encoding="utf-8")

    def _get_filename(self):
        return os.path.join(self.log_dir, f"backend_log_{self.current_date}.txt")

    def emit(self, record):
        # Check if date has changed
        new_date = datetime.now().strftime("%Y-%m-%d")
        if new_date != self.current_date:
            self.current_date = new_date
            # Close old stream and open new one
            if self.stream:
                self.stream.close()
            self.baseFilename = self._get_filename()
            self.stream = self._open()
        
        super().emit(record)

def setup_logging():
    """
    Configures logging to write to console and daily timestamped internal file.
    Logs are stored in the 'logs' directory.
    """
    log_dir = "logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Create formatters
    formatter = logging.Formatter(
        '%(asctime)s [%(levelname)s] %(name)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Root Logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    
    # Remove existing handlers to avoid duplicates on reloads
    if root_logger.handlers:
        root_logger.handlers.clear()

    # 1. Console Handler (Stdout)
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)

    # 2. Daily Log File Handler (Custom)
    file_handler = DailyFileHandler(log_dir)
    file_handler.setFormatter(formatter)
    root_logger.addHandler(file_handler)

    logging.info(f"Logging configured. Logs writing to {file_handler.baseFilename}")

# Call this if run directly for testing
if __name__ == "__main__":
    setup_logging()
    logging.info("Test log entry")
    logging.error("Test error entry")
