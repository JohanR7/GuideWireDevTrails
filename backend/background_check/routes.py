"""
background_check/routes.py
---------------------------
POST /api/v1/background-check/platform   → verify Swiggy/Zomato partner
POST /api/v1/background-check/license    → verify driving licence
GET  /api/v1/background-check/status     → get all checks for current user
GET  /api/v1/background-check/<check_id> → single check result
"""

from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from extensions import db
from models.models import WorkerProfile, BackgroundCheck
from utils.helpers import generate_uuid, success_response, error_response
from background_check.mock_apis import (
    verify_swiggy_partner,
    verify_zomato_partner,
    verify_driving_license,
)

bg_bp = Blueprint("background_check", __name__, url_prefix="/api/v1/background-check")


def _map_status(verified: bool, raw_status: str) -> str:
    """Map external API status to our internal status."""
    if verified:
        return "PASSED"
    if raw_status in ("SUSPENDED", "EXPIRED"):
        return "FAILED"
    if raw_status == "NOT_FOUND":
        return "FAILED"
    return "MANUAL_REVIEW"


# ---------------------------------------------------------------------------
# Platform (Swiggy / Zomato) Background Check
# ---------------------------------------------------------------------------
@bg_bp.route("/platform", methods=["POST"])
@jwt_required()
def platform_check():
    """
    Body: { platform, delivery_partner_id }
    Calls the mock Swiggy or Zomato verification API.
    Returns: check_id, status, details
    """
    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    platform = data.get("platform", "").upper()
    partner_id = data.get("delivery_partner_id", "").strip()

    if not platform or not partner_id:
        return error_response("platform and delivery_partner_id are required.", 422)

    if platform not in ("SWIGGY", "ZOMATO"):
        return error_response("platform must be SWIGGY or ZOMATO.", 422)

    # --- Call mock API ---
    if platform == "SWIGGY":
        result = verify_swiggy_partner(partner_id)
    else:
        result = verify_zomato_partner(partner_id)

    status = _map_status(result["verified"], result.get("status", ""))
    notes = result.get("reason") if not result["verified"] else f"Active partner — rating {result.get('rating')}"

    # --- Persist check record ---
    check = BackgroundCheck(
        check_id=generate_uuid(),
        user_id=user_id,
        check_type="PLATFORM",
        status=status,
        raw_response=result,
        notes=notes,
    )
    db.session.add(check)
    db.session.commit()

    http_status = 200 if status == "PASSED" else 422
    return success_response(
        {
            "check_id": check.check_id,
            "check_type": "PLATFORM",
            "status": status,
            "platform": platform,
            "partner_id": partner_id,
            "notes": notes,
            "details": {
                k: v for k, v in result.items() if k != "raw"
            },
        },
        "Platform verification complete.",
        http_status,
    )


# ---------------------------------------------------------------------------
# Driving Licence Check
# ---------------------------------------------------------------------------
@bg_bp.route("/license", methods=["POST"])
@jwt_required()
def license_check():
    """
    Body: { dl_number }
    Calls the mock SARATHI DL verification API.
    Returns: check_id, status, dl_details
    """
    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    dl_number = data.get("dl_number", "").strip()
    if not dl_number:
        return error_response("dl_number is required.", 422)

    # --- Call mock API ---
    result = verify_driving_license(dl_number)

    status = _map_status(result["verified"], result.get("status", ""))
    notes = result.get("reason") if not result["verified"] else f"Valid DL — expires {result.get('expiry_date')}"

    # --- Persist ---
    check = BackgroundCheck(
        check_id=generate_uuid(),
        user_id=user_id,
        check_type="LICENSE",
        status=status,
        raw_response=result,
        notes=notes,
    )
    db.session.add(check)

    # Also update DL on worker profile if it exists
    profile = WorkerProfile.query.filter_by(user_id=user_id).first()
    if profile and result["verified"]:
        profile.driving_license = dl_number

    db.session.commit()

    http_status = 200 if status == "PASSED" else 422
    return success_response(
        {
            "check_id": check.check_id,
            "check_type": "LICENSE",
            "status": status,
            "dl_number": dl_number,
            "notes": notes,
            "details": {
                k: v for k, v in result.items() if k != "raw"
            },
        },
        "Driving licence verification complete.",
        http_status,
    )


# ---------------------------------------------------------------------------
# Get All Checks for Current User
# ---------------------------------------------------------------------------
@bg_bp.route("/status", methods=["GET"])
@jwt_required()
def check_status():
    user_id = get_jwt_identity()
    checks = BackgroundCheck.query.filter_by(user_id=user_id).order_by(
        BackgroundCheck.checked_at.desc()
    ).all()

    all_passed = all(c.status == "PASSED" for c in checks) and len(checks) >= 2
    return success_response(
        {
            "checks": [c.to_dict() for c in checks],
            "overall_cleared": all_passed,
            "total": len(checks),
        }
    )


# ---------------------------------------------------------------------------
# Get Single Check
# ---------------------------------------------------------------------------
@bg_bp.route("/<string:check_id>", methods=["GET"])
@jwt_required()
def get_check(check_id: str):
    user_id = get_jwt_identity()
    check = BackgroundCheck.query.filter_by(check_id=check_id, user_id=user_id).first()
    if not check:
        return error_response("Check record not found.", 404)
    return success_response({"check": check.to_dict()})