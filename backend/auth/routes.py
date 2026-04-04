"""
auth/routes.py
--------------
Step 1: POST /api/v1/auth/register   → create user, send OTP
Step 2: POST /api/v1/auth/verify-otp → verify OTP, return JWT
        POST /api/v1/auth/refresh     → refresh access token
        POST /api/v1/auth/logout      → (client-side token discard, optional blocklist hook)
"""

from flask import Blueprint, request, current_app
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
)
import redis

from extensions import db, bcrypt
from models.models import User
from utils.helpers import (
    generate_uuid,
    generate_otp,
    success_response,
    error_response,
)

auth_bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")


def _get_redis():
    return redis.from_url(current_app.config["REDIS_URL"], decode_responses=True)


# ---------------------------------------------------------------------------
# STEP 1 — Register
# ---------------------------------------------------------------------------
@auth_bp.route("/register", methods=["POST"])
def register():
    """
    Body: { full_name, mobile, aadhaar?, pan?, city?, delivery_zone?, password }
    Returns: { user_id }  + OTP sent via SMS (logged to console in dev)
    """
    data = request.get_json(silent=True) or {}

    # --- Validation ---
    required = ["full_name", "mobile", "password"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return error_response(f"Missing required fields: {', '.join(missing)}", 422)

    mobile = data["mobile"].strip()
    if len(mobile) < 10:
        return error_response("Invalid mobile number.", 422)

    if User.query.filter_by(mobile=mobile).first():
        return error_response("Mobile number already registered.", 409)

    # --- Create user ---
    user = User(
        user_id=generate_uuid(),
        full_name=data["full_name"].strip(),
        mobile=mobile,
        aadhaar=data.get("aadhaar"),
        pan=data.get("pan"),
        city=data.get("city"),
        delivery_zone=data.get("delivery_zone"),
        password_hash=bcrypt.generate_password_hash(data["password"]).decode("utf-8"),
        is_mobile_verified=False,
    )
    db.session.add(user)
    db.session.commit()

    # --- Generate & cache OTP ---
    otp = generate_otp(current_app.config["OTP_LENGTH"])
    expiry = current_app.config["OTP_EXPIRY_SECONDS"]
    r = _get_redis()
    r.setex(f"otp:{mobile}", expiry, otp)

    # In production: call SMS gateway here
    current_app.logger.info(f"[DEV] OTP for {mobile}: {otp}")

    return success_response(
        {"user_id": user.user_id, "otp_expiry_seconds": expiry},
        "Registration successful. OTP sent to mobile.",
        201,
    )


# ---------------------------------------------------------------------------
# STEP 2 — Verify OTP
# ---------------------------------------------------------------------------
@auth_bp.route("/verify-otp", methods=["POST"])
def verify_otp():
    """
    Body: { mobile, otp }
    Returns: { session_token (access), refresh_token }
    """
    data = request.get_json(silent=True) or {}
    mobile = data.get("mobile", "").strip()
    otp_provided = data.get("otp", "").strip()

    if not mobile or not otp_provided:
        return error_response("mobile and otp are required.", 422)

    user = User.query.filter_by(mobile=mobile).first()
    if not user:
        return error_response("User not found.", 404)

    r = _get_redis()
    stored_otp = r.get(f"otp:{mobile}")

    if not stored_otp:
        return error_response("OTP expired. Please request a new one.", 410)

    if stored_otp != otp_provided:
        return error_response("Invalid OTP.", 401)

    # Mark verified
    user.is_mobile_verified = True
    db.session.commit()
    r.delete(f"otp:{mobile}")

    access_token = create_access_token(identity=user.user_id)
    refresh_token = create_refresh_token(identity=user.user_id)

    return success_response(
        {
            "session_token": access_token,
            "refresh_token": refresh_token,
            "user_id": user.user_id,
        },
        "OTP verified. Session started.",
    )


# ---------------------------------------------------------------------------
# Resend OTP
# ---------------------------------------------------------------------------
@auth_bp.route("/resend-otp", methods=["POST"])
def resend_otp():
    data = request.get_json(silent=True) or {}
    mobile = data.get("mobile", "").strip()

    if not mobile:
        return error_response("mobile is required.", 422)

    user = User.query.filter_by(mobile=mobile).first()
    if not user:
        return error_response("User not found.", 404)

    if user.is_mobile_verified:
        return error_response("Mobile already verified.", 400)

    otp = generate_otp(current_app.config["OTP_LENGTH"])
    expiry = current_app.config["OTP_EXPIRY_SECONDS"]
    r = _get_redis()
    r.setex(f"otp:{mobile}", expiry, otp)

    current_app.logger.info(f"[DEV] Resent OTP for {mobile}: {otp}")
    return success_response({"otp_expiry_seconds": expiry}, "OTP resent.")


# ---------------------------------------------------------------------------
# Login (for returning users)
# ---------------------------------------------------------------------------
@auth_bp.route("/login", methods=["POST"])
def login():
    """
    Body: { mobile, password }
    Returns: { session_token, refresh_token }
    """
    data = request.get_json(silent=True) or {}
    mobile = data.get("mobile", "").strip()
    password = data.get("password", "")

    if not mobile or not password:
        return error_response("mobile and password are required.", 422)

    user = User.query.filter_by(mobile=mobile).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        return error_response("Invalid credentials.", 401)

    if not user.is_mobile_verified:
        return error_response("Mobile not verified. Please complete OTP verification.", 403)

    access_token = create_access_token(identity=user.user_id)
    refresh_token = create_refresh_token(identity=user.user_id)

    return success_response(
        {
            "session_token": access_token,
            "refresh_token": refresh_token,
            "user": user.to_dict(),
        }
    )


# ---------------------------------------------------------------------------
# Refresh Token
# ---------------------------------------------------------------------------
@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return success_response({"session_token": access_token}, "Token refreshed.")


# ---------------------------------------------------------------------------
# Me (current user)
# ---------------------------------------------------------------------------
@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def me():
    user_id = get_jwt_identity()
    user = User.query.filter_by(user_id=user_id).first()
    if not user:
        return error_response("User not found.", 404)
    return success_response({"user": user.to_dict()})