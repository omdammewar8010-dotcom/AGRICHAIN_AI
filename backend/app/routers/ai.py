from fastapi import APIRouter, Depends
from typing import Dict, Any

from app.models.ai import AIChatRequest, AIChatResponse
from app.services.gemini_service import gemini_assistant
from app.auth.dependencies import get_current_user

router = APIRouter(prefix="/ai", tags=["AI Assistant (Gemini)"])


@router.post("/chat", response_model=AIChatResponse)
async def chat_with_assistant(
    request: AIChatRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Interacts with the Gemini AgriChain diagnostic assistant, grounded with live shipment context.
    """
    return await gemini_assistant.answer_query(request)
