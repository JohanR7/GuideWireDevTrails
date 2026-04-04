"""
claims/routes.py
-----------------
POST /api/v1/claims/auto-initiate             → internal: create claims for disruption
GET  /api/v1/claims/<claim_id>/status         → claim status
GET  /api/v1/claims/history/<user_id>         → claim history
POST /api/v1/claims/<claim_id>/step-up-verify → biometric / photo re-score
POST /api/v1/claims/<claim_id>/appeal         → appeal rejected claim
"""

import random
from datetime import datetime
from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from extensions import db
from models.models import Claim, Policy, Plan, Wallet, Notification
from utils.helpers import generate_uuid, success_response, error_response, mock_blockchain_tx

claims_bp = Blueprint("claims", __name__, url_prefix="/api/v1/claims")


def _mock_trust_score(user_id: str) -> float:
    """
    Mock DARTS fraud detection model output.
    In production: aggregates GNSS, barometer, GNN cluster signals.
    """
    # Seeded by user_id for reproducibility in tests
    seed = sum(ord(c) for c in user_id)
    random.seed(seed)
    score = round(random.uniform(0.55, 0.98), 3)
    random.seed()  # reset
    return score


def _route_claim(claim: Claim, trust_score: float):
    """Apply trust score routing logic."""
    claim.trust_score = trust_score
    if trust_score > 0.9:
        claim.status = "APPROVED"
    elif trust_score >= 0.7:
        claim.status = "STEP_UP_REQUIRED"
    else:
        claim.status = "AUDITING"


def _payout_claim(claim: Claim, user_id: str):
    """Execute mock payout: debit liquidity pool → credit worker wallet."""
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    if wallet and claim.payout_amount:
        wallet.balance = float(wallet.balance or 0) + float(claim.payout_amount)
        wallet.total_earned = float(wallet.total_earned or 0) + float(claim.payout_amount)

    claim.status = "APPROVED"
    claim.blockchain_tx_hash = mock_blockchain_tx()
    claim.settled_at = datetime.utcnow()

    notif = Notification(
        notification_id=generate_uuid(),
        user_id=user_id,
        type="PAYOUT",
        title="Claim Paid 💰",
        body=f"₹{claim.payout_amount} credited to your wallet. Ref: {claim.blockchain_tx_hash[:16]}",
    )
    db.session.add(notif)


