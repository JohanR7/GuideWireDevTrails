"""
policy/routes.py
-----------------
POST /api/v1/policy/select-plan       → draft a policy (Step 4)
POST /api/v1/policy/confirm           → confirm + activate policy (Step 5)
GET  /api/v1/policy/<policy_id>       → get policy details
GET  /api/v1/policy/me                → get current user's active policy
POST /api/v1/policy/upgrade-plan      → switch tiers
POST /api/v1/policy/cancel            → cancel policy
GET  /api/v1/policy/<policy_id>/premium-history  → weekly premium log
GET  /api/v1/risk/profile/<user_id>   → ML risk profile
"""

import redis
from datetime import datetime
from flask import Blueprint, request, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity

from extensions import db
from models.models import Plan, Policy, WorkerProfile, User, Wallet, Notification
from utils.helpers import (
    generate_uuid,
    success_response,
    error_response,
    mock_blockchain_tx,
    mock_mandate_id,
    next_sunday,
)

policy_bp = Blueprint("policy", __name__)


def _get_redis():
    return redis.from_url(current_app.config["REDIS_URL"], decode_responses=True)


def _create_wallet(user_id: str, upi_id: str = None) -> Wallet:
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    if not wallet:
        wallet = Wallet(
            wallet_id=generate_uuid(),
            user_id=user_id,
            upi_id=upi_id,
        )
        db.session.add(wallet)
    return wallet


def _push_notification(user_id: str, ntype: str, title: str, body: str):
    notif = Notification(
        notification_id=generate_uuid(),
        user_id=user_id,
        type=ntype,
        title=title,
        body=body,
    )
    db.session.add(notif)


# ---------------------------------------------------------------------------
# Step 4 — Select Plan (creates draft)
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/policy/select-plan", methods=["POST"])
@jwt_required()
def select_plan():
    """
    Body: { plan_id, risk_zone?, dynamic_premium_accepted }
    Returns: { policy_draft_id, summary }
    Draft is stored in Redis (expires 30 min).
    """
    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    plan_id = data.get("plan_id")
    if not plan_id:
        return error_response("plan_id is required.", 422)

    plan = Plan.query.filter_by(plan_id=plan_id, is_active=True).first()
    if not plan:
        return error_response("Plan not found.", 404)

    profile = WorkerProfile.query.filter_by(user_id=user_id).first()
    if not profile:
        return error_response("Worker profile not found. Complete registration first.", 404)

    risk_zone = data.get("risk_zone") or profile.risk_zone or "Z1"
    dynamic_accepted = bool(data.get("dynamic_premium_accepted", True))

    draft_id = generate_uuid()
    draft = {
        "policy_draft_id": draft_id,
        "user_id": user_id,
        "plan_id": plan_id,
        "risk_zone": risk_zone,
        "dynamic_premium_accepted": dynamic_accepted,
        "tier": plan.tier,
        "worker_contribution": str(plan.worker_contribution),
        "max_payout": str(plan.max_payout),
        "created_at": datetime.utcnow().isoformat(),
    }

    import json
    r = _get_redis()
    r.setex(f"policy_draft:{draft_id}", 1800, json.dumps(draft))  # 30 min TTL

    summary = {
        "plan_tier": plan.tier,
        "weekly_premium_you_pay": float(plan.worker_contribution),
        "platform_subsidy": float(plan.subsidy_amount),
        "max_weekly_payout": float(plan.max_payout),
        "risk_zone": risk_zone,
        "dynamic_premium_accepted": dynamic_accepted,
        "effective_from": str(next_sunday()),
        "coverage": plan.coverage_description,
    }

    return success_response(
        {"policy_draft_id": draft_id, "summary": summary},
        "Plan selected. Review summary and confirm to activate.",
        201,
    )


