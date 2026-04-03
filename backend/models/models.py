from datetime import datetime
from extensions import db


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(36), unique=True, nullable=False)  # UUID
    full_name = db.Column(db.String(120), nullable=False)
    mobile = db.Column(db.String(15), unique=True, nullable=False)
    aadhaar = db.Column(db.String(12), nullable=True)
    pan = db.Column(db.String(10), nullable=True)
    city = db.Column(db.String(80), nullable=True)
    delivery_zone = db.Column(db.String(20), nullable=True)
    is_mobile_verified = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    password_hash = db.Column(db.String(256), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    profile = db.relationship("WorkerProfile", backref="user", uselist=False)
    policies = db.relationship("Policy", backref="user")
    claims = db.relationship("Claim", backref="user")

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "full_name": self.full_name,
            "mobile": self.mobile,
            "city": self.city,
            "delivery_zone": self.delivery_zone,
            "is_mobile_verified": self.is_mobile_verified,
            "created_at": self.created_at.isoformat(),
        }


class WorkerProfile(db.Model):
    __tablename__ = "worker_profiles"

    id = db.Column(db.Integer, primary_key=True)
    profile_id = db.Column(db.String(36), unique=True, nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey("users.user_id"), nullable=False)
    platform = db.Column(db.String(20), nullable=False)   # SWIGGY / ZOMATO
    delivery_partner_id = db.Column(db.String(80), nullable=False)
    avg_monthly_income = db.Column(db.Numeric(10, 2), nullable=True)
    primary_zones = db.Column(db.JSON, nullable=True)     # list of zone strings
    risk_zone = db.Column(db.String(10), nullable=True)   # Z1/Z2/Z3
    driving_license = db.Column(db.String(20), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "profile_id": self.profile_id,
            "user_id": self.user_id,
            "platform": self.platform,
            "delivery_partner_id": self.delivery_partner_id,
            "avg_monthly_income": float(self.avg_monthly_income or 0),
            "primary_zones": self.primary_zones,
            "risk_zone": self.risk_zone,
        }


class BackgroundCheck(db.Model):
    __tablename__ = "background_checks"

    id = db.Column(db.Integer, primary_key=True)
    check_id = db.Column(db.String(36), unique=True, nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey("users.user_id"), nullable=False)
    check_type = db.Column(db.String(30), nullable=False)  # PLATFORM / LICENSE
    status = db.Column(db.String(20), default="PENDING")   # PENDING/PASSED/FAILED/MANUAL_REVIEW
    raw_response = db.Column(db.JSON, nullable=True)
    notes = db.Column(db.Text, nullable=True)
    checked_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "check_id": self.check_id,
            "user_id": self.user_id,
            "check_type": self.check_type,
            "status": self.status,
            "notes": self.notes,
            "checked_at": self.checked_at.isoformat(),
        }


class Plan(db.Model):
    __tablename__ = "plans"

    id = db.Column(db.Integer, primary_key=True)
    plan_id = db.Column(db.String(36), unique=True, nullable=False)
    tier = db.Column(db.String(20), nullable=False)         # ESSENTIAL / STANDARD / PREMIUM
    worker_contribution = db.Column(db.Numeric(8, 2), nullable=False)
    subsidy_amount = db.Column(db.Numeric(8, 2), nullable=False)
    total_premium = db.Column(db.Numeric(8, 2), nullable=False)
    max_payout = db.Column(db.Numeric(10, 2), nullable=False)
    coverage_description = db.Column(db.Text, nullable=True)
    min_income = db.Column(db.Numeric(10, 2), nullable=True)
    max_income = db.Column(db.Numeric(10, 2), nullable=True)
    is_active = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            "plan_id": self.plan_id,
            "tier": self.tier,
            "worker_contribution": float(self.worker_contribution),
            "subsidy_amount": float(self.subsidy_amount),
            "total_premium": float(self.total_premium),
            "max_payout": float(self.max_payout),
            "coverage_description": self.coverage_description,
        }


