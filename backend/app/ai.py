"""Claude-powered structured extraction and meal recommendations.

Both functions degrade gracefully: if no ANTHROPIC_API_KEY is configured the
module falls back to simple heuristics so the app is still usable offline /
without a key.
"""

from __future__ import annotations

import json
import logging
import os
import re
from typing import Optional

from .schemas import (
    Category,
    ExerciseOut,
    MacroTargets,
    MealSuggestion,
)

log = logging.getLogger("reelfit.ai")

MODEL = os.environ.get("REELFIT_MODEL", "claude-sonnet-4-6")


def _client():
    """Return an Anthropic client, or None if no key is set."""
    key = os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        return None
    try:
        from anthropic import Anthropic
    except ImportError:
        log.warning("anthropic SDK not installed")
        return None
    return Anthropic(api_key=key)


# --------------------------------------------------------------------------- #
# Workout extraction
# --------------------------------------------------------------------------- #

_EXTRACT_SYSTEM = """You convert Instagram fitness-reel text into a structured \
workout. The text may be a caption, on-screen text, or an audio transcript and \
is often messy (emojis, hashtags, promo lines).

Rules:
- Extract only the actual exercises/movements of the workout.
- Ignore promo, hashtags, follow-for-more, links, and unrelated chatter.
- For each exercise give a clean name and a short plain-language "how to do it" \
instruction (1-2 sentences). Infer reasonable form cues if the source omits them.
- Fill sets/reps/duration/rest only when stated or strongly implied; otherwise \
leave them null.
- Pick one category that best fits the whole workout: arms, abs, legs, \
fullBody, cardio, mobility, or other.
- Give a short title and a one-line summary.
- If the text contains no real workout, return an empty exercises list."""

_SAVE_WORKOUT_TOOL = {
    "name": "save_workout",
    "description": "Save the structured workout extracted from the reel text.",
    "input_schema": {
        "type": "object",
        "properties": {
            "title": {"type": "string"},
            "category": {
                "type": "string",
                "enum": [c.value for c in Category],
            },
            "summary": {"type": "string"},
            "exercises": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "instructions": {"type": "string"},
                        "sets": {"type": ["integer", "null"]},
                        "reps": {"type": ["integer", "null"]},
                        "durationSec": {"type": ["integer", "null"]},
                        "restSec": {"type": ["integer", "null"]},
                        "equipment": {"type": ["string", "null"]},
                    },
                    "required": ["name", "instructions"],
                },
            },
        },
        "required": ["title", "category", "exercises"],
    },
}


def extract_workout(text: str) -> dict:
    """Return {title, category, summary, exercises:[ExerciseOut...]}."""
    text = (text or "").strip()
    if not text:
        return {"title": "Workout", "category": Category.other, "summary": "", "exercises": []}

    client = _client()
    if client is None:
        return _heuristic_workout(text)

    try:
        resp = client.messages.create(
            model=MODEL,
            max_tokens=2000,
            system=[
                {
                    "type": "text",
                    "text": _EXTRACT_SYSTEM,
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            tools=[_SAVE_WORKOUT_TOOL],
            tool_choice={"type": "tool", "name": "save_workout"},
            messages=[{"role": "user", "content": f"Reel text:\n\n{text}"}],
        )
    except Exception as exc:
        log.warning("Claude extraction failed, using heuristic: %s", exc)
        return _heuristic_workout(text)

    data = _first_tool_input(resp)
    if not data:
        return _heuristic_workout(text)

    exercises = [
        ExerciseOut(
            name=e.get("name", "").strip(),
            instructions=(e.get("instructions") or "").strip(),
            sets=e.get("sets"),
            reps=e.get("reps"),
            durationSec=e.get("durationSec"),
            restSec=e.get("restSec"),
            equipment=e.get("equipment"),
        )
        for e in data.get("exercises", [])
        if e.get("name")
    ]
    try:
        category = Category(data.get("category", "other"))
    except ValueError:
        category = Category.other

    return {
        "title": data.get("title") or "Workout",
        "category": category,
        "summary": data.get("summary") or "",
        "exercises": exercises,
    }


# --------------------------------------------------------------------------- #
# Meal recommendations
# --------------------------------------------------------------------------- #

_RECOMMEND_SYSTEM = """You are a sports-nutrition assistant. Given a person's \
REMAINING calories and macros for the day plus their preferences, suggest 3 \
realistic meals/snacks that fit within the remaining budget (do not exceed \
calories; get protein as close to the remaining protein as is reasonable). \
Keep meals practical to make. Respect dietary preferences exactly."""

_SUGGEST_TOOL = {
    "name": "suggest_meals",
    "description": "Return meal suggestions that fit the remaining macro budget.",
    "input_schema": {
        "type": "object",
        "properties": {
            "suggestions": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "description": {"type": "string"},
                        "kcal": {"type": "number"},
                        "proteinG": {"type": "number"},
                        "carbsG": {"type": "number"},
                        "fatG": {"type": "number"},
                        "ingredients": {"type": "array", "items": {"type": "string"}},
                    },
                    "required": ["name", "description", "kcal", "proteinG", "carbsG", "fatG"],
                },
            }
        },
        "required": ["suggestions"],
    },
}


