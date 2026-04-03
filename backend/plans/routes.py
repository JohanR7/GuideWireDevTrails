"""
plans/routes.py
----------------
GET  /api/v1/plans/list              → list all plans with dynamic pricing for user's zone
GET  /api/v1/plans/<plan_id>/details → detailed plan info
GET  /api/v1/plans/recommend         → AI-generated recommendation for current user
POST /api/v1/plans/seed              → (dev only) seed default plans into DB
"""

from flask import Blueprint, request, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity

from extensions import db
from models.models import Plan, WorkerProfile, BackgroundCheck, User
from utils.helpers import generate_uuid, success_response, error_response
from plans.ai_recommender import recommend_plan

plans_bp = Blueprint("plans", __name__, url_prefix="/api/v1/plans")


# ---------------------------------------------------------------------------
# Default plan definitions (used for DB seed)
# ---------------------------------------------------------------------------

DEFAULT_PLANS = [
    {
        "tier": "ESSENTIAL",
        "worker_contribution": 8.0,
        "subsidy_amount": 22.0,
        "total_premium": 30.0,
        "max_payout": 250.0,
        "coverage_description": "Single disruption event coverage. Ideal for low-income earners in low-risk zones.",
        "min_income": 10000.0,
        "max_income": 14000.0,
    },
    {
        "tier": "STANDARD",
        "worker_contribution": 15.0,
        "subsidy_amount": 33.0,
        "total_premium": 48.0,
        "max_payout": 500.0,
        "coverage_description": "Multi-disruption coverage with broader event triggers. Suited for mid-income earners.",
        "min_income": 14000.0,
        "max_income": 18000.0,
    },
    {
        "tier": "PREMIUM",
        "worker_contribution": 25.0,
        "subsidy_amount": 47.0,
        "total_premium": 72.0,
        "max_payout": 800.0,
        "coverage_description": "Comprehensive protection for high-income workers and flood-zone riders.",
        "min_income": 18000.0,
        "max_income": 9999999.0,
    },
]

ZONE_MULTIPLIERS = {"Z1": 1.0, "Z2": 1.10, "Z3": 1.25, "Z4": 1.40}


def _apply_zone_pricing(plan: Plan, risk_zone: str) -> dict:
    """Apply dynamic zone-based multiplier to worker contribution."""
    multiplier = ZONE_MULTIPLIERS.get(risk_zone, 1.0)
    base = plan.to_dict()
    adjusted_contribution = round(float(plan.worker_contribution) * multiplier, 2)
    base["worker_contribution"] = adjusted_contribution
    base["total_premium"] = round(adjusted_contribution + float(plan.subsidy_amount), 2)
    base["zone_multiplier"] = multiplier
    base["risk_zone"] = risk_zone
    return base


# ---------------------------------------------------------------------------
# Seed Plans (dev helper)
# ---------------------------------------------------------------------------
@plans_bp.route("/seed", methods=["POST"])
def seed_plans():
    """Idempotent seed endpoint — only run once in dev."""
    if Plan.query.count() > 0:
        return success_response({"count": Plan.query.count()}, "Plans already seeded.")

    for p in DEFAULT_PLANS:
        plan = Plan(plan_id=generate_uuid(), **p)
        db.session.add(plan)

    db.session.commit()
    return success_response({"seeded": len(DEFAULT_PLANS)}, "Plans seeded.", 201)


# ---------------------------------------------------------------------------
# List All Plans
# ---------------------------------------------------------------------------
@plans_bp.route("/list", methods=["GET"])
@jwt_required()
def list_plans():
    """
    Query: ?risk_zone=Z1 (optional, defaults to user's profile zone)
    Returns all plans with dynamic pricing applied + recommended flag.
    """
    user_id = get_jwt_identity()
    risk_zone = request.args.get("risk_zone")

    if not risk_zone:
        profile = WorkerProfile.query.filter_by(user_id=user_id).first()
        risk_zone = profile.risk_zone if profile else "Z1"

    plans = Plan.query.filter_by(is_active=True).all()
    if not plans:
        return error_response("No plans found. Run /api/v1/plans/seed first.", 404)

    # Get recommended tier for this user
    recommended_tier = None
    profile = WorkerProfile.query.filter_by(user_id=user_id).first()
    user = User.query.filter_by(user_id=user_id).first()
    if profile:
        checks = BackgroundCheck.query.filter_by(user_id=user_id).all()
        cleared = all(c.status == "PASSED" for c in checks) if checks else True
        rec = recommend_plan(
            risk_zone=risk_zone,
            avg_monthly_income=float(profile.avg_monthly_income or 0),
            platform=profile.platform,
            city=user.city or "",
            background_cleared=cleared,
        )
        recommended_tier = rec.recommended_tier

    result = []
    for plan in plans:
        p_dict = _apply_zone_pricing(plan, risk_zone)
        p_dict["recommended"] = (plan.tier == recommended_tier)
        result.append(p_dict)

    return success_response(
        {
            "plans": result,
            "risk_zone": risk_zone,
            "recommended_tier": recommended_tier,
        }
    )


