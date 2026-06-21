"""Food macro lookup via USDA FoodData Central (free API).

Docs: https://fdc.nal.usda.gov/api-guide.html
"""

from __future__ import annotations

import logging
import os
from typing import Optional

import httpx

from .schemas import FoodItemOut

log = logging.getLogger("glowup.nutrition")

_SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"

# USDA nutrient numbers.
_KCAL = "208"
_PROTEIN = "203"
_FAT = "204"
_CARB = "205"


def _nutrient_map(food: dict) -> dict[str, float]:
    out: dict[str, float] = {}
    for n in food.get("foodNutrients", []):
        num = str(n.get("nutrientNumber") or n.get("number") or "")
        val = n.get("value")
        if num and isinstance(val, (int, float)):
            out[num] = float(val)
    return out


def search_foods(query: str, limit: int = 15) -> list[FoodItemOut]:
    query = (query or "").strip()
    if not query:
        return []

    key = os.environ.get("USDA_API_KEY", "DEMO_KEY")
    params = {
        "api_key": key,
        "query": query,
        "pageSize": limit,
        "dataType": "Foundation,SR Legacy,Branded",
    }
    try:
        resp = httpx.get(_SEARCH_URL, params=params, timeout=15)
        resp.raise_for_status()
        data = resp.json()
    except Exception as exc:
        log.warning("USDA search failed for %r: %s", query, exc)
        return []

    items: list[FoodItemOut] = []
    for food in data.get("foods", []):
        nm = _nutrient_map(food)
        kcal = nm.get(_KCAL)
        if kcal is None:
            continue  # skip rows without energy data
        serving = _serving_label(food)
        items.append(
            FoodItemOut(
                name=(food.get("description") or "Food").title(),
                serving=serving,
                kcal=kcal,
                proteinG=nm.get(_PROTEIN, 0.0),
                carbsG=nm.get(_CARB, 0.0),
                fatG=nm.get(_FAT, 0.0),
            )
        )
    return items


def _serving_label(food: dict) -> str:
    size = food.get("servingSize")
    unit = food.get("servingSizeUnit")
    if size and unit:
        return f"{size:g} {unit}"
    return "per 100 g"