def recommend_meals(
    remaining: MacroTargets, meal_type: str, preferences: str
) -> list[MealSuggestion]:
    client = _client()
    if client is None:
        return _heuristic_meals(remaining)

    user = (
        f"Remaining today: {remaining.kcal:.0f} kcal, "
        f"{remaining.protein_g:.0f}g protein, {remaining.carbs_g:.0f}g carbs, "
        f"{remaining.fat_g:.0f}g fat.\n"
        f"Meal type: {meal_type}\n"
        f"Preferences: {preferences or 'none'}"
    )
    try:
        resp = client.messages.create(
            model=MODEL,
            max_tokens=1500,
            system=[
                {
                    "type": "text",
                    "text": _RECOMMEND_SYSTEM,
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            tools=[_SUGGEST_TOOL],
            tool_choice={"type": "tool", "name": "suggest_meals"},
            messages=[{"role": "user", "content": user}],
        )
    except Exception as exc:
        log.warning("Claude meal recommendation failed: %s", exc)
        return _heuristic_meals(remaining)

    data = _first_tool_input(resp)
    if not data:
        return _heuristic_meals(remaining)

    out: list[MealSuggestion] = []
    for s in data.get("suggestions", []):
        try:
            out.append(
                MealSuggestion(
                    name=s["name"],
                    description=s.get("description", ""),
                    kcal=s["kcal"],
                    proteinG=s["proteinG"],
                    carbsG=s["carbsG"],
                    fatG=s["fatG"],
                    ingredients=s.get("ingredients", []),
                )
            )
        except (KeyError, TypeError):
            continue
    return out or _heuristic_meals(remaining)


# --------------------------------------------------------------------------- #
# Helpers / fallbacks
# --------------------------------------------------------------------------- #

def _first_tool_input(resp) -> Optional[dict]:
    for block in resp.content:
        if getattr(block, "type", None) == "tool_use":
            return block.input
    return None


_CATEGORY_HINTS = {
    Category.arms: ["bicep", "tricep", "curl", "arm", "shoulder", "push-up", "pushup", "press"],
    Category.abs: ["ab", "core", "crunch", "plank", "sit-up", "situp", "oblique"],
    Category.legs: ["leg", "squat", "lunge", "glute", "calf", "hamstring", "quad"],
    Category.cardio: ["run", "cardio", "hiit", "jump", "burpee", "sprint"],
    Category.mobility: ["stretch", "mobility", "yoga", "flexibility"],
}

_LINE_RE = re.compile(
    r"""^\s*
    (?:[-*••\d.)\s]+)?       # bullet / number prefix
    (?P<name>[A-Za-z][A-Za-z'/\- ]{1,50}?)
    \s*[:\-–]?\s*
    (?:(?P<sets>\d+)\s*[xX×]\s*(?P<reps>\d+))?   # 3x12
    (?:\s*(?P<dur>\d+)\s*(?:sec|secs|s|seconds))?
    \s*$""",
    re.VERBOSE,
)


def _heuristic_workout(text: str) -> dict:
    """No-API fallback: best-effort line parsing of the caption."""
    exercises: list[ExerciseOut] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "http" in line:
            continue
        m = _LINE_RE.match(line)
        if not m or not m.group("name"):
            continue
        name = m.group("name").strip().title()
        if len(name) < 3:
            continue
        exercises.append(
            ExerciseOut(
                name=name,
                instructions="",
                sets=int(m.group("sets")) if m.group("sets") else None,
                reps=int(m.group("reps")) if m.group("reps") else None,
                durationSec=int(m.group("dur")) if m.group("dur") else None,
            )
        )

    lower = text.lower()
    category = Category.fullBody
    best = 0
    for cat, hints in _CATEGORY_HINTS.items():
        score = sum(lower.count(h) for h in hints)
        if score > best:
            best, category = score, cat

    return {
        "title": "Imported Workout",
        "category": category,
        "summary": "Parsed from caption (no AI key set).",
        "exercises": exercises[:30],
    }


def _heuristic_meals(remaining: MacroTargets) -> list[MealSuggestion]:
    kcal = max(remaining.kcal, 0)
    return [
        MealSuggestion(
            name="Greek yogurt + berries + granola",
            description="Quick high-protein snack/breakfast.",
            kcal=min(kcal, 350),
            proteinG=min(remaining.protein_g, 25),
            carbsG=40,
            fatG=8,
            ingredients=["Greek yogurt", "mixed berries", "granola"],
        ),
        MealSuggestion(
            name="Chicken & rice bowl",
            description="Balanced lean-protein meal.",
            kcal=min(kcal, 550),
            proteinG=min(remaining.protein_g, 45),
            carbsG=55,
            fatG=12,
            ingredients=["chicken breast", "rice", "broccoli", "olive oil"],
        ),
    ]
