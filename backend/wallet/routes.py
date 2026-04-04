"""
wallet/routes.py
-----------------
GET  /api/v1/wallet/<user_id>  → wallet balance + linked UPI
POST /api/v1/wallet/withdraw   → withdraw balance to UPI/bank
"""

from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

from extensions import db
from models.models import Wallet, Policy, Plan, Notification
from utils.helpers import generate_uuid, success_response, error_response

wallet_bp = Blueprint("wallet", __name__, url_prefix="/api/v1/wallet")


@wallet_bp.route("/<string:uid>", methods=["GET"])
@jwt_required()
def get_wallet(uid: str):
    user_id = get_jwt_identity()
    target = uid if uid != "me" else user_id

    wallet = Wallet.query.filter_by(user_id=target).first()
    if not wallet:
        return error_response("Wallet not found.", 404)

    # Get next premium info
    policy = Policy.query.filter_by(user_id=target, status="ACTIVE").first()
    next_debit = None
    next_debit_amount = None
    if policy:
        from utils.helpers import next_sunday
        plan = Plan.query.filter_by(plan_id=policy.plan_id).first()
        next_debit = str(next_sunday())
        next_debit_amount = float(plan.worker_contribution) if plan else None

    return success_response(
        {
            "wallet": wallet.to_dict(),
            "pending_payouts": [],  # would come from claims in APPROVED state
            "next_premium_debit": next_debit,
            "next_premium_amount": next_debit_amount,
        }
    )


@wallet_bp.route("/withdraw", methods=["POST"])
@jwt_required()
def withdraw():
    """
    Body: { amount, upi_id? }
    Minimum ₹50. Settles within 2 hours via Razorpay (mock).
    """
    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    try:
        amount = float(data.get("amount", 0))
    except (TypeError, ValueError):
        return error_response("amount must be a number.", 422)

    if amount < 50:
        return error_response("Minimum withdrawal amount is ₹50.", 422)

    wallet = Wallet.query.filter_by(user_id=user_id).first()
    if not wallet:
        return error_response("Wallet not found.", 404)

    if float(wallet.balance) < amount:
        return error_response(f"Insufficient balance. Available: ₹{wallet.balance}", 400)

    wallet.balance = float(wallet.balance) - amount
    upi_id = data.get("upi_id") or wallet.upi_id

    ref = f"WD{generate_uuid().replace('-','')[:12].upper()}"

    notif = Notification(
        notification_id=generate_uuid(),
        user_id=user_id,
        type="PAYOUT",
        title="Withdrawal Initiated",
        body=f"₹{amount} withdrawal to {upi_id} initiated. Ref: {ref}. ETA: 2 hours.",
    )
    db.session.add(notif)
    db.session.commit()

    return success_response(
        {
            "amount": amount,
            "upi_id": upi_id,
            "reference": ref,
            "estimated_settlement": "Within 2 hours",
            "remaining_balance": float(wallet.balance),
        },
        "Withdrawal initiated.",
    )