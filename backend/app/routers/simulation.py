import time
import math
from typing import Dict, Any, Optional
from fastapi import APIRouter
from pydantic import BaseModel

from app.firebase import update_rtdb_shipment_telemetry
from app.ml.pipeline import ml_pipeline
from app.models.risk import RiskPredictionInput

router = APIRouter(prefix="/simulation", tags=["Hackathon Simulation Engine"])

# Simulated journey route: Nashik Farm -> Igatpuri -> Kasara Ghat -> Kalyan -> Vashi APMC Mumbai
SIMULATION_WAYPOINTS = [
    {"name": "Nashik Agro Farm", "lat": 19.9975, "lng": 73.7898},
    {"name": "Ghoti Junction", "lat": 19.7224, "lng": 73.6543},
    {"name": "Igatpuri Logistics Hub", "lat": 19.6948, "lng": 73.5601},
    {"name": "Kasara Ghat Hairpin", "lat": 19.6450, "lng": 73.4820},
    {"name": "Shahapur Corridor", "lat": 19.4521, "lng": 73.3421},
    {"name": "Kalyan Bypass", "lat": 19.2437, "lng": 73.1355},
    {"name": "Thane Toll Plaza", "lat": 19.1860, "lng": 72.9750},
    {"name": "APMC Market Vashi", "lat": 19.0760, "lng": 72.8777},
]


class SimulationState:
    def __init__(self):
        self.active: bool = True
        self.batch_id: str = "AGRI-2026-TOM-000124"
        self.shipment_id: str = "SHIP-2026-0916-01"
        self.current_step: int = 2
        self.total_steps: int = len(SIMULATION_WAYPOINTS)
        self.mode: str = "normal"  # normal, temp_spike, humidity_spike, route_delay, iot_failure
        self.temperature: float = 20.2
        self.humidity: float = 67.5
        self.delay_minutes: float = 0.0
        self.speed: float = 52.0
        self.battery: int = 94
        self.device_status: str = "online"
        self.last_injected_event: Optional[str] = None


sim_state = SimulationState()


class AnomalyInjectionRequest(BaseModel):
    anomalyType: str  # temp_spike, humidity_spike, route_delay, iot_failure, normal
    magnitude: Optional[float] = None
    description: Optional[str] = None


@router.get("/status")
def get_simulation_status():
    """Returns the current state of the active hackathon simulation."""
    idx = min(sim_state.current_step, len(SIMULATION_WAYPOINTS) - 1)
    waypoint = SIMULATION_WAYPOINTS[idx]

    # Evaluate ML risk on the fly
    risk_input = RiskPredictionInput(
        cropType="Tomato",
        temperature=sim_state.temperature,
        humidity=sim_state.humidity,
        delayMinutes=sim_state.delay_minutes,
        transitDurationHours=2.5,
        remainingDistanceKm=max(10.0, (len(SIMULATION_WAYPOINTS) - 1 - idx) * 22.0),
    )
    pred = ml_pipeline.predict(risk_input)

    return {
        "active": sim_state.active,
        "batchId": sim_state.batch_id,
        "shipmentId": sim_state.shipment_id,
        "mode": sim_state.mode,
        "currentWaypoint": waypoint["name"],
        "step": sim_state.current_step,
        "totalSteps": sim_state.total_steps,
        "telemetry": {
            "latitude": waypoint["lat"],
            "longitude": waypoint["lng"],
            "temperature": round(sim_state.temperature, 2),
            "humidity": round(sim_state.humidity, 2),
            "speed": sim_state.speed,
            "battery": sim_state.battery,
            "deviceStatus": sim_state.device_status,
            "delayMinutes": sim_state.delay_minutes,
        },
        "mlRisk": {
            "spoilageRisk": pred.spoilageRisk,
            "delayRisk": pred.delayRisk,
            "overallRisk": pred.overallRisk,
            "riskLevel": pred.riskLevel,
            "topFactors": [f.model_dump() for f in pred.factors[:3]],
            "recommendedAction": pred.recommendedAction,
        },
        "lastInjectedEvent": sim_state.last_injected_event,
    }


