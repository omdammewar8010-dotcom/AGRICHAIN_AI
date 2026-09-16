import uuid
from typing import List
from app.models.route import (
    RouteOptimizationRequest,
    RouteOptimizationResponse,
    RouteOption,
    Coordinates,
)


class RouteOptimizer:
    """
    Multi-objective Agricultural Logistics Route Optimizer.
    Evaluates candidate transit corridors balancing:
    1. ETA & Transit Duration (Minimizing crop shelf-life depletion)
    2. Operational Cost (Fuel, Tolls, Reefer energy)
    3. Environmental & Spoilage Hazard Risk (Traffic congestion hotspots, temperature spikes, road bumpiness)
    """

    @staticmethod
    def optimize_routes(request: RouteOptimizationRequest) -> RouteOptimizationResponse:
        origin_lat = request.origin.latitude
        origin_lng = request.origin.longitude
        dest_lat = request.destination.latitude
        dest_lng = request.destination.longitude

        # Base straight-line distance heuristic in km
        lat_diff = abs(dest_lat - origin_lat)
        lng_diff = abs(dest_lng - origin_lng)
        base_dist = max(40.0, (lat_diff**2 + lng_diff**2) ** 0.5 * 111.0)

        # Baseline cost per km in INR (fuel + refrigeration reefer consumption)
        cost_per_km = 14.5 + (request.cargoWeightKg / 1000.0) * 1.8

        # Option 1: Express Green Corridor (Samruddhi Expressway / National Superhighway)
        dist_1 = round(base_dist * 1.08, 1)
        eta_1 = int((dist_1 / 65.0) * 60)  # average 65 km/h
        cost_1 = round(dist_1 * cost_per_km + 450.0, 2)  # includes highway toll
        spoilage_1 = 12.0 if request.currentTemperature <= 24.0 else 28.0
        delay_risk_1 = 15.0

        # Option 2: State Highway Regular Corridor (Kasara Ghat route)
        dist_2 = round(base_dist * 1.02, 1)
        eta_2 = int((dist_2 / 45.0) * 60 + request.currentDelayMinutes)  # slower ghat speed + traffic
        cost_2 = round(dist_2 * cost_per_km + 180.0, 2)
        spoilage_2 = 34.0 if request.currentTemperature <= 24.0 else 62.0
        delay_risk_2 = 45.0

        # Option 3: Rural Bypass / Local Freight Route
        dist_3 = round(base_dist * 1.18, 1)
        eta_3 = int((dist_3 / 38.0) * 60)
        cost_3 = round(dist_3 * cost_per_km + 50.0, 2)  # minimal tolls
        spoilage_3 = 48.0 if request.currentTemperature <= 24.0 else 78.0
        delay_risk_3 = 58.0

        options_data = [
            {
                "id": "ROUTE-EXPRESS-01",
                "name": "Corridor A: Samruddhi Express Highway (Optimal Freshness)",
                "dist": dist_1,
                "eta": eta_1,
                "cost": cost_1,
                "spoilage": spoilage_1,
                "delay": delay_risk_1,
                "highlights": ["Zero Ghat bottlenecks", "Continuous high-speed reefer airflow", "Smooth road quality (0.95)"],
                "cold_storage": ["Igatpuri Express Cold Hub (KM 45)", "Bhiwandi Integrated Logistics Park (KM 130)"],
                "waypoints": [
                    Coordinates(latitude=origin_lat, longitude=origin_lng, name=request.origin.name or "Origin Farm"),
                    Coordinates(latitude=(origin_lat * 0.65 + dest_lat * 0.35), longitude=(origin_lng * 0.65 + dest_lng * 0.35), name="Express Interchange 4"),
                    Coordinates(latitude=(origin_lat * 0.30 + dest_lat * 0.70), longitude=(origin_lng * 0.30 + dest_lng * 0.70), name="Bhiwandi Logistics Bypass"),
                    Coordinates(latitude=dest_lat, longitude=dest_lng, name=request.destination.name or "Destination Hub"),
                ]
            },
            {
                "id": "ROUTE-STANDARD-02",
                "name": "Corridor B: NH-160 via Kasara Ghat",
                "dist": dist_2,
                "eta": eta_2,
                "cost": cost_2,
                "spoilage": spoilage_2,
                "delay": delay_risk_2,
                "highlights": ["Direct distance", "Ghat incline slow traffic", "Moderate road bumps (0.75)"],
                "cold_storage": ["Ghoti APMC Storage (KM 32)", "Kalyan Agro Depot (KM 140)"],
                "waypoints": [
                    Coordinates(latitude=origin_lat, longitude=origin_lng, name=request.origin.name or "Origin Farm"),
                    Coordinates(latitude=(origin_lat * 0.60 + dest_lat * 0.40), longitude=(origin_lng * 0.60 + dest_lng * 0.40), name="Kasara Ghat Descent"),
                    Coordinates(latitude=(origin_lat * 0.25 + dest_lat * 0.75), longitude=(origin_lng * 0.25 + dest_lng * 0.75), name="Asangaon Toll Plaza"),
                    Coordinates(latitude=dest_lat, longitude=dest_lng, name=request.destination.name or "Destination Hub"),
                ]
            },
            {
                "id": "ROUTE-ECONOMY-03",
                "name": "Corridor C: Rural State Bypass (Lowest Toll)",
                "dist": dist_3,
                "eta": eta_3,
                "cost": cost_3,
                "spoilage": spoilage_3,
                "delay": delay_risk_3,
                "highlights": ["Minimal toll charges", "Rough rural pavement (0.55)", "Higher ambient vibration"],
                "cold_storage": ["Murbad Agri Cooperative (KM 95)"],
                "waypoints": [
                    Coordinates(latitude=origin_lat, longitude=origin_lng, name=request.origin.name or "Origin Farm"),
                    Coordinates(latitude=(origin_lat * 0.50 + dest_lat * 0.50), longitude=(origin_lng * 0.50 + dest_lng * 0.50), name="Murbad Rural Link"),
                    Coordinates(latitude=dest_lat, longitude=dest_lng, name=request.destination.name or "Destination Hub"),
                ]
            },
        ]

        # Calculate composite score for each candidate
        # Score lower is better (0 to 100)
        max_eta = max(o["eta"] for o in options_data)
        max_cost = max(o["cost"] for o in options_data)

        scored_routes: List[RouteOption] = []
        best_score = float("inf")
        best_id = options_data[0]["id"]

        for opt in options_data:
            norm_time = (opt["eta"] / max_eta) * 100.0
            norm_cost = (opt["cost"] / max_cost) * 100.0
            norm_risk = (opt["spoilage"] * 0.6 + opt["delay"] * 0.4)

            composite_score = round(
                (request.timeWeight * norm_time) +
                (request.costWeight * norm_cost) +
                (request.riskWeight * norm_risk),
                2
            )

            if composite_score < best_score:
                best_score = composite_score
                best_id = opt["id"]

            scored_routes.append(
                RouteOption(
                    routeId=opt["id"],
                    routeName=opt["name"],
                    distanceKm=opt["dist"],
                    etaMinutes=opt["eta"],
                    costInr=opt["cost"],
                    spoilageRisk=opt["spoilage"],
                    delayRisk=opt["delay"],
                    overallScore=composite_score,
                    isRecommended=False,  # will set after loop
                    highlights=opt["highlights"],
                    waypoints=opt["waypoints"],
                    coldStoragePointsEnRoute=opt["cold_storage"],
                )
            )

        for r in scored_routes:
            if r.routeId == best_id:
                r.isRecommended = True

        return RouteOptimizationResponse(
            recommendationId=f"REC-{uuid.uuid4().hex[:8].upper()}",
            bestRouteId=best_id,
            routes=scored_routes,
            strategySummary=(
                f"Selected {best_id} based on optimization priorities (Time: {int(request.timeWeight*100)}%, "
                f"Cost: {int(request.costWeight*100)}%, Freshness Preservation Risk: {int(request.riskWeight*100)}%)."
            ),
        )