# ---------------------------------------------------------------------------
# Step 5 — Confirm Policy (activates it)
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/policy/confirm", methods=["POST"])
@jwt_required()
def confirm_policy():
    """
    Body: { policy_draft_id, upi_id? }
    Returns: { policy_id, effective_from, wallet_address, blockchain_tx_hash }
    """
    import json

    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    draft_id = data.get("policy_draft_id")
    if not draft_id:
        return error_response("policy_draft_id is required.", 422)

    r = _get_redis()
    draft_json = r.get(f"policy_draft:{draft_id}")
    if not draft_json:
        return error_response("Draft expired or not found. Please re-select a plan.", 410)

    draft = json.loads(draft_json)
    if draft["user_id"] != user_id:
        return error_response("Unauthorized.", 403)

    # Check for existing active policy
    existing = Policy.query.filter_by(user_id=user_id, status="ACTIVE").first()
    if existing:
        return error_response("You already have an active policy. Use upgrade-plan to change tier.", 409)

    # Mock: issue smart contract + mandate
    mandate_id = mock_mandate_id()
    tx_hash = mock_blockchain_tx()
    wallet_address = f"WALLET_{generate_uuid().replace('-', '')[:12].upper()}"
    effective_from = next_sunday()

    # Create wallet
    upi_id = data.get("upi_id")
    wallet = _create_wallet(user_id, upi_id)
    wallet.upi_id = upi_id or wallet.upi_id

    # Create policy
    policy = Policy(
        policy_id=generate_uuid(),
        policy_draft_id=draft_id,
        user_id=user_id,
        plan_id=draft["plan_id"],
        risk_zone=draft["risk_zone"],
        status="ACTIVE",
        mandate_id=mandate_id,
        wallet_address=wallet_address,
        blockchain_tx_hash=tx_hash,
        effective_from=effective_from,
        dynamic_premium_accepted=draft["dynamic_premium_accepted"],
    )
    db.session.add(policy)

    _push_notification(
        user_id,
        "PREMIUM",
        "Policy Activated 🎉",
        f"Your {draft['tier']} plan is active from {effective_from}. "
        f"Weekly premium: ₹{draft['worker_contribution']}.",
    )

    db.session.commit()
    r.delete(f"policy_draft:{draft_id}")

    return success_response(
        {
            "policy_id": policy.policy_id,
            "effective_from": str(effective_from),
            "wallet_address": wallet_address,
            "mandate_id": mandate_id,
            "blockchain_tx_hash": tx_hash,
            "status": "ACTIVE",
        },
        "Policy activated. Smart contract issued on Hyperledger Fabric.",
        201,
    )


# ---------------------------------------------------------------------------
# Get Policy by ID
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/policy/<string:policy_id>", methods=["GET"])
@jwt_required()
def get_policy(policy_id: str):
    user_id = get_jwt_identity()
    policy = Policy.query.filter_by(policy_id=policy_id, user_id=user_id).first()
    if not policy:
        return error_response("Policy not found.", 404)

    plan = Plan.query.filter_by(plan_id=policy.plan_id).first()
    data = policy.to_dict()
    data["plan"] = plan.to_dict() if plan else None
    return success_response({"policy": data})


# ---------------------------------------------------------------------------
# Get My Active Policy
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/policy/me", methods=["GET"])
@jwt_required()
def my_policy():
    user_id = get_jwt_identity()
    policy = Policy.query.filter_by(user_id=user_id, status="ACTIVE").first()
    if not policy:
        return error_response("No active policy found.", 404)

    plan = Plan.query.filter_by(plan_id=policy.plan_id).first()
    data = policy.to_dict()
    data["plan"] = plan.to_dict() if plan else None
    return success_response({"policy": data})


# ---------------------------------------------------------------------------
# Upgrade / Downgrade Plan
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/policy/upgrade-plan", methods=["POST"])
@jwt_required()
def upgrade_plan():
    """
    Body: { policy_id, new_plan_id }
    Takes effect from next Sunday.
    """
    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    policy_id = data.get("policy_id")
    new_plan_id = data.get("new_plan_id")

    if not policy_id or not new_plan_id:
        return error_response("policy_id and new_plan_id are required.", 422)

    policy = Policy.query.filter_by(policy_id=policy_id, user_id=user_id, status="ACTIVE").first()
    if not policy:
        return error_response("Active policy not found.", 404)

    new_plan = Plan.query.filter_by(plan_id=new_plan_id, is_active=True).first()
    if not new_plan:
        return error_response("New plan not found.", 404)

    old_plan = Plan.query.filter_by(plan_id=policy.plan_id).first()

    # Apply the change
    policy.plan_id = new_plan_id
    policy.blockchain_tx_hash = mock_blockchain_tx()  # re-issue contract

    _push_notification(
        user_id,
        "PREMIUM",
        "Plan Upgraded",
        f"Switched from {old_plan.tier if old_plan else '?'} to {new_plan.tier}. "
        f"New weekly premium: ₹{new_plan.worker_contribution}. Effective next Sunday.",
    )
    db.session.commit()

    return success_response(
        {
            "policy_id": policy_id,
            "old_tier": old_plan.tier if old_plan else None,
            "new_tier": new_plan.tier,
            "effective_from": str(next_sunday()),
            "new_blockchain_tx_hash": policy.blockchain_tx_hash,
        },
        "Plan upgraded. Effective from next Sunday.",
    )


