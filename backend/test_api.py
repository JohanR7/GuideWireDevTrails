"""
test_api.py
-----------
End-to-end happy-path test using only the stdlib + requests.
Run:  python test_api.py
Requires the server to be running: python app.py
"""

import json
import sys
import requests

BASE = "http://localhost:5002"
session = requests.Session()
TOKEN = None
REFRESH = None
USER_ID = None
PROFILE_ID = None
PLAN_ID = None
POLICY_DRAFT_ID = None
POLICY_ID = None
CHECK_ID_PLATFORM = None
CHECK_ID_LICENSE = None


def h(label: str):
    print(f"\n{'='*60}")
    print(f"  {label}")
    print("="*60)


def check(resp, label: str, expected: int = 200):
    ok = "✓" if resp.status_code == expected else "✗"
    print(f"  {ok} [{resp.status_code}] {label}")
    if resp.status_code not in (expected, expected):
        try:
            print("    ", json.dumps(resp.json(), indent=2)[:300])
        except Exception:
            pass
    return resp.json()


def auth_header():
    return {"Authorization": f"Bearer {TOKEN}"}


# ─────────────────────────────────────────────────────────────────────────────

h("0. Health Check")
r = session.get(f"{BASE}/health")
check(r, "Health", 200)

# ─────────────────────────────────────────────────────────────────────────────

h("1. Register")
r = session.post(f"{BASE}/api/v1/auth/register", json={
    "full_name": "Ravi Kumar",
    "mobile": "9876543210",
    "password": "Secure@123",
    "city": "Chennai",
    "delivery_zone": "Z3",
    "aadhaar": "123456789012",
})
data = check(r, "Register", 201)
if r.status_code == 201:
    USER_ID = data["data"]["user_id"]
    print(f"    user_id: {USER_ID}")

# ─────────────────────────────────────────────────────────────────────────────

h("2. OTP (get from server logs in dev)")
# In dev the OTP is logged to console. Here we use a direct DB trick via seed user.
# For a fresh user we'll need the logged OTP — using seed user for test flow.

r = session.post(f"{BASE}/api/v1/auth/login", json={
    "mobile": "9999999999",   # seed user — already verified
    "password": "Test@1234",
})
data = check(r, "Login (seed user)", 200)
if r.status_code == 200:
    TOKEN = data["data"]["session_token"]
    REFRESH = data["data"]["refresh_token"]
    USER_ID = data["data"]["user"]["user_id"]
    print(f"    user_id: {USER_ID}")
    print(f"    token:   {TOKEN[:40]}...")

# ─────────────────────────────────────────────────────────────────────────────

h("3. Worker Profile")
r = session.post(f"{BASE}/api/v1/worker/profile", headers=auth_header(), json={
    "platform": "SWIGGY",
    "delivery_partner_id": "SWG_DEV_001",
    "avg_monthly_income": 16500,
    "primary_zones": ["Z2", "Z3"],
    "driving_license": "KA0120230012345",
})
data = check(r, "Create Worker Profile", 201)
if r.status_code == 201:
    PROFILE_ID = data["data"]["profile_id"]
    print(f"    profile_id: {PROFILE_ID}  risk_zone: {data['data']['risk_zone']}")

# ─────────────────────────────────────────────────────────────────────────────

h("4. Background Checks")

r = session.post(f"{BASE}/api/v1/background-check/platform", headers=auth_header(), json={
    "platform": "SWIGGY",
    "delivery_partner_id": "SWG_DEV_001",
})
data = check(r, "Platform Check (should PASS)", 200)
if r.status_code == 200:
    CHECK_ID_PLATFORM = data["data"]["check_id"]
    print(f"    check_id: {CHECK_ID_PLATFORM}  status: {data['data']['status']}")

