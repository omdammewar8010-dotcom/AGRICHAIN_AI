from typing import Dict, Any, List
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.firebase import verify_firebase_token
from app.config import settings

security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> Dict[str, Any]:
    """Extracts and verifies Firebase ID Token from the Authorization: Bearer <token> header."""
    if not credentials:
        if settings.BYPASS_AUTH_FOR_DEMO:
            return {
                "uid": "demo_admin_user",
                "email": "demo@agrichain.ai",
                "role": "admin",
                "name": "Demo Admin"
            }
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization Bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    try:
        user = verify_firebase_token(token)
        return user
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


def require_role(allowed_roles: List[str]):
    """Role-Based Access Control dependency factory."""
    async def role_checker(current_user: Dict[str, Any] = Depends(get_current_user)):
        user_role = current_user.get("role", "farmer")
        if user_role == "admin" or user_role in allowed_roles:
            return current_user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access forbidden: User role '{user_role}' not authorized. Requires one of {allowed_roles}."
        )
    return role_checker
