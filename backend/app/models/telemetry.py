from typing import Optional
from pydantic import BaseModel, Field


class TelemetryPayload(BaseModel):
    deviceId: str = Field(..., description="Unique ESP32 or simulated device ID (e.g., ESP32-TRUCK-001)")
    batchId: str = Field(..., description="Active crop batch ID (e.g., AGRI-2026-TOM-000124)")
    shipmentId: Optional[str] = Field(None, description="Active shipment ID")
    temperature: float = Field(..., description="Current temperature in Celsius")
    humidity: float = Field(..., description="Current relative humidity in percent")
    latitude: float = Field(..., description="Current GPS latitude")
    longitude: float = Field(..., description="Current GPS longitude")
    speed: float = Field(0.0, description="Current speed in km/h")
    altitude: Optional[float] = Field(None, description="Altitude in meters")
    battery: Optional[int] = Field(100, description="Battery percentage (0-100)")
    timestamp: Optional[int] = Field(None, description="Epoch timestamp in seconds")
    deviceStatus: Optional[str] = Field("online", description="Device health status")


class TelemetryResponse(BaseModel):
    status: str
    message: str
    telemetryReceived: TelemetryPayload
    anomalyDetected: bool
    riskScore: float
    riskLevel: str