# ---------------------------------------------------------------------------
# Plan Details
# ---------------------------------------------------------------------------
@plans_bp.route("/<string:plan_id>/details", methods=["GET"])
@jwt_required()
def plan_details(plan_id: str):
    """
    Returns trigger conditions, payout schedule, exclusions, subsidy breakdown,
    and sample payout scenarios.
    """
    plan = Plan.query.filter_by(plan_id=plan_id, is_active=True).first()
    if not plan:
        return error_response("Plan not found.", 404)

    user_id = get_jwt_identity()
    profile = WorkerProfile.query.filter_by(user_id=user_id).first()
    risk_zone = profile.risk_zone if profile else "Z1"

    base = _apply_zone_pricing(plan, risk_zone)

    # Add detailed trigger conditions per tier
    trigger_map = {
        "ESSENTIAL": {
            "rain_threshold_mm_hr": 50,
            "aqi_threshold": 400,
            "temp_threshold_c": 42,
            "platform_outage_minutes": 15,
            "civic_confidence": 0.85,
        },
        "STANDARD": {
            "rain_threshold_mm_hr": 35,
            "aqi_threshold": 350,
            "temp_threshold_c": 40,
            "platform_outage_minutes": 10,
            "civic_confidence": 0.80,
        },
        "PREMIUM": {
            "rain_threshold_mm_hr": 20,
            "aqi_threshold": 300,
            "temp_threshold_c": 38,
            "platform_outage_minutes": 8,
            "civic_confidence": 0.75,
        },
    }

    exclusions = [
        "Disruptions due to worker's own fault or misconduct",
        "Events outside registered delivery zones",
        "Claims submitted >48 hours after disruption event",
        "Workers with active fraud flags on profile",
    ]

    sample_payouts = [
        {
            "scenario": "Heavy rain disruption (3 hrs)",
            "payout": round(float(plan.max_payout) * 0.4, 2),
            "notes": "40% of weekly max for partial disruption.",
        },
        {
            "scenario": "Platform outage (full peak window)",
            "payout": round(float(plan.max_payout) * 0.7, 2),
            "notes": "70% for full peak-hour outage.",
        },
        {
            "scenario": "Civic disruption (curfew/strike)",
            "payout": float(plan.max_payout),
            "notes": "100% max payout for confirmed civic events.",
        },
    ]

    base.update(
        {
            "triggers": trigger_map.get(plan.tier, {}),
            "exclusions": exclusions,
            "sample_payouts": sample_payouts,
            "payout_schedule": "Within 10 minutes for trust_score > 0.9; 30 min for step-up; manual otherwise.",
            "subsidy_breakdown": {
                "worker_pays": base["worker_contribution"],
                "platform_subsidy": float(plan.subsidy_amount),
                "total_pool_contribution": base["total_premium"],
            },
            "policy_period": "Weekly, renewing every Sunday.",
        }
    )

    return success_response({"plan": base})


# ---------------------------------------------------------------------------
# AI Recommendation for Current User
# ---------------------------------------------------------------------------
@plans_bp.route("/recommend", methods=["GET"])
@jwt_required()
def get_recommendation():
    """
    Returns the AI model recommendation for the currently authenticated worker.
    """
    user_id = get_jwt_identity()
    profile = WorkerProfile.query.filter_by(user_id=user_id).first()
    user = User.query.filter_by(user_id=user_id).first()

    if not profile:
        return error_response("Worker profile not found. Complete registration first.", 404)

    checks = BackgroundCheck.query.filter_by(user_id=user_id).all()
    background_cleared = all(c.status == "PASSED" for c in checks) if checks else True

    rec = recommend_plan(
        risk_zone=profile.risk_zone or "Z1",
        avg_monthly_income=float(profile.avg_monthly_income or 0),
        platform=profile.platform,
        city=user.city or "",
        background_cleared=background_cleared,
    )

    # Find the recommended plan record
    recommended_plan = Plan.query.filter_by(tier=rec.recommended_tier, is_active=True).first()

    return success_response(
        {
            "recommended_tier": rec.recommended_tier,
            "confidence_score": rec.confidence_score,
            "risk_score": rec.risk_score,
            "dynamic_multiplier": rec.dynamic_multiplier,
            "shap_factors": rec.shap_factors,
            "reasoning": rec.reasoning,
            "recommended_plan": recommended_plan.to_dict() if recommended_plan else None,
            "next_recalculation": "Every Wednesday",
        }
    )