r = session.post(f"{BASE}/api/v1/background-check/license", headers=auth_header(), json={
    "dl_number": "KA0120230012345",
})
data = check(r, "DL Check (should PASS)", 200)
if r.status_code == 200:
    CHECK_ID_LICENSE = data["data"]["check_id"]
    print(f"    check_id: {CHECK_ID_LICENSE}  status: {data['data']['status']}")

# Test FAIL scenarios
r = session.post(f"{BASE}/api/v1/background-check/platform", headers=auth_header(), json={
    "platform": "ZOMATO",
    "delivery_partner_id": "FAIL_12345",
})
data = check(r, "Platform Check FAIL scenario", 422)
print(f"    status: {data['data']['status']}  notes: {data['data']['notes']}")

r = session.post(f"{BASE}/api/v1/background-check/license", headers=auth_header(), json={
    "dl_number": "EXP_DL99999",
})
data = check(r, "DL Check EXPIRED scenario", 422)
print(f"    status: {data['data']['status']}  notes: {data['data']['notes']}")

r = session.get(f"{BASE}/api/v1/background-check/status", headers=auth_header())
data = check(r, "All Checks Status", 200)
print(f"    total checks: {data['data']['total']}  overall_cleared: {data['data']['overall_cleared']}")

# ─────────────────────────────────────────────────────────────────────────────

h("5. Plans + AI Recommendation")

# Seed plans first
r = session.post(f"{BASE}/api/v1/plans/seed")
check(r, "Seed Plans", 200)

r = session.get(f"{BASE}/api/v1/plans/recommend", headers=auth_header())
data = check(r, "AI Plan Recommendation", 200)
if r.status_code == 200:
    rec = data["data"]
    print(f"    recommended_tier: {rec['recommended_tier']}")
    print(f"    risk_score:       {rec['risk_score']}")
    print(f"    confidence:       {rec['confidence_score']}")
    print(f"    multiplier:       {rec['dynamic_multiplier']}")
    print(f"    reasoning:        {rec['reasoning'][:80]}...")

r = session.get(f"{BASE}/api/v1/plans/list", headers=auth_header())
data = check(r, "List Plans", 200)
if r.status_code == 200:
    for p in data["data"]["plans"]:
        rec_flag = " ← RECOMMENDED" if p.get("recommended") else ""
        print(f"    {p['tier']:12}  ₹{p['worker_contribution']}/wk  max ₹{p['max_payout']}{rec_flag}")
    # Grab a plan_id for next steps
    PLAN_ID = data["data"]["plans"][0]["plan_id"]
    # Prefer the recommended one
    for p in data["data"]["plans"]:
        if p.get("recommended"):
            PLAN_ID = p["plan_id"]
            break

r = session.get(f"{BASE}/api/v1/plans/{PLAN_ID}/details", headers=auth_header())
data = check(r, "Plan Details", 200)
if r.status_code == 200:
    print(f"    triggers: {list(data['data']['plan']['triggers'].keys())}")

# ─────────────────────────────────────────────────────────────────────────────

h("6. Policy Selection & Confirmation")

r = session.post(f"{BASE}/api/v1/policy/select-plan", headers=auth_header(), json={
    "plan_id": PLAN_ID,
    "dynamic_premium_accepted": True,
})
data = check(r, "Select Plan (Draft)", 201)
if r.status_code == 201:
    POLICY_DRAFT_ID = data["data"]["policy_draft_id"]
    print(f"    draft_id:     {POLICY_DRAFT_ID}")
    print(f"    effective:    {data['data']['summary']['effective_from']}")
    print(f"    weekly cost:  ₹{data['data']['summary']['weekly_premium_you_pay']}")

r = session.post(f"{BASE}/api/v1/policy/confirm", headers=auth_header(), json={
    "policy_draft_id": POLICY_DRAFT_ID,
    "upi_id": "ravi@okicici",
})
data = check(r, "Confirm Policy", 201)
if r.status_code == 201:
    POLICY_ID = data["data"]["policy_id"]
    print(f"    policy_id:   {POLICY_ID}")
    print(f"    tx_hash:     {data['data']['blockchain_tx_hash'][:30]}...")
    print(f"    wallet:      {data['data']['wallet_address']}")