@router.post("/step")
def step_simulation():
    """Advances the simulated shipment to the next waypoint along the transit corridor."""
    sim_state.current_step = (sim_state.current_step + 1) % len(SIMULATION_WAYPOINTS)
    idx = sim_state.current_step
    waypoint = SIMULATION_WAYPOINTS[idx]

    # Apply slight natural telemetry variation if in normal mode
    if sim_state.mode == "normal":
        sim_state.temperature = 20.0 + (math.sin(idx) * 1.5)
        sim_state.humidity = 66.0 + (math.cos(idx) * 3.0)
        sim_state.speed = 48.0 + (math.sin(idx * 2) * 8.0)

    # Sync to Firebase RTDB
    update_rtdb_shipment_telemetry(sim_state.shipment_id, {
        "batchId": sim_state.batch_id,
        "latitude": waypoint["lat"],
        "longitude": waypoint["lng"],
        "temperature": round(sim_state.temperature, 2),
        "humidity": round(sim_state.humidity, 2),
        "speed": round(sim_state.speed, 1),
        "battery": sim_state.battery,
        "deviceStatus": sim_state.device_status,
        "timestamp": int(time.time()),
    })

    return get_simulation_status()


@router.post("/inject")
def inject_anomaly(req: AnomalyInjectionRequest):
    """
    Injects an operational or environmental anomaly into the live simulation.
    Instantly changes RTDB live values and triggers ML risk predictions.
    """
    atype = req.anomalyType.lower()
    sim_state.mode = atype

    if atype == "temp_spike":
        sim_state.temperature = req.magnitude or 32.6
        sim_state.last_injected_event = "Temperature Spike (+10.6°C Reefer Failure)"
    elif atype == "humidity_spike":
        sim_state.humidity = req.magnitude or 92.5
        sim_state.last_injected_event = "Excess Moisture / Humidity Excursion (92.5%)"
    elif atype == "route_delay":
        sim_state.delay_minutes = req.magnitude or 75.0
        sim_state.speed = 12.0
        sim_state.last_injected_event = "Ghat Corridor Traffic Blockade (+75 min delay)"
    elif atype == "iot_failure":
        sim_state.battery = 6
        sim_state.device_status = "low_battery_warning"
        sim_state.last_injected_event = "IoT Sensor Battery Depletion Alert"
    else:  # normal / reset
        sim_state.mode = "normal"
        sim_state.temperature = 20.2
        sim_state.humidity = 67.5
        sim_state.delay_minutes = 0.0
        sim_state.speed = 52.0
        sim_state.battery = 94
        sim_state.device_status = "online"
        sim_state.last_injected_event = "Reset to Normal Optimal Conditions"

    # Immediately push state to RTDB
    idx = min(sim_state.current_step, len(SIMULATION_WAYPOINTS) - 1)
    waypoint = SIMULATION_WAYPOINTS[idx]

    update_rtdb_shipment_telemetry(sim_state.shipment_id, {
        "batchId": sim_state.batch_id,
        "latitude": waypoint["lat"],
        "longitude": waypoint["lng"],
        "temperature": round(sim_state.temperature, 2),
        "humidity": round(sim_state.humidity, 2),
        "speed": round(sim_state.speed, 1),
        "battery": sim_state.battery,
        "deviceStatus": sim_state.device_status,
        "anomalyFlag": (atype != "normal"),
        "timestamp": int(time.time()),
    })

    return get_simulation_status()


@router.post("/reset")
def reset_simulation():
    """Resets the simulation to the origin farm in normal state."""
    sim_state.current_step = 0
    return inject_anomaly(AnomalyInjectionRequest(anomalyType="normal"))
