"""Strava OAuth token exchange/refresh.

The mobile app handles the user-facing OAuth (ASWebAuthenticationSession) and
fetches activities directly from the Strava API with the access token. Only the
parts that need the client secret live here.

Set in .env:
    STRAVA_CLIENT_ID=...
    STRAVA_CLIENT_SECRET=...
"""

from __future__ import annotations

import logging
import os

import httpx
from fastapi import HTTPException

log = logging.getLogger("reelfit.strava")

_TOKEN_URL = "https://www.strava.com/oauth/token"


def client_id() -> str:
    return os.environ.get("STRAVA_CLIENT_ID", "")


def is_configured() -> bool:
    return bool(client_id() and os.environ.get("STRAVA_CLIENT_SECRET"))


def _token_request(extra: dict) -> dict:
    if not is_configured():
        raise HTTPException(status_code=503, detail="Strava not configured on the backend.")
    payload = {
        "client_id": client_id(),
        "client_secret": os.environ.get("STRAVA_CLIENT_SECRET", ""),
        **extra,
    }
    try:
        resp = httpx.post(_TOKEN_URL, data=payload, timeout=20)
        resp.raise_for_status()
        data = resp.json()
    except httpx.HTTPStatusError as exc:
        log.warning("Strava token request failed: %s", exc.response.text)
        raise HTTPException(status_code=400, detail="Strava token request failed.") from exc
    except Exception as exc:
        log.warning("Strava token request error: %s", exc)
        raise HTTPException(status_code=502, detail="Could not reach Strava.") from exc

    return {
        "accessToken": data.get("access_token", ""),
        "refreshToken": data.get("refresh_token", ""),
        "expiresAt": data.get("expires_at", 0),
    }


def exchange_code(code: str) -> dict:
    return _token_request({"code": code, "grant_type": "authorization_code"})


def refresh(refresh_token: str) -> dict:
    return _token_request({"refresh_token": refresh_token, "grant_type": "refresh_token"})
