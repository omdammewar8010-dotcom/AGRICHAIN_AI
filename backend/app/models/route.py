from typing import List, Optional
from pydantic import BaseModel, Field


class Coordinates(BaseModel):
    latitude: float
    longitude: float
    name: Optional[str] = None


class RouteOptimizationRequest(BaseModel):
    origin: Coordinates
    destination: Coordinates
    cropType: str = "Tomato"
    cargoWeightKg: float = 2000.0
    currentTemperature: float = 21.0
    currentDelayMinutes: float = 0.0
    # Configurable multi-objective weights (sum = 1.0)
    timeWeight: float = Field(0.35, ge=0.0, le=1.0)
    costWeight: float = Field(0.25, ge=0.0, le=1.0)
    riskWeight: float = Field(0.40, ge=0.0, le=1.0)


class RouteOption(BaseModel):
    routeId: str
    routeName: str
    distanceKm: float
    etaMinutes: int
    costInr: float
    spoilageRisk: float
    delayRisk: float
    overallScore: float
    isRecommended: bool
    highlights: List[str]
    waypoints: List[Coordinates]
    coldStoragePointsEnRoute: List[str]


class RouteOptimizationResponse(BaseModel):
    recommendationId: str
    bestRouteId: str
    routes: List[RouteOption]
    strategySummary: str
