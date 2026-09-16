from fastapi import APIRouter, Depends
from typing import Dict, Any
from pydantic import BaseModel

from app.auth.dependencies import get_current_user

router = APIRouter(prefix="/delay", tags=["Delay Prediction"])


class DelayPredictionRequest(BaseModel):
    currentSpeedKmph: float = 38.0
    remainingDistanceKm: float = 85.0
    congestionIndex: float = 0.65  # 0.0=free flow, 1.0=gridlock
    weatherCondition: str = "rain"
    routeSegment: str = "Kasara Ghat"


class DelayPredictionResponse(BaseModel):
    predictedDelayMinutes: float
    delayProbability: float
    confidence: float
    impactSeverity: str
    etaAdjustmentHours: float


@router.post("/predict-eta", response_model=DelayPredictionResponse)
async def predict_eta_delay(
    req: DelayPredictionRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Predicts transit delay minutes using route telemetry, congestion, and topography factors.
    """
    base_time_hours = req.remainingDistanceKm / max(15.0, req.currentSpeedKmph)
    weather_multiplier = 1.25 if req.weatherCondition in ["rain", "storm", "fog"] else 1.0
    terrain_multiplier = 1.30 if "ghat" in req.routeSegment.lower() else 1.0

    delay_minutes = (req.congestionIndex * 45.0 * weather_multiplier * terrain_multiplier) + (
        (60.0 - min(60.0, req.currentSpeedKmph)) * 0.5
    )
    delay_minutes = round(max(0.0, delay_minutes), 1)

    prob = min(0.98, max(0.10, (delay_minutes / 75.0)))
    severity = "CRITICAL" if delay_minutes > 60 else ("HIGH" if delay_minutes > 30 else "MODERATE")

    return DelayPredictionResponse(
        predictedDelayMinutes=delay_minutes,
        delayProbability=round(prob, 2),
        confidence=0.88,
        impactSeverity=severity,
        etaAdjustmentHours=round(delay_minutes / 60.0, 2),
    )
