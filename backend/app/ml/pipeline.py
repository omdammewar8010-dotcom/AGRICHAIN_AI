import os
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional
import joblib
import numpy as np
import pandas as pd

from app.models.risk import RiskPredictionInput, RiskPredictionOutput, RiskFactor
from app.ml.explainer import AgriRiskExplainer

logger = logging.getLogger("agrichain.ml.pipeline")

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models_store")


class MLRiskPipeline:
    def __init__(self):
        self.preprocessor = None
        self.spoilage_model = None
        self.delay_model = None
        self.anomaly_detector = None
        self.explainer = None
        self._load_artifacts()

    def _load_artifacts(self):
        preprocessor_path = os.path.join(MODELS_DIR, "preprocessor.joblib")
        spoilage_path = os.path.join(MODELS_DIR, "spoilage_model.joblib")
        delay_path = os.path.join(MODELS_DIR, "delay_model.joblib")
        anomaly_path = os.path.join(MODELS_DIR, "anomaly_detector.joblib")

        if os.path.exists(preprocessor_path) and os.path.exists(spoilage_path):
            try:
                self.preprocessor = joblib.load(preprocessor_path)
                self.spoilage_model = joblib.load(spoilage_path)
                self.delay_model = joblib.load(delay_path)
                self.anomaly_detector = joblib.load(anomaly_path)
                logger.info("Successfully loaded pre-trained ML models from store.")
            except Exception as e:
                logger.warning(f"Error loading model artifacts: {e}. Will use heuristic fallback.")
        else:
            logger.warning("ML model artifacts not found yet in models_store. Will use heuristic pipeline until trained.")

        self.explainer = AgriRiskExplainer(model=self.spoilage_model, preprocessor=self.preprocessor)

    def predict(self, inp: RiskPredictionInput) -> RiskPredictionOutput:
        temp_excess = max(0.0, inp.temperature - inp.preferredTempMax)
        temp_deficit = max(0.0, inp.preferredTempMin - inp.temperature)
        hum_deviation = max(0.0, inp.preferredHumidityMin - inp.humidity) + max(0.0, inp.humidity - inp.preferredHumidityMax)

        features_dict = {
            "crop_type": inp.cropType,
            "temperature": inp.temperature,
            "humidity": inp.humidity,
            "temp_excess": temp_excess,
            "hum_deviation": hum_deviation,
            "transit_duration_hours": inp.transitDurationHours,
            "expected_transit_hours": inp.expectedTransitHours,
            "delay_minutes": inp.delayMinutes,
            "remaining_dist_km": inp.remainingDistanceKm,
            "shelf_life_hours": inp.shelfLifeHours,
            "road_quality": inp.roadQualityScore,
            "ambient_weather_temp": inp.ambientWeatherTemp or 32.0,
        }

        # Model-based inference if models loaded
        if self.preprocessor is not None and self.spoilage_model is not None:
            try:
                df = pd.DataFrame([features_dict])
                x_trans = self.preprocessor.transform(df)
                spoilage_risk = float(np.clip(self.spoilage_model.predict(x_trans)[0], 0.0, 100.0))
                pred_delay_minutes = float(max(0.0, self.delay_model.predict(x_trans)[0]))
                delay_risk = float(np.clip((pred_delay_minutes / 180.0) * 100.0 + (inp.remainingDistanceKm / 300.0) * 20.0, 0.0, 100.0))

                anomaly_score = self.anomaly_detector.decision_function(x_trans)[0]
                # Negative score indicates anomaly in Isolation Forest
                anomaly_risk = float(np.clip((0.2 - anomaly_score) * 100.0, 0.0, 100.0))
            except Exception as e:
                logger.error(f"Inference error in trained model: {e}. Falling back to analytical formula.")
                spoilage_risk, delay_risk, anomaly_risk = self._heuristic_predict(inp, temp_excess, hum_deviation)
        else:
            spoilage_risk, delay_risk, anomaly_risk = self._heuristic_predict(inp, temp_excess, hum_deviation)

        # Composite overall risk
        overall_risk = float(np.clip((0.55 * spoilage_risk) + (0.35 * delay_risk) + (0.10 * anomaly_risk), 0.0, 100.0))

        # Risk level determination
        if overall_risk >= 75.0:
            risk_level = "CRITICAL"
        elif overall_risk >= 50.0:
            risk_level = "HIGH"
        elif overall_risk >= 25.0:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"

        # Generate Explainable AI factors
        factors = self.explainer.explain_instance(inp.model_dump(), spoilage_risk, delay_risk)

        # Action recommendation engine
        action = self._determine_action(risk_level, inp, temp_excess, temp_deficit, spoilage_risk, delay_risk)

        return RiskPredictionOutput(
            spoilageRisk=round(spoilage_risk, 1),
            delayRisk=round(delay_risk, 1),
            anomalyRisk=round(anomaly_risk, 1),
            overallRisk=round(overall_risk, 1),
            riskLevel=risk_level,
            factors=factors,
            recommendedAction=action,
            calculatedAt=datetime.now(timezone.utc).isoformat(),
        )

    def _heuristic_predict(self, inp: RiskPredictionInput, temp_excess: float, hum_deviation: float):
        thermal_stress = (temp_excess * 6.5)
        moisture_stress = hum_deviation * 0.8
        time_stress = (inp.transitDurationHours / max(1.0, inp.shelfLifeHours)) * 50.0
        spoilage = float(np.clip(thermal_stress + moisture_stress + time_stress, 0.0, 100.0))
        delay = float(np.clip((inp.delayMinutes / 120.0) * 80.0 + (inp.remainingDistanceKm / 250.0) * 20.0, 0.0, 100.0))
        anomaly = 85.0 if (temp_excess > 8.0 or hum_deviation > 25.0) else 10.0
        return spoilage, delay, anomaly

    def _determine_action(
        self,
        risk_level: str,
        inp: RiskPredictionInput,
        temp_excess: float,
        temp_deficit: float,
        spoilage_risk: float,
        delay_risk: float,
    ) -> str:
        if risk_level == "CRITICAL":
            if temp_excess > 5.0:
                return f"CRITICAL HAZARD: Temperature is {inp.temperature}°C (+{temp_excess:.1f}°C violation). Activate auxiliary reefer cooler immediately or divert to nearest Cold Hub (Bhiwandi Storage Hub, 32km away) to avert total loss."
            elif delay_risk > 70.0:
                return f"CRITICAL DELAY: Traffic stoppage (+{int(inp.delayMinutes)} min delay) exceeds shelf-life buffer. Reroute vehicle via Samruddhi Expressway corridor immediately."
            else:
                return "CRITICAL COMBINED RISK: Divert cargo to nearest APMC collection depot for rapid liquidation."
        elif risk_level == "HIGH":
            if temp_excess > 2.0:
                return f"HIGH RISK: Adjust transport refrigeration setpoint to {inp.preferredTempMin}°C - {inp.preferredTempMax}°C and inspect door seal gasket."
            return f"HIGH RISK: Monitor vehicle speed and utilize alternate bypass route to avoid peak urban bottlenecks."
        elif risk_level == "MEDIUM":
            return "MODERATE WARNING: Telemetry within acceptable tolerances; maintain steady cold-chain monitoring."
        else:
            return "NORMAL OPTIMAL: Cargo transit is executing within prime freshness specifications."


# Global singleton instance
ml_pipeline = MLRiskPipeline()
