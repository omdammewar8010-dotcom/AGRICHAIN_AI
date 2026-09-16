import pytest
from app.models.route import RouteOptimizationRequest, Coordinates
from app.optimization.route_optimizer import RouteOptimizer


def test_route_optimizer_multi_objective():
    req = RouteOptimizationRequest(
        origin=Coordinates(latitude=19.9975, longitude=73.7898, name="Nashik Farm"),
        destination=Coordinates(latitude=19.0760, longitude=72.8777, name="APMC Mumbai"),
        cropType="Tomato",
        currentTemperature=21.0,
        currentDelayMinutes=10.0,
        timeWeight=0.35,
        costWeight=0.25,
        riskWeight=0.40,
    )
    res = RouteOptimizer.optimize_routes(req)
    assert len(res.routes) == 3
    assert res.bestRouteId is not None
    # Best route must have isRecommended = True
    recommended = [r for r in res.routes if r.isRecommended]
    assert len(recommended) == 1
    assert recommended[0].routeId == res.bestRouteId
