import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class BaseConfig:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-change-me")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "jwt-secret-change-me")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(seconds=int(os.getenv("JWT_ACCESS_TOKEN_EXPIRES", 3600)))
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(seconds=int(os.getenv("JWT_REFRESH_TOKEN_EXPIRES", 2592000)))

    # Redis
    REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # OTP
    OTP_EXPIRY_SECONDS = int(os.getenv("OTP_EXPIRY_SECONDS", 300))
    OTP_LENGTH = int(os.getenv("OTP_LENGTH", 6))

    # External Mock APIs
    SWIGGY_API_BASE = os.getenv("SWIGGY_API_BASE", "https://mock.swiggy.api")
    ZOMATO_API_BASE = os.getenv("ZOMATO_API_BASE", "https://mock.zomato.api")
    DRIVING_LICENSE_API = os.getenv("DRIVING_LICENSE_API", "https://mock.sarathi.api")

    RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID", "rzp_test_mock")
    RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET", "mock_secret")


class DevelopmentConfig(BaseConfig):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/gig_insurance"
    )


class TestingConfig(BaseConfig):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"


class ProductionConfig(BaseConfig):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")


config_map = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
}


def get_config():
    env = os.getenv("FLASK_ENV", "development")
    return config_map.get(env, DevelopmentConfig)