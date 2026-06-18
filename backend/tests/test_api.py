"""Smoke tests that run without network or an API key (heuristic fallbacks)."""

from fastapi.testclient import TestClient

from app.main import app
from app.ai import extract_workout, recommend_meals
from app.schemas import MacroTargets

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True


def test_extract_with_pasted_caption():
    caption = """
    Killer arm day 💪 #fitness #gym
    Bicep Curls 3x12
    Tricep Dips 3x15
    Shoulder Press 4x10
    follow for more!
    https://example.com
    """
    r = client.post("/reels/extract", json={"url": "https://instagram.com/reel/x", "caption": caption})
    assert r.status_code == 200
    body = r.json()
    assert body["needsManualCaption"] is False
    assert body["sourceURL"] == "https://instagram.com/reel/x"
    # Heuristic parser should find at least the curls/dips/press lines.
    names = [e["name"].lower() for e in body["exercises"]]
    assert any("curl" in n for n in names)


def test_heuristic_workout_categorizes_arms():
    parsed = extract_workout("Bicep Curls 3x12\nTricep Dips 3x15\nPush-up 3x20")
    assert parsed["category"].value in {"arms", "fullBody"}
    assert len(parsed["exercises"]) >= 2


def test_strava_config_not_configured():
    r = client.get("/strava/config")
    assert r.status_code == 200
    body = r.json()
    assert "clientId" in body and "configured" in body


def test_strava_exchange_requires_config():
    # No client id/secret in the test env → should be a clean 503, not a crash.
    r = client.post("/strava/exchange", json={"code": "abc"})
    assert r.status_code == 503


def test_heuristic_meals_fit_budget():
    meals = recommend_meals(
        MacroTargets(kcal=600, proteinG=50, carbsG=60, fatG=20), "any", ""
    )
    assert meals
    assert all(m.kcal <= 600 for m in meals)
