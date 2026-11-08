import os
from pathlib import Path

from dotenv import load_dotenv

# Load .env from A2/ repo root (parent of app/)
_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(_ROOT / ".env")


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-only-change-me")
    MYSQL_HOST = os.getenv("MYSQL_HOST", "127.0.0.1")
    MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
    MYSQL_USER = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
    MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "ahamove_a2")
    DEBUG = os.getenv("FLASK_DEBUG", "1") == "1"
