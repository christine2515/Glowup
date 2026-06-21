"""Pydantic models shared across the API. These mirror the Swift structs
the iOS app decodes (see ios/Glowup/Services/BackendClient.swift)."""

from __future__ import annotations

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class Category(str, Enum):
    arms = "arms"
    abs = "abs"
    legs = "legs"
    fullBody = "fullBody"
    cardio = "cardio"
    mobility = "mobility"
    other = "other"


class ExerciseOut(BaseModel):
    name: str
    instructions: str = ""
    sets: Optional[int] = None
    reps: Optional[int] = None
    duration_sec: Optional[int] = Field(default=None, alias="durationSec")
    rest_sec: Optional[int] = Field(default=None, alias="restSec")
    equipment: Optional[str] = None

    model_config = {"populate_by_name": True}


class ExtractRequest(BaseModel):
    url: str
    # Optional caption the user pasted from Instagram. When the automatic
    # fetch is blocked, the app sends this so extraction can still proceed.
    caption: Optional[str] = None


class ExtractResponse(BaseModel):
    title: str
    category: Category
    summary: str = ""
    exercises: list[ExerciseOut] = []
    source_url: str = Field(alias="sourceURL")
    thumbnail_url: Optional[str] = Field(default=None, alias="thumbnailURL")
    caption: Optional[str] = None
    # True when we couldn't read the reel automatically and need the user
    # to paste the caption, retrying the request with it filled in.
    needs_manual_caption: bool = Field(default=False, alias="needsManualCaption")

    model_config = {"populate_by_name": True}


class MacroTargets(BaseModel):
    kcal: float
    protein_g: float = Field(alias="proteinG")
    carbs_g: float = Field(alias="carbsG")
    fat_g: float = Field(alias="fatG")

    model_config = {"populate_by_name": True}


class RecommendRequest(BaseModel):
    remaining: MacroTargets
    meal_type: str = Field(default="any", alias="mealType")  # breakfast/lunch/dinner/snack/any
    preferences: str = ""  # free text: "high protein, vegetarian, quick"

    model_config = {"populate_by_name": True}


class MealSuggestion(BaseModel):
    name: str
    description: str
    kcal: float
    protein_g: float = Field(alias="proteinG")
    carbs_g: float = Field(alias="carbsG")
    fat_g: float = Field(alias="fatG")
    ingredients: list[str] = []

    model_config = {"populate_by_name": True}


class RecommendResponse(BaseModel):
    suggestions: list[MealSuggestion] = []


class FoodItemOut(BaseModel):
    name: str
    serving: str
    kcal: float
    protein_g: float = Field(alias="proteinG")
    carbs_g: float = Field(alias="carbsG")
    fat_g: float = Field(alias="fatG")

    model_config = {"populate_by_name": True}


class FoodSearchResponse(BaseModel):
    items: list[FoodItemOut] = []
