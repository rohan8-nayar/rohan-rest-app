import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """Base configuration class"""

    SECRET_KEY = os.environ.get("SECRET_KEY") or "dev-secret-key-change-in-production"
    SQLALCHEMY_DATABASE_URI = (
        os.environ.get("DATABASE_URL")
        or "postgresql://postgres:postgres@localhost:5432/students_db"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    API_VERSION = os.environ.get("API_VERSION") or "v1"
    HOST = os.environ.get("HOST") or "0.0.0.0"
    PORT = int(os.environ.get("PORT") or 5000)


class DevelopmentConfig(Config):
    """Development configuration"""

    DEBUG = True
    FLASK_ENV = "development"


class ProductionConfig(Config):
    """Production configuration"""

    DEBUG = False
    FLASK_ENV = "production"


class TestingConfig(Config):
    """Testing configuration"""

    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    WTF_CSRF_ENABLED = False


# Configuration dictionary
config = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "testing": TestingConfig,
    "default": DevelopmentConfig,
}
