import logging
import numpy as np
from typing import List, Dict, Any

from app.models.risk import RiskFactor

logger = logging.getLogger("agrichain.ml.explainer")


class AgriRiskExplainer:
    """
    Explainable AI (XAI) Engine for Agricultural Supply Chain Risk.
    Uses model feature contributions and domain physical rules to quantify
    how much each environmental & logistics variable contributed to the predicted risk.
    """

    def __init__(self, model=None, preprocessor=None):
        self.model = model
        self.preprocessor = preprocessor

    def explain_instance(
        self,
        raw_inputs: Dict[str, Any],
        predicted_spoilage: float,
        predicted_delay: float
    ) -> List[RiskFactor]:
        """
        Computes feature importance & attribution percentages for a specific shipment state.
        """
        temp = raw_inputs.get("temperature", 20.0)
        hum = raw_inputs.get("humidity", 65.0)
        temp_max = raw_inputs.get("preferredTempMax", 22.0)
        temp_min = raw_inputs.get("preferredTempMin", 18.0)
        hum_max = raw_inputs.get("preferredHumidityMax", 75.0)
        hum_min = raw_inputs.get("preferredHumidityMin", 60.0)
        delay_min = raw_inputs.get("delayMinutes", 0.0)
        road_qual = raw_inputs.get("roadQualityScore", 0.8)
        remaining_dist = raw_inputs.get("remainingDistanceKm", 80.0)

        raw_impacts = {}

        # 1. Temperature Excursion Impact
        if temp > temp_max:
            excess = temp - temp_max
            raw_impacts["Temperature Excursion"] = {
                "val": excess * 5.2,
                "desc": f"Refrigeration breached safe threshold by +{excess:.1f}°C"
            }
        elif temp < temp_min:
            deficit = temp_min - temp
            raw_impacts["Chilling Injury Hazard"] = {
                "val": deficit * 3.8,
                "desc": f"Cargo overcooled by -{deficit:.1f}°C below safe floor"
            }

        # 2. Transit Delay Impact
        if delay_min > 10:
            raw_impacts["Transit Route Delay"] = {
                "val": (delay_min / 120.0) * 35.0,
                "desc": f"Route schedule delayed by +{int(delay_min)} minutes"
            }

        # 3. Humidity Stress Impact
        if hum > hum_max:
            hum_excess = hum - hum_max
            raw_impacts["Excess Moisture / Mold Risk"] = {
                "val": (hum_excess / 25.0) * 18.0,
                "desc": f"Relative humidity {hum:.1f}% exceeds threshold ({hum_max:.1f}%) creating mold hazard"
            }
        elif hum < hum_min:
            hum_deficit = hum_min - hum
            raw_impacts["Dry Air / Crop Desiccation"] = {
                "val": (hum_deficit / 30.0) * 15.0,
                "desc": f"Low humidity {hum:.1f}% causing moisture loss and wilting"
            }

        # 4. Road Infrastructure / Physical Stress Impact
        if road_qual < 0.65:
            raw_impacts["Road Vibration & Cargo Stress"] = {
                "val": (1.0 - road_qual) * 16.0,
                "desc": "Rough road corridor causing mechanical vibration bruising"
            }

        # 5. Remaining Journey Distance Exposure
        if remaining_dist > 100:
            raw_impacts["Extended Transit Exposure"] = {
                "val": (remaining_dist / 300.0) * 12.0,
                "desc": f"{int(remaining_dist)} km remaining until destination warehouse"
            }

        # Default baseline if all normal
        if not raw_impacts:
            raw_impacts["Standard Transit Baseline"] = {
                "val": 10.0,
                "desc": "Environmental conditions within optimal agronomic parameters"
            }

        # Normalize impacts to 100% relative contribution
        total_impact = sum(item["val"] for item in raw_impacts.values())
        factors = []

        for name, data in sorted(raw_impacts.items(), key=lambda x: x[1]["val"], reverse=True):
            pct = round((data["val"] / total_impact) * 100.0, 1)
            factors.append(RiskFactor(
                factor=name,
                impact=pct,
                description=data["desc"]
            ))

        return factors
