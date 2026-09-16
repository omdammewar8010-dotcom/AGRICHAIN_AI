import pytest
from app.models.risk import RiskPredictionInput
from app.ml.pipeline import ml_pipeline


def test_ml_risk_pipeline_normal_conditions():
    inp = RiskPredictionInput(
        cropType="Tomato",
        temperature=20.0,
        humidity=68.0,
        preferredTempMin=18.0,
        preferredTempMax=22.0,
        preferredHumidityMin=60.0,
        preferredHumidityMax=75.0,
        transitDurationHours=2.0,
        expectedTransitHours=4.5,
        delayMinutes=0.0,
        remainingDistanceKm=80.0,
        shelfLifeHours=96.0,
    )
    result = ml_pipeline.predict(inp)
    assert result.overallRisk < 35.0
    assert result.riskLevel in ["LOW", "MEDIUM"]
    assert len(result.factors) > 0


def test_ml_risk_pipeline_temperature_excursion():
    inp = RiskPredictionInput(
        cropType="Tomato",
        temperature=33.5,  # 11.5 deg above safe max
        humidity=85.0,
        preferredTempMin=18.0,
        preferredTempMax=22.0,
        delayMinutes=65.0,
        transitDurationHours=4.0,
        remainingDistanceKm=70.0,
    )
    result = ml_pipeline.predict(inp)
    assert result.spoilageRisk > 65.0
    assert result.overallRisk > 50.0
    assert result.riskLevel in ["HIGH", "CRITICAL"]
    # Temperature should be top factor
    assert any("Temperature" in f.factor or "Delay" in f.factor for f in result.factors)
    assert "CRITICAL" in result.recommendedAction or "HIGH" in result.recommendedAction
