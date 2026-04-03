"""
registration/routes.py
-----------------------
Step 3: POST /api/v1/worker/profile  → save platform info, assign risk_zone
        GET  /api/v1/worker/profile  → get current profile
"""

from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from extensions import db
from models.models import User, WorkerProfile
from utils.helpers import (
    generate_uuid,
    success_response,
    error_response,
    require_verified_mobile,
)

registration_bp = Blueprint("registration", __name__, url_prefix="/api/v1/worker")

VALID_PLATFORMS = {"SWIGGY", "ZOMATO"}
VALID_ZONES = {"Z1", "Z2", "Z3", "Z4"}


def _assign_risk_zone(city: str, zones: list, income: float) -> str:
    """
    Simple deterministic mock risk zone assignment.
    Real system uses IMD forecast + historical data.
    Z1 = lowest risk, Z3 = highest risk.
    """
    high_risk_cities = {"chennai", "mumbai", "kolkata", "hyderabad"}
    city_lower = (city or "").lower()

    if city_lower in high_risk_cities or income < 12000:
        return "Z3"
    elif income < 16000:
        return "Z2"
    return "Z1"


# ---------------------------------------------------------------------------
# Create / Update Worker Profile
# ---------------------------------------------------------------------------
@registration_bp.route("/profile", methods=["POST"])
@jwt_required()
def create_profile():
    """
    Body: {
        platform,              # SWIGGY / ZOMATO
        delivery_partner_id,
        avg_monthly_income,
        primary_zones[],
        driving_license?
    }
    Returns: { profile_id, risk_zone }
    """
    user_id = get_jwt_identity()
    user = User.query.filter_by(user_id=user_id).first()
    if not user:
        return error_response("User not found.", 404)

    if not user.is_mobile_verified:
        return error_response("Mobile verification required before creating profile.", 403)

    data = request.get_json(silent=True) or {}

    # --- Validation ---
    required = ["platform", "delivery_partner_id", "avg_monthly_income"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return error_response(f"Missing required fields: {', '.join(missing)}", 422)

    platform = data["platform"].upper()
    if platform not in VALID_PLATFORMS:
        return error_response(f"platform must be one of: {', '.join(VALID_PLATFORMS)}", 422)

    try:
        income = float(data["avg_monthly_income"])
    except (TypeError, ValueError):
        return error_response("avg_monthly_income must be a number.", 422)

    primary_zones = data.get("primary_zones", [])
    if not isinstance(primary_zones, list):
        primary_zones = [primary_zones]

    # --- Upsert profile ---
    profile = WorkerProfile.query.filter_by(user_id=user_id).first()
    if profile:
        # Update existing
        profile.platform = platform
        profile.delivery_partner_id = data["delivery_partner_id"]
        profile.avg_monthly_income = income
        profile.primary_zones = primary_zones
        profile.driving_license = data.get("driving_license")
        profile.risk_zone = _assign_risk_zone(user.city, primary_zones, income)
    else:
        profile = WorkerProfile(
            profile_id=generate_uuid(),
            user_id=user_id,
            platform=platform,
            delivery_partner_id=data["delivery_partner_id"],
            avg_monthly_income=income,
            primary_zones=primary_zones,
            driving_license=data.get("driving_license"),
            risk_zone=_assign_risk_zone(user.city, primary_zones, income),
        )
        db.session.add(profile)

    db.session.commit()

    return success_response(
        {
            "profile_id": profile.profile_id,
            "risk_zone": profile.risk_zone,
            "profile": profile.to_dict(),
        },
        "Worker profile saved successfully.",
        201,
    )


# ---------------------------------------------------------------------------
# Get Worker Profile
# ---------------------------------------------------------------------------
@registration_bp.route("/profile", methods=["GET"])
@jwt_required()
def get_profile():
    user_id = get_jwt_identity()
    profile = WorkerProfile.query.filter_by(user_id=user_id).first()
    if not profile:
        return error_response("Profile not found. Please complete registration.", 404)
    return success_response({"profile": profile.to_dict()})


# ---------------------------------------------------------------------------
# Get Profile by user_id (admin / internal use)
# ---------------------------------------------------------------------------
@registration_bp.route("/profile/<string:uid>", methods=["GET"])
@jwt_required()
def get_profile_by_id(uid: str):
    profile = WorkerProfile.query.filter_by(user_id=uid).first()
    if not profile:
        return error_response("Profile not found.", 404)
    return success_response({"profile": profile.to_dict()})