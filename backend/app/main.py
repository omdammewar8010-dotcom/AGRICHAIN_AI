import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.firebase import initialize_firebase
from app.routers import (
    risk_router,
    delay_router,
    routes_router,
    ai_router,
    iot_router,
    simulation_router,
    analytics_router,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("agrichain.main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing AgriChain AI Backend Services...")
    initialize_firebase()
    yield
    logger.info("Shutting down AgriChain AI Backend Services...")


app = FastAPI(
    title="🌾 AgriChain AI - Intelligence Backend",
    description=(
        "AI-Powered Real-Time Agricultural Supply Chain Tracking, Risk Prediction & Logistics Optimization Platform. "
        "Coordinates ML inference, Explainable AI (SHAP), Gemini AI diagnostics, Route Optimization, and IoT ingestion."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API Routers under /api/v1
api_prefix = settings.API_V1_STR
app.include_router(risk_router, prefix=api_prefix)
app.include_router(delay_router, prefix=api_prefix)
app.include_router(routes_router, prefix=api_prefix)
app.include_router(ai_router, prefix=api_prefix)
app.include_router(iot_router, prefix=api_prefix)
app.include_router(simulation_router, prefix=api_prefix)
app.include_router(analytics_router, prefix=api_prefix)


@app.get("/", tags=["Health"])
def root_endpoint():
    return {
        "service": "AgriChain AI Intelligence Layer",
        "status": "operational",
        "version": "1.0.0",
        "docs": "/docs",
        "philosophy": "DETECT -> PREDICT -> EXPLAIN -> OPTIMIZE -> ACT -> TRACE",
    }


@app.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy",
        "environment": settings.ENVIRONMENT,
        "debug": settings.DEBUG,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
