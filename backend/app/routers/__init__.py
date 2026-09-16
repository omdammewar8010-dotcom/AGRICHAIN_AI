from .risk import router as risk_router
from .delay import router as delay_router
from .routes import router as routes_router
from .ai import router as ai_router
from .iot import router as iot_router
from .simulation import router as simulation_router
from .analytics import router as analytics_router

__all__ = [
    "risk_router",
    "delay_router",
    "routes_router",
    "ai_router",
    "iot_router",
    "simulation_router",
    "analytics_router",
]
