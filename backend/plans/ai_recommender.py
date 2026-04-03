"""
plans/ai_recommender.py
-----------------------
Mock AI model that recommends a plan tier based on:
  - risk_zone (Z1/Z2/Z3)
  - avg_monthly_income
  - platform (Swiggy/Zomato)
  - background check results
  - city

In production this would call the Transformer-CNN-LSTM model endpoint.
"""

from dataclasses import dataclass
from typing import Literal


PlanTier = Literal["ESSENTIAL", "STANDARD", "PREMIUM"]


@dataclass
class AIRecommendation:
    recommended_tier: PlanTier
    confidence_score: float          # 0–1
    dynamic_multiplier: float        # premium multiplier for this week
    risk_score: float                # 0–1 raw risk score
    shap_factors: dict               # top factors driving the recommendation
    reasoning: str


# ---------------------------------------------------------------------------
# Feature weights (mock SHAP values)
# ---------------------------------------------------------------------------

_ZONE_RISK = {"Z1": 0.2, "Z2": 0.5, "Z3": 0.85, "Z4": 0.95}
_INCOME_BANDS = [
    (0,     12000, "ESSENTIAL",  0.25),
    (12000, 14000, "ESSENTIAL",  0.30),
    (14000, 16000, "STANDARD",   0.45),
    (16000, 18000, "STANDARD",   0.55),
    (18000, 99999, "PREMIUM",    0.70),
]
_PLATFORM_FACTOR = {"SWIGGY": 0.05, "ZOMATO": 0.03}   # slight exposure diff
_HIGH_RISK_CITIES = {"chennai", "mumbai", "kolkata", "bhubaneswar", "patna"}


def recommend_plan(
    risk_zone: str,
    avg_monthly_income: float,
    platform: str,
    city: str = "",
    background_cleared: bool = True,
) -> AIRecommendation:
    """
    Pure-Python mock of the Transformer-CNN-LSTM risk model.
    Returns a structured recommendation with fake SHAP values.
    """
    zone_risk = _ZONE_RISK.get(risk_zone, 0.5)

    # Income-based baseline tier
    tier = "STANDARD"
    income_risk = 0.4
    for lo, hi, t, ir in _INCOME_BANDS:
        if lo <= avg_monthly_income < hi:
            tier = t
            income_risk = ir
            break

    # Uplift to PREMIUM for high-risk zone + high income
    platform_risk = _PLATFORM_FACTOR.get(platform.upper(), 0.04)
    city_risk = 0.15 if city.lower() in _HIGH_RISK_CITIES else 0.0

    raw_risk = (
        zone_risk * 0.45
        + income_risk * 0.30
        + platform_risk * 0.10
        + city_risk * 0.15
    )

    # Override tier based on composite risk
    if raw_risk >= 0.65:
        tier = "PREMIUM"
    elif raw_risk >= 0.40:
        tier = "STANDARD"
    else:
        tier = "ESSENTIAL"

    # Dynamic premium multiplier (would come from PPO RL model weekly)
    if zone_risk >= 0.80:
        multiplier = round(1.0 + (raw_risk * 0.4), 2)
    else:
        multiplier = round(1.0 + (raw_risk * 0.2), 2)

    multiplier = min(multiplier, 1.5)   # cap at 50% above base

    confidence = round(0.65 + (raw_risk * 0.3), 2)
    confidence = min(confidence, 0.98)

    shap = {
        "risk_zone": round(zone_risk * 0.45, 4),
        "income_level": round(income_risk * 0.30, 4),
        "platform_exposure": round(platform_risk * 0.10, 4),
        "city_flood_risk": round(city_risk * 0.15, 4),
    }

    if not background_cleared:
        tier = "ESSENTIAL"
        confidence = round(confidence * 0.8, 2)
        reasoning = (
            f"Background check concerns noted. "
            f"Restricted to ESSENTIAL tier until checks clear. "
            f"Risk score: {raw_risk:.2f}, Zone: {risk_zone}."
        )
    else:
        reasoning = (
            f"Based on risk zone {risk_zone}, monthly income ₹{avg_monthly_income:,.0f}, "
            f"and {platform} platform exposure, the {tier} plan is recommended. "
            f"Composite risk score: {raw_risk:.2f}. "
            f"Dynamic multiplier this week: {multiplier}x."
        )

    return AIRecommendation(
        recommended_tier=tier,
        confidence_score=confidence,
        dynamic_multiplier=multiplier,
        risk_score=round(raw_risk, 4),
        shap_factors=shap,
        reasoning=reasoning,
    )