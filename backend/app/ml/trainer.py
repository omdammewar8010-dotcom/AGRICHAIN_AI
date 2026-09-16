import os
import json
import logging
import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor, IsolationForest
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error

from app.ml.dataset_generator import generate_synthetic_agri_dataset

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("agrichain.ml.trainer")

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models_store")


def train_and_save_all_models():
    os.makedirs(MODELS_DIR, exist_ok=True)
    logger.info("Generating realistic multi-crop agricultural dataset...")
    df = generate_synthetic_agri_dataset(num_samples=7000, random_seed=42)

    feature_cols = [
        "crop_type",
        "temperature",
        "humidity",
        "temp_excess",
        "hum_deviation",
        "transit_duration_hours",
        "expected_transit_hours",
        "delay_minutes",
        "remaining_dist_km",
        "shelf_life_hours",
        "road_quality",
        "ambient_weather_temp",
    ]

    categorical_features = ["crop_type"]
    numerical_features = [c for c in feature_cols if c not in categorical_features]

    X = df[feature_cols]
    y_spoilage = df["spoilage_risk"]
    y_delay = df["delay_minutes"]

    preprocessor = ColumnTransformer(
        transformers=[
            ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), categorical_features),
            ("num", "passthrough", numerical_features),
        ]
    )

    X_train, X_test, y_spoil_train, y_spoil_test, y_delay_train, y_delay_test = train_test_split(
        X, y_spoilage, y_delay, test_size=0.20, random_state=42
    )

    logger.info("Fitting feature preprocessor...")
    X_train_processed = preprocessor.fit_transform(X_train)
    X_test_processed = preprocessor.transform(X_test)

    # 1. Spoilage Prediction Model (Random Forest Regressor)
    logger.info("Training Spoilage Prediction Model (Random Forest)...")
    spoilage_model = RandomForestRegressor(
        n_estimators=100,
        max_depth=12,
        min_samples_split=4,
        random_state=42,
        n_jobs=-1
    )
    spoilage_model.fit(X_train_processed, y_spoil_train)

    spoil_preds = spoilage_model.predict(X_test_processed)
    spoil_r2 = r2_score(y_spoil_test, spoil_preds)
    spoil_mae = mean_absolute_error(y_spoil_test, spoil_preds)
    logger.info(f"Spoilage Model Evaluated -> R2: {spoil_r2:.4f}, MAE: {spoil_mae:.2f}%")

    # 2. Delay Prediction Model (Gradient Boosting Regressor)
    logger.info("Training Delay Prediction Model (Gradient Boosting)...")
    delay_model = GradientBoostingRegressor(
        n_estimators=80,
        max_depth=6,
        learning_rate=0.08,
        random_state=42
    )
    delay_model.fit(X_train_processed, y_delay_train)

    delay_preds = delay_model.predict(X_test_processed)
    delay_r2 = r2_score(y_delay_test, delay_preds)
    delay_mae = mean_absolute_error(y_delay_test, delay_preds)
    logger.info(f"Delay Model Evaluated -> R2: {delay_r2:.4f}, MAE: {delay_mae:.2f} minutes")

    # 3. Anomaly Detection Model (Isolation Forest)
    logger.info("Training Sensor Anomaly Detector (Isolation Forest)...")
    anomaly_detector = IsolationForest(
        n_estimators=100,
        contamination=0.15,
        random_state=42,
        n_jobs=-1
    )
    anomaly_detector.fit(X_train_processed)

    # Save artifacts
    logger.info(f"Saving trained models to {MODELS_DIR}...")
    joblib.dump(preprocessor, os.path.join(MODELS_DIR, "preprocessor.joblib"))
    joblib.dump(spoilage_model, os.path.join(MODELS_DIR, "spoilage_model.joblib"))
    joblib.dump(delay_model, os.path.join(MODELS_DIR, "delay_model.joblib"))
    joblib.dump(anomaly_detector, os.path.join(MODELS_DIR, "anomaly_detector.joblib"))

    feature_names = preprocessor.get_feature_names_out().tolist()
    metadata = {
        "feature_names": feature_names,
        "spoilage_model": {
            "r2": round(float(spoil_r2), 4),
            "mae": round(float(spoil_mae), 2),
            "algorithm": "RandomForestRegressor(n_estimators=100, max_depth=12)"
        },
        "delay_model": {
            "r2": round(float(delay_r2), 4),
            "mae": round(float(delay_mae), 2),
            "algorithm": "GradientBoostingRegressor(n_estimators=80, max_depth=6)"
        },
        "anomaly_detector": {
            "contamination": 0.15,
            "algorithm": "IsolationForest(n_estimators=100)"
        }
    }

    with open(os.path.join(MODELS_DIR, "metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2)

    logger.info("ML Training pipeline successfully completed! All models exported.")
    return metadata


if __name__ == "__main__":
    train_and_save_all_models()
