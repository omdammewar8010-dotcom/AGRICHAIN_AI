import time
import logging
from fastapi import APIRouter, HTTPException, status
from app.models.telemetry import TelemetryPayload, TelemetryResponse
from app.models.risk import RiskPredictionInput
from app.ml.pipeline import ml_pipeline
from app.firebase import update_rtdb_shipment_telemetry, get_firestore
from app.services.notification_service import notification_service

logger = logging.getLogger("agrichain.iot")
router = APIRouter(prefix="/iot", tags=["IoT Ingestion"])


@router.post("/telemetry", response_model=TelemetryResponse)
async def ingest_telemetry(payload: TelemetryPayload):
    """
    High-frequency IoT ingestion endpoint for ESP32 and Hackathon simulator.
    1. Validates incoming sensor payload
    2. Updates Firebase Realtime Database (RTDB) for live Flutter stream
    3. Runs ML inference for continuous risk & anomaly detection
    4. Triggers alerts & notifications if risk thresholds are breached
    """
    ts = payload.timestamp or int(time.time())
    shipment_id = payload.shipmentId or f"SHIP-{payload.batchId}"

    # 1. Update Firebase RTDB live state
    rtdb_data = {
        "batchId": payload.batchId,
        "deviceId": payload.deviceId,
        "temperature": round(payload.temperature, 2),
        "humidity": round(payload.humidity, 2),
        "latitude": round(payload.latitude, 6),
        "longitude": round(payload.longitude, 6),
        "speed": round(payload.speed, 1),
        "altitude": payload.altitude,
        "battery": payload.battery,
        "deviceStatus": payload.deviceStatus or "online",
        "timestamp": ts,
        "lastPing": ts,
    }
    update_rtdb_shipment_telemetry(shipment_id, rtdb_data)

    # 2. Run real-time ML risk inference
    risk_input = RiskPredictionInput(
        cropType="Tomato",  # default crop profile
        temperature=payload.temperature,
        humidity=payload.humidity,
        preferredTempMin=18.0,
        preferredTempMax=22.0,
        preferredHumidityMin=60.0,
        preferredHumidityMax=75.0,
        transitDurationHours=2.5,
        expectedTransitHours=4.5,
        delayMinutes=0.0,
        remainingDistanceKm=75.0,
        shelfLifeHours=90.0,
    )
    pred = ml_pipeline.predict(risk_input)

    # Anomaly flag
    is_anomaly = pred.anomalyRisk > 50.0 or pred.spoilageRisk > 60.0

    # 3. If critical risk, store alert in Firestore and send FCM
    if pred.riskLevel in ["CRITICAL", "HIGH"]:
        db = get_firestore()
        if db:
            try:
                db.collection("alerts").add({
                    "batchId": payload.batchId,
                    "shipmentId": shipment_id,
                    "title": f"Cold Chain Alert: {pred.riskLevel} ({round(pred.overallRisk)}/100)",
                    "description": pred.recommendedAction,
                    "severity": pred.riskLevel,
                    "status": "open",
                    "temperature": payload.temperature,
                    "humidity": payload.humidity,
                    "createdAt": ts,
                })
            except Exception as e:
                logger.warning(f"Could not write alert to Firestore: {e}")

        notification_service.send_risk_alert_push(
            batch_id=payload.batchId,
            risk_score=pred.overallRisk,
            risk_level=pred.riskLevel,
            title=f"⚠️ Cold Chain Breach: {pred.riskLevel}",
            body=f"Batch {payload.batchId} reached {round(payload.overallRisk)}/100 risk. Temp: {payload.temperature}°C",
        )

    return TelemetryResponse(
        status="success",
        message="Telemetry ingested and evaluated by ML engine.",
        telemetryReceived=payload,
        anomalyDetected=is_anomaly,
        riskScore=pred.overallRisk,
        riskLevel=pred.riskLevel,
    )
