import logging
import os
from typing import Optional, Dict, Any
import firebase_admin
from firebase_admin import credentials, firestore, db as rtdb, auth

from app.config import settings

logger = logging.getLogger("agrichain.firebase")

_firebase_app: Optional[firebase_admin.App] = None
_firestore_client = None
_is_mock_mode: bool = False


def initialize_firebase():
    global _firebase_app, _firestore_client, _is_mock_mode
    if _firebase_app is not None:
        return

    try:
        cred = None
        # 1. Try file path
        if settings.FIREBASE_CREDENTIALS_PATH and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
            logger.info(f"Initializing Firebase from credentials file: {settings.FIREBASE_CREDENTIALS_PATH}")
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        # 2. Try environment variables
        elif settings.FIREBASE_CLIENT_EMAIL and settings.FIREBASE_PRIVATE_KEY:
            logger.info("Initializing Firebase from environment credentials")
            private_key = settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n")
            cred_dict = {
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "private_key": private_key,
                "token_uri": "https://oauth2.googleapis.com/token",
            }
            cred = credentials.Certificate(cred_dict)

        if cred:
            _firebase_app = firebase_admin.initialize_app(cred, {
                "databaseURL": settings.FIREBASE_DATABASE_URL
            })
            _firestore_client = firestore.client()
            logger.info("Firebase Admin SDK successfully initialized.")
        else:
            logger.warning("No Firebase credentials provided. Running in Demo/Mock Mode.")
            _is_mock_mode = True

    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}. Falling back to Demo Mode.")
        _is_mock_mode = True


def get_firestore():
    global _firestore_client
    if _is_mock_mode:
        return None
    if _firestore_client is None:
        initialize_firebase()
    return _firestore_client


def verify_firebase_token(token: str) -> Dict[str, Any]:
    """Verifies Firebase ID token from Authorization header."""
    if _is_mock_mode or settings.BYPASS_AUTH_FOR_DEMO:
        # In demo/mock mode or test mode, return a simulated admin/transporter token
        return {
            "uid": "demo_user_001",
            "email": "demo@agrichain.ai",
            "role": "admin",
            "name": "Demo Admin User"
        }
    try:
        decoded = auth.verify_id_token(token)
        return decoded
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        raise ValueError(f"Invalid Firebase ID Token: {e}")


def update_rtdb_shipment_telemetry(shipment_id: str, data: dict):
    """Writes real-time GPS and sensor stream to Firebase RTDB."""
    if _is_mock_mode:
        logger.debug(f"[Mock RTDB] Written to live/shipments/{shipment_id}: {data}")
        return True
    try:
        ref = rtdb.reference(f"live/shipments/{shipment_id}")
        ref.update(data)
        return True
    except Exception as e:
        logger.error(f"RTDB write error: {e}")
        return False
