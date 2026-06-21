"""Optional audio transcription for reels whose workout is only spoken in the
video (no usable caption).

Uses faster-whisper, which is a heavy/optional dependency:
    pip install -r requirements-transcription.txt

Everything degrades gracefully: if faster-whisper isn't installed, transcription
is disabled, and the API falls back to asking the user to paste the caption.
"""

from __future__ import annotations

import logging
import os
import shutil
from typing import Optional

log = logging.getLogger("glowup.transcribe")

_model = None  # cached WhisperModel


def _enabled() -> bool:
    return os.environ.get("GLOWUP_ENABLE_TRANSCRIPTION", "1").lower() in ("1", "true", "yes")


def _get_model():
    global _model
    if _model is not None:
        return _model
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        log.info("faster-whisper not installed; transcription disabled")
        return None
    size = os.environ.get("GLOWUP_WHISPER_MODEL", "base")
    log.info("loading whisper model: %s", size)
    _model = WhisperModel(size, device="cpu", compute_type="int8")
    return _model


def transcribe_audio(path: str) -> Optional[str]:
    model = _get_model()
    if model is None:
        return None
    try:
        segments, _info = model.transcribe(path)
        text = " ".join(seg.text.strip() for seg in segments).strip()
        return text or None
    except Exception as exc:
        log.warning("transcription failed: %s", exc)
        return None


def transcribe_reel(url: str) -> Optional[str]:
    """Download the reel's audio and transcribe it. Returns the transcript or
    None (not enabled, no model, download/transcribe failure)."""
    if not _enabled():
        return None
    if _get_model() is None:
        return None

    from .extract import download_audio

    path = download_audio(url)
    if not path:
        return None
    try:
        return transcribe_audio(path)
    finally:
        shutil.rmtree(os.path.dirname(path), ignore_errors=True)
