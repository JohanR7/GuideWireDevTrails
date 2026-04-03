"""
background_check/mock_apis.py
------------------------------
Mock responses simulating:
  - Swiggy / Zomato partner verification API
  - SARATHI driving licence verification API
"""

import random
import time
from datetime import date, timedelta


# ---------------------------------------------------------------------------
# Swiggy / Zomato Platform Verification
# ---------------------------------------------------------------------------

def verify_swiggy_partner(partner_id: str) -> dict:
    """
    Mock Swiggy delivery partner verification.
    In production: POST https://partner.swiggy.com/api/v2/verify
    """
    time.sleep(0.3)  # simulate network latency

    # Deterministic outcome based on partner_id prefix for testing
    if partner_id.upper().startswith("FAIL"):
        return {
            "verified": False,
            "status": "NOT_FOUND",
            "partner_id": partner_id,
            "reason": "Partner ID not found in Swiggy records.",
            "raw": {"code": 404, "message": "partner_not_found"},
        }

    if partner_id.upper().startswith("SUSP"):
        return {
            "verified": False,
            "status": "SUSPENDED",
            "partner_id": partner_id,
            "reason": "Partner account suspended due to policy violation.",
            "raw": {"code": 403, "message": "account_suspended"},
        }

    # Default: pass
    return {
        "verified": True,
        "status": "ACTIVE",
        "partner_id": partner_id,
        "partner_name": "Mock Partner Name",
        "city": "Bengaluru",
        "rating": round(random.uniform(3.8, 5.0), 1),
        "deliveries_completed": random.randint(500, 8000),
        "account_created": str(date.today() - timedelta(days=random.randint(90, 730))),
        "raw": {"code": 200, "message": "verified"},
    }


def verify_zomato_partner(partner_id: str) -> dict:
    """
    Mock Zomato delivery partner verification.
    In production: POST https://api.zomato.com/delivery/v1/partner/verify
    """
    time.sleep(0.3)

    if partner_id.upper().startswith("FAIL"):
        return {
            "verified": False,
            "status": "NOT_FOUND",
            "partner_id": partner_id,
            "reason": "Partner ID not registered in Zomato network.",
            "raw": {"error_code": "PARTNER_NOT_FOUND"},
        }

    return {
        "verified": True,
        "status": "ACTIVE",
        "partner_id": partner_id,
        "partner_name": "Mock Zomato Partner",
        "city": "Mumbai",
        "rating": round(random.uniform(3.5, 5.0), 1),
        "deliveries_completed": random.randint(300, 6000),
        "account_created": str(date.today() - timedelta(days=random.randint(60, 600))),
        "raw": {"status": "success"},
    }


# ---------------------------------------------------------------------------
# SARATHI Driving Licence Verification
# ---------------------------------------------------------------------------

DL_CATEGORIES = ["LMV", "MCWG", "LMV-TR", "HMV"]
DL_STATES = ["KA", "MH", "TN", "DL", "UP", "WB"]


def verify_driving_license(dl_number: str) -> dict:
    """
    Mock SARATHI (MoRTH) driving licence verification.
    In production: POST https://sarathi.parivahan.gov.in/sarathiservice/verifyDL
    """
    time.sleep(0.4)

    dl_upper = dl_number.upper()

    if dl_upper.startswith("FAIL") or len(dl_number) < 8:
        return {
            "verified": False,
            "status": "INVALID",
            "dl_number": dl_number,
            "reason": "DL number format invalid or not found in SARATHI records.",
            "raw": {"error": "DL_NOT_FOUND"},
        }

    if dl_upper.startswith("EXP"):
        return {
            "verified": False,
            "status": "EXPIRED",
            "dl_number": dl_number,
            "reason": "Driving licence has expired.",
            "expiry_date": str(date.today() - timedelta(days=random.randint(10, 365))),
            "raw": {"error": "DL_EXPIRED"},
        }

    if dl_upper.startswith("SUSP"):
        return {
            "verified": False,
            "status": "SUSPENDED",
            "dl_number": dl_number,
            "reason": "Driving licence suspended by issuing authority.",
            "raw": {"error": "DL_SUSPENDED"},
        }

    # Default: pass
    state_code = dl_upper[:2] if dl_upper[:2] in DL_STATES else random.choice(DL_STATES)
    expiry = date.today() + timedelta(days=random.randint(180, 1800))

    return {
        "verified": True,
        "status": "VALID",
        "dl_number": dl_number,
        "holder_name": "Mock DL Holder",
        "dob": str(date.today() - timedelta(days=random.randint(7300, 14600))),
        "issue_date": str(date.today() - timedelta(days=random.randint(30, 3650))),
        "expiry_date": str(expiry),
        "vehicle_classes": random.sample(DL_CATEGORIES, k=random.randint(1, 2)),
        "issuing_authority": f"RTO {state_code}",
        "state": state_code,
        "raw": {"status": "SUCCESS"},
    }