from typing import List, Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    PROJECT_NAME: str = "AgriChain AI Backend"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Firebase Admin SDK settings
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    FIREBASE_PROJECT_ID: Optional[str] = "agrichain-ai"
    FIREBASE_CLIENT_EMAIL: Optional[str] = None
    FIREBASE_PRIVATE_KEY: Optional[str] = None
    FIREBASE_DATABASE_URL: Optional[str] = "https://agrichain-ai-default-rtdb.firebaseio.com"

    # AI / Gemini API
    GEMINI_API_KEY: Optional[str] = None

    # Maps API
    MAPS_API_KEY: Optional[str] = None

    # CORS
    ALLOWED_ORIGINS: List[str] = ["*"]

    # Security
    BYPASS_AUTH_FOR_DEMO: bool = True  # Allows hackathon judges / local demo mode without active Firebase project

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