class Policy(db.Model):
    __tablename__ = "policies"

    id = db.Column(db.Integer, primary_key=True)
    policy_id = db.Column(db.String(36), unique=True, nullable=False)
    policy_draft_id = db.Column(db.String(36), nullable=True)
    user_id = db.Column(db.String(36), db.ForeignKey("users.user_id"), nullable=False)
    plan_id = db.Column(db.String(36), db.ForeignKey("plans.plan_id"), nullable=False)
    risk_zone = db.Column(db.String(10), nullable=True)
    status = db.Column(db.String(20), default="ACTIVE")    # ACTIVE/LAPSED/CANCELLED
    mandate_id = db.Column(db.String(80), nullable=True)
    wallet_address = db.Column(db.String(80), nullable=True)
    blockchain_tx_hash = db.Column(db.String(128), nullable=True)
    effective_from = db.Column(db.Date, nullable=True)
    effective_to = db.Column(db.Date, nullable=True)
    dynamic_premium_accepted = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    cancelled_at = db.Column(db.DateTime, nullable=True)

    plan = db.relationship("Plan", backref="policies")

    def to_dict(self):
        return {
            "policy_id": self.policy_id,
            "user_id": self.user_id,
            "plan_id": self.plan_id,
            "status": self.status,
            "risk_zone": self.risk_zone,
            "blockchain_tx_hash": self.blockchain_tx_hash,
            "effective_from": self.effective_from.isoformat() if self.effective_from else None,
            "effective_to": self.effective_to.isoformat() if self.effective_to else None,
            "wallet_address": self.wallet_address,
            "created_at": self.created_at.isoformat(),
        }


class Claim(db.Model):
    __tablename__ = "claims"

    id = db.Column(db.Integer, primary_key=True)
    claim_id = db.Column(db.String(36), unique=True, nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey("users.user_id"), nullable=False)
    policy_id = db.Column(db.String(36), db.ForeignKey("policies.policy_id"), nullable=False)
    disruption_event_id = db.Column(db.String(36), nullable=True)
    status = db.Column(db.String(30), default="PENDING")   # PENDING/AUDITING/APPROVED/REJECTED
    trust_score = db.Column(db.Float, nullable=True)
    payout_amount = db.Column(db.Numeric(10, 2), nullable=True)
    blockchain_tx_hash = db.Column(db.String(128), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    settled_at = db.Column(db.DateTime, nullable=True)

    def to_dict(self):
        return {
            "claim_id": self.claim_id,
            "user_id": self.user_id,
            "policy_id": self.policy_id,
            "status": self.status,
            "trust_score": self.trust_score,
            "payout_amount": float(self.payout_amount or 0),
            "blockchain_tx_hash": self.blockchain_tx_hash,
            "created_at": self.created_at.isoformat(),
            "settled_at": self.settled_at.isoformat() if self.settled_at else None,
        }


class Wallet(db.Model):
    __tablename__ = "wallets"

    id = db.Column(db.Integer, primary_key=True)
    wallet_id = db.Column(db.String(36), unique=True, nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey("users.user_id"), unique=True, nullable=False)
    balance = db.Column(db.Numeric(12, 2), default=0)
    total_earned = db.Column(db.Numeric(12, 2), default=0)
    upi_id = db.Column(db.String(80), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "wallet_id": self.wallet_id,
            "user_id": self.user_id,
            "balance": float(self.balance),
            "total_earned": float(self.total_earned),
            "upi_id": self.upi_id,
        }


class Notification(db.Model):
    __tablename__ = "notifications"

    id = db.Column(db.Integer, primary_key=True)
    notification_id = db.Column(db.String(36), unique=True, nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey("users.user_id"), nullable=False)
    type = db.Column(db.String(20), nullable=False)  # CLAIM/PREMIUM/ALERT/PAYOUT
    title = db.Column(db.String(200), nullable=False)
    body = db.Column(db.Text, nullable=True)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "notification_id": self.notification_id,
            "user_id": self.user_id,
            "type": self.type,
            "title": self.title,
            "body": self.body,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat(),
        }