from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "operational"
    assert "DETECT" in data["philosophy"]


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


def test_simulation_status():
    response = client.get("/api/v1/simulation/status")
    assert response.status_code == 200
    data = response.json()
    assert "telemetry" in data
    assert "mlRisk" in data
    assert data["batchId"] == "AGRI-2026-TOM-000124"


def test_simulation_anomaly_injection():
    response = client.post(
        "/api/v1/simulation/inject",
        json={"anomalyType": "temp_spike", "magnitude": 34.0}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["telemetry"]["temperature"] == 34.0
    assert data["mlRisk"]["spoilageRisk"] > 60.0
    assert data["mlRisk"]["overallRisk"] > 40.0
