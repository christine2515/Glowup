"""ReelFit backend API.

Run locally:
    cd backend
    python -m venv .venv && source .venv/bin/activate
    pip install -r requirements.txt
    cp .env.example .env   # add your ANTHROPIC_API_KEY
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

Then point the iOS app at http://<your-mac-ip>:8000
"""

from __future__ import annotations

import logging
import os

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException

from pydantic import BaseModel

from . import ai, extract, nutrition, strava, transcribe
from .schemas import (
    ExtractRequest,
    ExtractResponse,
    FoodSearchResponse,
    RecommendRequest,
    RecommendResponse,
)

load_dotenv()
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="ReelFit API", version="0.1.0")


def _check_token(token: str | None) -> None:
    expected = os.environ.get("REELFIT_API_TOKEN", "")
    if expected and token != expected:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.get("/health")
def health() -> dict:
    return {"ok": True, "ai": bool(os.environ.get("ANTHROPIC_API_KEY"))}


@app.post("/reels/extract", response_model=ExtractResponse)
def extract_reel(
    req: ExtractRequest,
    x_reelfit_token: str | None = Header(default=None),
) -> ExtractResponse:
    _check_token(x_reelfit_token)

    caption = req.caption
    thumbnail = None

    # Prefer the user-pasted caption; otherwise try to fetch it automatically.
    if not caption:
        meta = extract.fetch_reel_meta(req.url)
        if meta:
            caption = meta.caption
            thumbnail = meta.thumbnail_url

    # If still nothing, try transcribing the video's audio (caption-less reels).
    if not caption:
        caption = transcribe.transcribe_reel(req.url)

    if not caption:
        # Couldn't read the reel and nothing pasted — ask the app to retry
        # with a manually pasted caption.
        return ExtractResponse(
            title="Couldn't read this reel",
            category="other",
            summary="",
            exercises=[],
            sourceURL=req.url,
            thumbnailURL=thumbnail,
            needsManualCaption=True,
        )

    parsed = ai.extract_workout(caption)
    return ExtractResponse(
        title=parsed["title"],
        category=parsed["category"],
        summary=parsed["summary"],
        exercises=parsed["exercises"],
        sourceURL=req.url,
        thumbnailURL=thumbnail,
        caption=caption,
        needsManualCaption=False,
    )


@app.post("/nutrition/recommend", response_model=RecommendResponse)
def recommend(
    req: RecommendRequest,
    x_reelfit_token: str | None = Header(default=None),
) -> RecommendResponse:
    _check_token(x_reelfit_token)
    suggestions = ai.recommend_meals(req.remaining, req.meal_type, req.preferences)
    return RecommendResponse(suggestions=suggestions)


@app.get("/nutrition/search", response_model=FoodSearchResponse)
def food_search(
    q: str,
    x_reelfit_token: str | None = Header(default=None),
) -> FoodSearchResponse:
    _check_token(x_reelfit_token)
    return FoodSearchResponse(items=nutrition.search_foods(q))


# ----------------------------- Strava ------------------------------------- #

class StravaConfig(BaseModel):
    clientId: str
    configured: bool


class StravaCodeBody(BaseModel):
    code: str


class StravaRefreshBody(BaseModel):
    refreshToken: str


class StravaTokens(BaseModel):
    accessToken: str
    refreshToken: str
    expiresAt: int


@app.get("/strava/config", response_model=StravaConfig)
def strava_config(x_reelfit_token: str | None = Header(default=None)) -> StravaConfig:
    _check_token(x_reelfit_token)
    return StravaConfig(clientId=strava.client_id(), configured=strava.is_configured())


@app.post("/strava/exchange", response_model=StravaTokens)
def strava_exchange(
    body: StravaCodeBody, x_reelfit_token: str | None = Header(default=None)
) -> StravaTokens:
    _check_token(x_reelfit_token)
    return StravaTokens(**strava.exchange_code(body.code))


@app.post("/strava/refresh", response_model=StravaTokens)
def strava_refresh(
    body: StravaRefreshBody, x_reelfit_token: str | None = Header(default=None)
) -> StravaTokens:
    _check_token(x_reelfit_token)
    return StravaTokens(**strava.refresh(body.refreshToken))