# ---------------------------------------------------------------------------
# Cancel Policy
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/policy/cancel", methods=["POST"])
@jwt_required()
def cancel_policy():
    """
    Body: { policy_id, reason }
    """
    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}

    policy_id = data.get("policy_id")
    reason = data.get("reason", "Worker-initiated cancellation")

    if not policy_id:
        return error_response("policy_id is required.", 422)

    policy = Policy.query.filter_by(policy_id=policy_id, user_id=user_id, status="ACTIVE").first()
    if not policy:
        return error_response("Active policy not found.", 404)

    policy.status = "CANCELLED"
    policy.cancelled_at = datetime.utcnow()

    _push_notification(
        user_id,
        "PREMIUM",
        "Policy Cancelled",
        f"Your policy has been cancelled. Reason: {reason}. "
        "Unused pro-rated premium will be refunded within 2 business days.",
    )
    db.session.commit()

    return success_response(
        {
            "policy_id": policy_id,
            "status": "CANCELLED",
            "cancelled_at": policy.cancelled_at.isoformat(),
            "refund_note": "Pro-rated refund will be processed within 2 business days.",
        },
        "Policy cancelled successfully.",
    )


# ---------------------------------------------------------------------------
# Premium History
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/policy/<string:policy_id>/premium-history", methods=["GET"])
@jwt_required()
def premium_history(policy_id: str):
    """
    Mock: generate week-by-week premium history for the policy.
    """
    import random
    from datetime import date, timedelta

    user_id = get_jwt_identity()
    policy = Policy.query.filter_by(policy_id=policy_id, user_id=user_id).first()
    if not policy:
        return error_response("Policy not found.", 404)

    weeks = int(request.args.get("weeks", 4))
    plan = Plan.query.filter_by(plan_id=policy.plan_id).first()
    base_contribution = float(plan.worker_contribution) if plan else 15.0

    history = []
    today = date.today()
    for i in range(weeks):
        week_start = today - timedelta(weeks=i + 1)
        multiplier = round(random.uniform(0.95, 1.35), 2)
        adjusted = round(base_contribution * multiplier, 2)
        history.append(
            {
                "week": str(week_start),
                "base_rate": base_contribution,
                "dynamic_multiplier": multiplier,
                "adjusted_premium": adjusted,
                "subsidy_applied": float(plan.subsidy_amount) if plan else 33.0,
                "debit_status": random.choice(["SUCCESS", "SUCCESS", "SUCCESS", "FAILED"]),
                "upi_reference": f"UPI{generate_uuid().replace('-','')[:12].upper()}",
            }
        )

    return success_response({"policy_id": policy_id, "premium_history": history})


# ---------------------------------------------------------------------------
# Risk Profile (ML model output)
# ---------------------------------------------------------------------------
@policy_bp.route("/api/v1/risk/profile/<string:uid>", methods=["GET"])
@jwt_required()
def risk_profile(uid: str):
    """
    Returns Transformer-CNN-LSTM model output for the user.
    """
    user_id = get_jwt_identity()
    # Allow self-lookup or future admin override
    target_id = uid if uid != "me" else user_id

    profile = WorkerProfile.query.filter_by(user_id=target_id).first()
    user = User.query.filter_by(user_id=target_id).first()
    if not profile:
        return error_response("Worker profile not found.", 404)

    from plans.ai_recommender import recommend_plan
    checks = BackgroundCheck.query.filter_by(user_id=target_id).all() if target_id else []
    cleared = all(c.status == "PASSED" for c in checks) if checks else True

    rec = recommend_plan(
        risk_zone=profile.risk_zone or "Z1",
        avg_monthly_income=float(profile.avg_monthly_income or 0),
        platform=profile.platform,
        city=user.city or "" if user else "",
        background_cleared=cleared,
    )

    from datetime import date, timedelta
    next_wed = date.today()
    days = (2 - next_wed.weekday()) % 7 or 7  # next Wednesday
    next_recalc = next_wed + timedelta(days=days)

    return success_response(
        {
            "user_id": target_id,
            "risk_score": rec.risk_score,
            "suggested_premium_multiplier": rec.dynamic_multiplier,
            "risk_zone": profile.risk_zone,
            "top_risk_factors_shap": rec.shap_factors,
            "recommended_tier": rec.recommended_tier,
            "next_recalculation": str(next_recalc),
            "model": "Transformer-CNN-LSTM (mock)",
        }
    )


# Needed for BackgroundCheck import inside routes
from models.models import BackgroundCheck  # noqa: E402