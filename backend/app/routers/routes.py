from fastapi import APIRouter, Depends
from typing import Dict, Any

from app.models.route import RouteOptimizationRequest, RouteOptimizationResponse
from app.optimization.route_optimizer import RouteOptimizer
from app.auth.dependencies import get_current_user

router = APIRouter(prefix="/routes", tags=["Route Optimization"])


@router.post("/optimize", response_model=RouteOptimizationResponse)
async def optimize_routes(
    request: RouteOptimizationRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Evaluates alternative logistics corridors based on ETA, fuel/toll cost, and cold-chain spoilage risk.
    """
    return RouteOptimizer.optimize_routes(request)
