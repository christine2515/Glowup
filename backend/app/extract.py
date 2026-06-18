"""Fetch public metadata (caption + thumbnail) for an Instagram reel.

This uses yt-dlp, which reads the public page. It is unofficial and may break
when Instagram changes things, so every caller must handle a None result and
fall back to a user-pasted caption.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Optional

log = logging.getLogger("reelfit.extract")


@dataclass
class ReelMeta:
    caption: str
    thumbnail_url: Optional[str]
    duration_sec: Optional[int]


def fetch_reel_meta(url: str) -> Optional[ReelMeta]:
    """Return caption/thumbnail for a reel, or None if it can't be read."""
    try:
        import yt_dlp
    except ImportError:  # dependency not installed
        log.warning("yt-dlp not installed; cannot auto-fetch reel")
        return None

    opts = {
        "quiet": True,
        "no_warnings": True,
        "skip_download": True,
        "extract_flat": False,
    }
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False)
    except Exception as exc:  # network, login wall, rate limit, format change
        log.warning("yt-dlp failed for %s: %s", url, exc)
        return None

    if not info:
        return None

    caption = info.get("description") or info.get("title") or ""
    thumbnail = info.get("thumbnail")
    duration = info.get("duration")
    duration = int(duration) if isinstance(duration, (int, float)) else None

    return ReelMeta(caption=caption.strip(), thumbnail_url=thumbnail, duration_sec=duration)
