"""
app.py
------
Application factory. Registers all blueprints.
"""

from flask import Flask, jsonify
from flask_jwt_extended import JWTManager

from config.settings import get_config
from extensions import db, bcrypt, migrate


def create_app(config=None):
    app = Flask(__name__)

    # ── Config ──────────────────────────────────────────────────────────────
    cfg = config or get_config()
    app.config.from_object(cfg)

    # ── Extensions ──────────────────────────────────────────────────────────
    db.init_app(app)
    bcrypt.init_app(app)
    migrate.init_app(app, db)
    jwt = JWTManager(app)

    # ── JWT error handlers ───────────────────────────────────────────────────
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({"success": False, "message": "Token has expired."}), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return jsonify({"success": False, "message": "Invalid token."}), 401

    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return jsonify({"success": False, "message": "Authorization token required."}), 401

    # ── Import models (needed for migrations) ───────────────────────────────
    from models import models  # noqa: F401

    # ── Register Blueprints ─────────────────────────────────────────────────
    from auth.routes import auth_bp
    from registration.routes import registration_bp
    from background_check.routes import bg_bp
    from plans.routes import plans_bp
    from policy.routes import policy_bp
    from claims.routes import claims_bp
    from wallet.routes import wallet_bp
    from notifications.routes import notifications_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(registration_bp)
    app.register_blueprint(bg_bp)
    app.register_blueprint(plans_bp)
    app.register_blueprint(policy_bp)
    app.register_blueprint(wallet_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(claims_bp)

    # ── Health check ─────────────────────────────────────────────────────────
    @app.route("/health")
    def health():
        return jsonify({"status": "ok", "service": "gig-insurance-api"}), 200

    # ── Global error handlers ────────────────────────────────────────────────
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"success": False, "message": "Endpoint not found."}), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"success": False, "message": "Method not allowed."}), 405

    @app.errorhandler(500)
    def internal_error(e):
        db.session.rollback()
        return jsonify({"success": False, "message": "Internal server error."}), 500

    return app


# ── Entry point ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    app = create_app()
    app.run(debug=True, port=5002)