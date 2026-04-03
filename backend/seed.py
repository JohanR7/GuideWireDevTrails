"""
seed.py
-------
Run once to seed default plans and a dev test user.
Usage:  python seed.py
"""

from app import create_app
from extensions import db
from models.models import Plan, User, Wallet
from utils.helpers import generate_uuid
from flask_bcrypt import Bcrypt

app = create_app()
bcrypt = Bcrypt(app)

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
        "coverage_description": "Multi-disruption coverage with broader event triggers.",
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


def seed():
    with app.app_context():
        db.create_all()
        print("✓ Tables created.")

        # Seed plans
        if Plan.query.count() == 0:
            for p in DEFAULT_PLANS:
                plan = Plan(plan_id=generate_uuid(), **p)
                db.session.add(plan)
            db.session.commit()
            print(f"✓ {len(DEFAULT_PLANS)} plans seeded.")
        else:
            print("  Plans already exist — skipping.")

        # Seed a dev test user
        if not User.query.filter_by(mobile="9999999999").first():
            user = User(
                user_id=generate_uuid(),
                full_name="Dev Test User",
                mobile="9999999999",
                city="Bengaluru",
                delivery_zone="Z2",
                password_hash=bcrypt.generate_password_hash("Test@1234").decode("utf-8"),
                is_mobile_verified=True,
            )
            db.session.add(user)
            db.session.flush()

            wallet = Wallet(
                wallet_id=generate_uuid(),
                user_id=user.user_id,
                upi_id="testuser@upi",
            )
            db.session.add(wallet)
            db.session.commit()
            print(f"✓ Dev user seeded: mobile=9999999999 | password=Test@1234 | user_id={user.user_id}")
        else:
            print("  Dev user already exists — skipping.")

        print("\nSeed complete ✓")


if __name__ == "__main__":
    seed()