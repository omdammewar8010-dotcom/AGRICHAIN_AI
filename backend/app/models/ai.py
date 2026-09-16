from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field


class ShipmentContext(BaseModel):
    batchId: Optional[str] = None
    shipmentId: Optional[str] = None
    cropName: Optional[str] = "Tomato"
    currentTemperature: Optional[float] = 22.0
    currentHumidity: Optional[float] = 68.0
    preferredTempMin: Optional[float] = 18.0
    preferredTempMax: Optional[float] = 22.0
    delayMinutes: Optional[float] = 0.0
    riskScore: Optional[float] = 24.0
    riskLevel: Optional[str] = "LOW"
    currentLocation: Optional[str] = "Kasara, Maharashtra"
    destination: Optional[str] = "Vashi APMC Market, Navi Mumbai"


class AIChatRequest(BaseModel):
    message: str = Field(..., description="User question or prompt for Gemini assistant")
    context: Optional[ShipmentContext] = Field(default_factory=ShipmentContext)
    conversationHistory: Optional[List[Dict[str, str]]] = Field(default_factory=list)


class AIChatResponse(BaseModel):
    reply: str
    keyTakeaways: List[str]
    suggestedActions: List[str]
    timestamp: str
