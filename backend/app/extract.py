"""Fetch public metadata (caption + thumbnail) for an Instagram reel.

This uses yt-dlp, which reads the public page. It is unofficial and may break
when Instagram changes things, so every caller must handle a None result and
fall back to a user-pasted caption.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Optional

log = logging.getLogger("glowup.extract")


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


def download_audio(url: str) -> Optional[str]:
    """Download the reel's best audio track to a temp file. Returns the path
    (caller is responsible for cleaning up the parent dir), or None on failure.
    No ffmpeg required — we keep the native container (m4a/webm)."""
    try:
        import yt_dlp
    except ImportError:
        return None

    import os
    import tempfile

    tmpdir = tempfile.mkdtemp(prefix="glowup_")
    outtmpl = os.path.join(tmpdir, "audio.%(ext)s")
    opts = {
        "quiet": True,
        "no_warnings": True,
        "noplaylist": True,
        "format": "bestaudio/best",
        "outtmpl": outtmpl,
    }
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)
        ext = info.get("ext", "m4a")
        path = os.path.join(tmpdir, f"audio.{ext}")
        if os.path.exists(path):
            return path
        files = [os.path.join(tmpdir, f) for f in os.listdir(tmpdir)]
        return files[0] if files else None
    except Exception as exc:
        log.warning("audio download failed for %s: %s", url, exc)
        return None
