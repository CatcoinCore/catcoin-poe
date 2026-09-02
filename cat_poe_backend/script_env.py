"""Load backend `.env` for standalone maintenance scripts."""
from pathlib import Path

from dotenv import load_dotenv

_backend_root = Path(__file__).resolve().parent
load_dotenv(_backend_root / ".env")
