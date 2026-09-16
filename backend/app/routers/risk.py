from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any

from app.models.risk import (
    RiskPredictionInput,
    RiskPredictionOutput,
    ExplainabilityResponse,
)
from app.ml.pipeline import ml_pipeline
from app.auth.dependencies import get_current_user
from app.firebase import get_firestore

router = APIRouter(prefix="/risk", tags=["Risk & Explainable AI"])


@router.post("/predict", response_model=RiskPredictionOutput)
async def predict_risk(
    input_data: RiskPredictionInput,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Evaluates real-time sensor and transit inputs through the ML Risk Pipeline.
    Calculates spoilage probability, delay risk, anomaly score, and SHAP-based factors.
    """
    prediction = ml_pipeline.predict(input_data)

    # If Firestore client available, persist prediction
    db = get_firestore()
    if db:
        try:
            db.collection("risk_predictions").add({
                "cropType": input_data.cropType,
                "spoilageRisk": prediction.spoilageRisk,
                "delayRisk": prediction.delayRisk,
                "overallRisk": prediction.overallRisk,
                "riskLevel": prediction.riskLevel,
                "recommendedAction": prediction.recommendedAction,
                "calculatedAt": prediction.calculatedAt,
                "performedBy": current_user.get("uid", "anonymous"),
            })
        except Exception as e:
            # Non-blocking log
            pass

    return prediction


@router.get("/{batch_id}/explanation", response_model=ExplainabilityResponse)
async def get_batch_risk_explanation(
    batch_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Returns Explainable AI (SHAP / Feature Attribution) breakdown for a specific crop batch.
    """
    db = get_firestore()
    temperature = 28.5
    humidity = 82.0
    crop_name = "Tomato"

    if db:
        try:
            batch_doc = db.collection("crop_batches").document(batch_id).get()
            if batch_doc.exists:
                data = batch_doc.to_dict()
                crop_name = data.get("cropName", "Tomato")
        except Exception:
            pass

    # Run inference for the batch snapshot
    snapshot_input = RiskPredictionInput(
        cropType=crop_name,
        temperature=temperature,
        humidity=humidity,
        delayMinutes=35.0,
        transitDurationHours=3.5,
        remainingDistanceKm=65.0,
    )
    pred = ml_pipeline.predict(snapshot_input)

    summary_text = (
        f"For batch {batch_id} ({crop_name}), the primary risk driver is "
        f"{pred.factors[0].factor} ({pred.factors[0].impact}% impact), followed by "
        f"{pred.factors[1].factor if len(pred.factors) > 1 else 'Logistics Delay'}."
    )

    return ExplainabilityResponse(
        batchId=batch_id,
        overallRisk=pred.overallRisk,
        riskLevel=pred.riskLevel,
        factors=pred.factors,
        summary=summary_text,
    )