# ---------------------------------------------------------------------------
# Auto-Initiate Claim (internal / webhook use)
# ---------------------------------------------------------------------------
@claims_bp.route("/auto-initiate", methods=["POST"])
@jwt_required()
def auto_initiate():
    """
    Body: { disruption_event_id, zone, disruption_type, severity }
    Finds all ACTIVE policy holders in the zone and creates claim records.
    """
    data = request.get_json(silent=True) or {}
    required = ["disruption_event_id", "zone", "disruption_type"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return error_response(f"Missing: {', '.join(missing)}", 422)

    zone = data["zone"]
    disruption_type = data["disruption_type"].upper()
    severity = data.get("severity", "MEDIUM")
    event_id = data["disruption_event_id"]

    # Find ACTIVE policies in this zone
    active_policies = Policy.query.filter_by(status="ACTIVE", risk_zone=zone).all()
    if not active_policies:
        return success_response({"claims_created": 0, "message": "No active policies in this zone."})

    created_claims = []
    for policy in active_policies:
        plan = Plan.query.filter_by(plan_id=policy.plan_id).first()
        max_payout = float(plan.max_payout) if plan else 250.0

        # Payout = severity multiplier × max_payout
        sev_mult = {"LOW": 0.3, "MEDIUM": 0.5, "HIGH": 0.75, "CRITICAL": 1.0}.get(severity, 0.5)
        payout = round(max_payout * sev_mult, 2)

        trust_score = _mock_trust_score(policy.user_id)

        claim = Claim(
            claim_id=generate_uuid(),
            user_id=policy.user_id,
            policy_id=policy.policy_id,
            disruption_event_id=event_id,
            payout_amount=payout,
        )
        _route_claim(claim, trust_score)
        db.session.add(claim)

        # Auto-payout if trust score high enough
        if trust_score > 0.9:
            _payout_claim(claim, policy.user_id)

        created_claims.append(
            {
                "claim_id": claim.claim_id,
                "user_id": policy.user_id,
                "status": claim.status,
                "trust_score": trust_score,
                "payout_amount": payout,
            }
        )

    db.session.commit()
    return success_response(
        {
            "disruption_event_id": event_id,
            "disruption_type": disruption_type,
            "zone": zone,
            "claims_created": len(created_claims),
            "claims": created_claims,
        },
        "Claims initiated.",
        201,
    )


# ---------------------------------------------------------------------------
# Claim Status
# ---------------------------------------------------------------------------
@claims_bp.route("/<string:claim_id>/status", methods=["GET"])
@jwt_required()
def claim_status(claim_id: str):
    user_id = get_jwt_identity()
    claim = Claim.query.filter_by(claim_id=claim_id, user_id=user_id).first()
    if not claim:
        return error_response("Claim not found.", 404)

    est_time = "~10 minutes" if (claim.trust_score or 0) > 0.9 else (
        "~30 minutes" if (claim.trust_score or 0) >= 0.7 else "Manual review (24–48 hours)"
    )

    return success_response(
        {
            "claim": claim.to_dict(),
            "estimated_settlement_time": est_time,
        }
    )


# ---------------------------------------------------------------------------
# Claim History
# ---------------------------------------------------------------------------
@claims_bp.route("/history/<string:uid>", methods=["GET"])
@jwt_required()
def claim_history(uid: str):
    user_id = get_jwt_identity()
    target = uid if uid != "me" else user_id

    limit = int(request.args.get("limit", 20))
    status_filter = request.args.get("status")

    q = Claim.query.filter_by(user_id=target)
    if status_filter:
        q = q.filter_by(status=status_filter.upper())

    claims = q.order_by(Claim.created_at.desc()).limit(limit).all()
    return success_response(
        {
            "claims": [c.to_dict() for c in claims],
            "total": len(claims),
        }
    )


# ---------------------------------------------------------------------------
# Step-Up Verification
# ---------------------------------------------------------------------------
@claims_bp.route("/<string:claim_id>/step-up-verify", methods=["POST"])
@jwt_required()
def step_up_verify(claim_id: str):
    """
    Body: { liveness_token? OR location_photo (base64) }
    Re-runs trust score after verification. If passes → instant payout.
    """
    user_id = get_jwt_identity()
    claim = Claim.query.filter_by(claim_id=claim_id, user_id=user_id).first()
    if not claim:
        return error_response("Claim not found.", 404)

    if claim.status not in ("STEP_UP_REQUIRED", "AUDITING"):
        return error_response(f"Step-up not applicable for status: {claim.status}", 400)

    data = request.get_json(silent=True) or {}
    has_liveness = bool(data.get("liveness_token"))
    has_photo = bool(data.get("location_photo"))

    if not has_liveness and not has_photo:
        return error_response("Provide liveness_token or location_photo for verification.", 422)

    # Mock: re-score with a boost for providing evidence
    new_score = min(round((claim.trust_score or 0.7) + random.uniform(0.05, 0.18), 3), 0.99)
    claim.trust_score = new_score

    if new_score > 0.9:
        _payout_claim(claim, user_id)
        message = "Step-up passed. Payout initiated within 30 minutes."
    else:
        claim.status = "AUDITING"
        message = "Still below threshold. Routed to manual audit."

    db.session.commit()
    return success_response(
        {
            "claim_id": claim_id,
            "new_trust_score": new_score,
            "status": claim.status,
        },
        message,
    )


# ---------------------------------------------------------------------------
# Appeal Rejected Claim
# ---------------------------------------------------------------------------
@claims_bp.route("/<string:claim_id>/appeal", methods=["POST"])
@jwt_required()
def appeal_claim(claim_id: str):
    """
    Body: { reason, evidence? (text or base64 media) }
    SLA: 48-hour response.
    """
    user_id = get_jwt_identity()
    claim = Claim.query.filter_by(claim_id=claim_id, user_id=user_id).first()
    if not claim:
        return error_response("Claim not found.", 404)

    if claim.status != "REJECTED":
        return error_response("Only REJECTED claims can be appealed.", 400)

    data = request.get_json(silent=True) or {}
    reason = data.get("reason", "").strip()
    if not reason:
        return error_response("reason is required.", 422)

    # Move back to AUDITING with appeal note
    claim.status = "AUDITING"

    notif = Notification(
        notification_id=generate_uuid(),
        user_id=user_id,
        type="CLAIM",
        title="Appeal Submitted",
        body=f"Your appeal for claim {claim_id[:8]}... is under review. SLA: 48 hours.",
    )
    db.session.add(notif)
    db.session.commit()

    return success_response(
        {
            "claim_id": claim_id,
            "status": "AUDITING",
            "sla_hours": 48,
        },
        "Appeal submitted. You will be notified within 48 hours.",
    )