# ─────────────────────────────────────────────────────────────────────────────

h("7. Policy Management")

r = session.get(f"{BASE}/api/v1/policy/{POLICY_ID}", headers=auth_header())
data = check(r, "Get Policy", 200)
if r.status_code == 200:
    print(f"    status: {data['data']['policy']['status']}")

r = session.get(f"{BASE}/api/v1/policy/me", headers=auth_header())
check(r, "My Active Policy", 200)

r = session.get(f"{BASE}/api/v1/policy/{POLICY_ID}/premium-history?weeks=4", headers=auth_header())
data = check(r, "Premium History", 200)
if r.status_code == 200:
    for w in data["data"]["premium_history"]:
        print(f"    {w['week']}  ₹{w['adjusted_premium']}  mult={w['dynamic_multiplier']}  {w['debit_status']}")

r = session.get(f"{BASE}/api/v1/risk/profile/{USER_ID}", headers=auth_header())
data = check(r, "Risk Profile (ML)", 200)
if r.status_code == 200:
    print(f"    risk_score: {data['data']['risk_score']}  zone: {data['data']['risk_zone']}")

# ─────────────────────────────────────────────────────────────────────────────

h("8. Claims")

r = session.post(f"{BASE}/api/v1/claims/auto-initiate", headers=auth_header(), json={
    "disruption_event_id": "EVT_RAIN_20240801",
    "zone": "Z2",
    "disruption_type": "WEATHER",
    "severity": "HIGH",
})
data = check(r, "Auto-Initiate Claims", 201)
claim_id = None
if r.status_code == 201:
    print(f"    claims_created: {data['data']['claims_created']}")
    for c in data["data"]["claims"]:
        print(f"    claim_id: {c['claim_id'][:20]}...  trust: {c['trust_score']}  status: {c['status']}")
        claim_id = c["claim_id"]

if claim_id:
    r = session.get(f"{BASE}/api/v1/claims/{claim_id}/status", headers=auth_header())
    data = check(r, "Claim Status", 200)
    if r.status_code == 200:
        print(f"    status: {data['data']['claim']['status']}  eta: {data['data']['estimated_settlement_time']}")

r = session.get(f"{BASE}/api/v1/claims/history/me?limit=5", headers=auth_header())
data = check(r, "Claim History", 200)
if r.status_code == 200:
    print(f"    total claims in history: {data['data']['total']}")

# ─────────────────────────────────────────────────────────────────────────────

h("9. Wallet")

r = session.get(f"{BASE}/api/v1/wallet/me", headers=auth_header())
data = check(r, "Wallet Balance", 200)
if r.status_code == 200:
    print(f"    balance: ₹{data['data']['wallet']['balance']}")
    print(f"    next_debit: {data['data']['next_premium_debit']}")

# ─────────────────────────────────────────────────────────────────────────────

h("10. Notifications")

r = session.get(f"{BASE}/api/v1/notifications/me?unread=true", headers=auth_header())
data = check(r, "Unread Notifications", 200)
if r.status_code == 200:
    print(f"    unread: {data['data']['unread_count']}")
    for n in data["data"]["notifications"][:3]:
        print(f"    [{n['type']}] {n['title']}")

r = session.post(f"{BASE}/api/v1/notifications/read-all", headers=auth_header())
data = check(r, "Mark All Read", 200)

# ─────────────────────────────────────────────────────────────────────────────

h("11. Token Refresh")
r = session.post(f"{BASE}/api/v1/auth/refresh",
                 headers={"Authorization": f"Bearer {REFRESH}"})
check(r, "Refresh Token", 200)

# ─────────────────────────────────────────────────────────────────────────────

print("\n" + "="*60)
print("  All tests complete.")
print("="*60)