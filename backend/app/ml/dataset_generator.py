import numpy as np
import pandas as pd
from typing import Tuple

CROP_PROFILES = {
    "Tomato": {
        "ideal_temp_min": 18.0,
        "ideal_temp_max": 22.0,
        "ideal_hum_min": 65.0,
        "ideal_hum_max": 75.0,
        "base_shelf_life_hours": 96.0,
        "sensitivity_temp": 1.5,
        "sensitivity_hum": 1.1,
    },
    "Grapes": {
        "ideal_temp_min": 0.0,
        "ideal_temp_max": 2.0,
        "ideal_hum_min": 85.0,
        "ideal_hum_max": 95.0,
        "base_shelf_life_hours": 120.0,
        "sensitivity_temp": 2.2,
        "sensitivity_hum": 1.4,
    },
    "Pomegranate": {
        "ideal_temp_min": 5.0,
        "ideal_temp_max": 8.0,
        "ideal_hum_min": 90.0,
        "ideal_hum_max": 95.0,
        "base_shelf_life_hours": 360.0,
        "sensitivity_temp": 1.0,
        "sensitivity_hum": 0.9,
    },
    "Banana": {
        "ideal_temp_min": 13.0,
        "ideal_temp_max": 15.0,
        "ideal_hum_min": 85.0,
        "ideal_hum_max": 90.0,
        "base_shelf_life_hours": 168.0,
        "sensitivity_temp": 1.8,
        "sensitivity_hum": 1.2,
    },
    "Milk": {
        "ideal_temp_min": 2.0,
        "ideal_temp_max": 4.0,
        "ideal_hum_min": 50.0,
        "ideal_hum_max": 80.0,
        "base_shelf_life_hours": 48.0,
        "sensitivity_temp": 3.0,
        "sensitivity_hum": 0.5,
    },
    "Greens": {
        "ideal_temp_min": 1.0,
        "ideal_temp_max": 4.0,
        "ideal_hum_min": 95.0,
        "ideal_hum_max": 98.0,
        "base_shelf_life_hours": 72.0,
        "sensitivity_temp": 2.0,
        "sensitivity_hum": 2.0,
    },
}


def generate_synthetic_agri_dataset(num_samples: int = 5000, random_seed: int = 42) -> pd.DataFrame:
    """
    Generates a scientifically grounded synthetic dataset representing agricultural cold-chain
    transport across diverse Indian supply chain routes and weather scenarios.
    """
    np.random.seed(random_seed)

    crops = list(CROP_PROFILES.keys())
    selected_crops = np.random.choice(crops, size=num_samples)

    data = []

    for crop in selected_crops:
        profile = CROP_PROFILES[crop]

        # Simulate normal, mild-stress, or severe refrigeration breakdown conditions
        condition_type = np.random.choice(["normal", "mild_anomaly", "severe_anomaly"], p=[0.60, 0.25, 0.15])

        if condition_type == "normal":
            temp = np.random.uniform(profile["ideal_temp_min"] - 0.5, profile["ideal_temp_max"] + 1.0)
            hum = np.random.uniform(profile["ideal_hum_min"] - 3.0, profile["ideal_hum_max"] + 3.0)
            delay_minutes = np.random.exponential(scale=15.0)
        elif condition_type == "mild_anomaly":
            temp = np.random.uniform(profile["ideal_temp_max"] + 1.5, profile["ideal_temp_max"] + 6.0)
            hum = np.random.uniform(profile["ideal_hum_min"] - 15.0, profile["ideal_hum_max"] + 10.0)
            delay_minutes = np.random.exponential(scale=45.0) + 20.0
        else:  # severe anomaly
            temp = np.random.uniform(profile["ideal_temp_max"] + 7.0, profile["ideal_temp_max"] + 16.0)
            hum = np.random.uniform(30.0, 99.0)
            delay_minutes = np.random.exponential(scale=90.0) + 60.0

        # Physical parameters
        transit_duration_hours = np.random.uniform(1.0, 18.0)
        expected_transit_hours = transit_duration_hours + (delay_minutes / 60.0)
        remaining_dist_km = np.random.uniform(10.0, 250.0)
        shelf_life_hours = max(5.0, profile["base_shelf_life_hours"] - (transit_duration_hours * 1.5))
        road_quality = np.random.uniform(0.4, 0.95)
        ambient_weather_temp = np.random.uniform(26.0, 42.0)

        # Calculate biological spoilage metric:
        # Degree-hours exceeding permissible maximum
        temp_excess = max(0.0, temp - profile["ideal_temp_max"])
        temp_deficit = max(0.0, profile["ideal_temp_min"] - temp)
        hum_deviation = max(0.0, profile["ideal_hum_min"] - hum) + max(0.0, hum - profile["ideal_hum_max"])

        # Spoilage score calculation (0 to 100)
        thermal_stress = (temp_excess * profile["sensitivity_temp"] * 3.5) + (temp_deficit * 1.8)
        moisture_stress = hum_deviation * profile["sensitivity_hum"] * 0.45
        time_ratio = (transit_duration_hours + (delay_minutes / 60.0)) / profile["base_shelf_life_hours"]

        raw_spoilage = (thermal_stress + moisture_stress + (time_ratio * 40.0)) * (1.2 - (road_quality * 0.2))
        spoilage_risk = float(np.clip(raw_spoilage + np.random.normal(0, 2.5), 0.0, 100.0))

        # Delay risk score (0 to 100)
        delay_risk = float(np.clip((delay_minutes / 180.0) * 100.0 + (remaining_dist_km / 300.0) * 20.0, 0.0, 100.0))

        # Overall composite risk
        overall_risk = float(np.clip(0.55 * spoilage_risk + 0.35 * delay_risk + 0.10 * (1.0 - road_quality) * 100, 0.0, 100.0))

        # Label: Anomaly
        is_anomaly = 1 if (condition_type != "normal" or spoilage_risk > 65.0 or delay_minutes > 90.0) else 0

        data.append({
            "crop_type": crop,
            "temperature": round(temp, 2),
            "humidity": round(hum, 2),
            "ideal_temp_min": profile["ideal_temp_min"],
            "ideal_temp_max": profile["ideal_temp_max"],
            "ideal_hum_min": profile["ideal_hum_min"],
            "ideal_hum_max": profile["ideal_hum_max"],
            "temp_excess": round(temp_excess, 2),
            "hum_deviation": round(hum_deviation, 2),
            "transit_duration_hours": round(transit_duration_hours, 2),
            "expected_transit_hours": round(expected_transit_hours, 2),
            "delay_minutes": round(delay_minutes, 2),
            "remaining_dist_km": round(remaining_dist_km, 2),
            "shelf_life_hours": round(shelf_life_hours, 2),
            "road_quality": round(road_quality, 2),
            "ambient_weather_temp": round(ambient_weather_temp, 2),
            "spoilage_risk": round(spoilage_risk, 2),
            "delay_risk": round(delay_risk, 2),
            "overall_risk": round(overall_risk, 2),
            "is_anomaly": is_anomaly,
        })

    return pd.DataFrame(data)
