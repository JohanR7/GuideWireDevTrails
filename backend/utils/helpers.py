import uuid
import random
import string
from datetime import datetime, timedelta
from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request


def generate_uuid() -> str:
    return str(uuid.uuid4())


def generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


def success_response(data: dict = None, message: str = "Success", status_code: int = 200):
    payload = {"success": True, "message": message}
    if data is not None:
        payload["data"] = data
    return jsonify(payload), status_code


def error_response(message: str, status_code: int = 400, errors: dict = None):
    payload = {"success": False, "message": message}
    if errors:
        payload["errors"] = errors
    return jsonify(payload), status_code


def mock_blockchain_tx() -> str:
    """Generate a fake Hyperledger Fabric tx hash for mock purposes."""
    return "0x" + "".join(random.choices("abcdef0123456789", k=64))


def mock_mandate_id() -> str:
    return "MAND_" + generate_uuid().replace("-", "")[:16].upper()


def next_sunday() -> datetime:
    today = datetime.utcnow().date()
    days_ahead = 6 - today.weekday()  # Sunday = 6
    if days_ahead <= 0:
        days_ahead += 7
    return today + timedelta(days=days_ahead)


def require_verified_mobile(fn):
    """Decorator — ensures the JWT user has a verified mobile."""
    @wraps(fn)
    def wrapper(*args, **kwargs):
        verify_jwt_in_request()
        from models.models import User
        user_id = get_jwt_identity()
        user = User.query.filter_by(user_id=user_id).first()
        if not user or not user.is_mobile_verified:
            return error_response("Mobile number not verified.", 403)
        return fn(*args, **kwargs)
    return wrapper