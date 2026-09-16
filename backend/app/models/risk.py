from typing import List, Optional, Dict
from pydantic import BaseModel, Field


class RiskPredictionInput(BaseModel):
    cropType: str = Field("Tomato", description="Crop variety (Tomato, Grapes, Pomegranate, Banana, Milk, Greens)")
    temperature: float = Field(..., description="Current measured temperature in Celsius")
    humidity: float = Field(..., description="Current relative humidity in percent")
    preferredTempMin: float = Field(18.0, description="Minimum preferred temperature")
    preferredTempMax: float = Field(22.0, description="Maximum preferred temperature")
    preferredHumidityMin: float = Field(60.0, description="Minimum preferred humidity")
    preferredHumidityMax: float = Field(75.0, description="Maximum preferred humidity")
    transitDurationHours: float = Field(2.5, description="Elapsed hours in transit")
    expectedTransitHours: float = Field(4.5, description="Estimated total transit hours")
    delayMinutes: float = Field(0.0, description="Current delay in minutes")
    remainingDistanceKm: float = Field(80.0, description="Remaining transit distance in kilometers")
    shelfLifeHours: float = Field(96.0, description="Remaining crop shelf life in hours")
    roadQualityScore: float = Field(0.8, description="Road infrastructure quality (0.0=rough to 1.0=expressway)")
    ambientWeatherTemp: Optional[float] = Field(32.0, description="External ambient weather temperature in Celsius")


class RiskFactor(BaseModel):
    factor: str
    impact: float
    description: Optional[str] = None


class RiskPredictionOutput(BaseModel):
    spoilageRisk: float = Field(..., description="Predicted spoilage risk percentage (0-100)")
    delayRisk: float = Field(..., description="Predicted delay severity risk percentage (0-100)")
    anomalyRisk: float = Field(..., description="Sensor anomaly indicator risk (0-100)")
    overallRisk: float = Field(..., description="Composite weighted risk score (0-100)")
    riskLevel: str = Field(..., description="LOW, MEDIUM, HIGH, or CRITICAL")
    factors: List[RiskFactor] = Field(default_factory=list, description="Top SHAP feature attribution factors")
    recommendedAction: str = Field(..., description="Actionable prescription for transporter / supply chain operator")
    calculatedAt: str


class ExplainabilityResponse(BaseModel):
    batchId: str
    overallRisk: float
    riskLevel: str
    factors: List[RiskFactor]
    summary: str
