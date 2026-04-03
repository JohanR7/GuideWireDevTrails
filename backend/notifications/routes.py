"""
notifications/routes.py
------------------------
GET  /api/v1/notifications/<user_id>         → list notifications
POST /api/v1/notifications/<notif_id>/read   → mark as read
POST /api/v1/notifications/read-all          → mark all as read
"""

from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from extensions import db
from models.models import Notification
from utils.helpers import success_response, error_response

notifications_bp = Blueprint("notifications", __name__, url_prefix="/api/v1/notifications")


@notifications_bp.route("/<string:uid>", methods=["GET"])
@jwt_required()
def get_notifications(uid: str):
    """
    Query: ?unread=true&type=CLAIM&limit=20
    """
    user_id = get_jwt_identity()
    target = uid if uid != "me" else user_id

    unread_only = request.args.get("unread", "false").lower() == "true"
    ntype = request.args.get("type")
    limit = int(request.args.get("limit", 50))

    q = Notification.query.filter_by(user_id=target)
    if unread_only:
        q = q.filter_by(is_read=False)
    if ntype:
        q = q.filter_by(type=ntype.upper())

    notifications = q.order_by(Notification.created_at.desc()).limit(limit).all()
    unread_count = Notification.query.filter_by(user_id=target, is_read=False).count()

    return success_response(
        {
            "notifications": [n.to_dict() for n in notifications],
            "total": len(notifications),
            "unread_count": unread_count,
        }
    )


@notifications_bp.route("/<string:notif_id>/read", methods=["POST"])
@jwt_required()
def mark_read(notif_id: str):
    user_id = get_jwt_identity()
    notif = Notification.query.filter_by(
        notification_id=notif_id, user_id=user_id
    ).first()
    if not notif:
        return error_response("Notification not found.", 404)

    notif.is_read = True
    db.session.commit()
    return success_response({"notification_id": notif_id, "is_read": True})


@notifications_bp.route("/read-all", methods=["POST"])
@jwt_required()
def mark_all_read():
    user_id = get_jwt_identity()
    updated = (
        Notification.query
        .filter_by(user_id=user_id, is_read=False)
        .update({"is_read": True})
    )
    db.session.commit()
    return success_response({"marked_read": updated}, f"{updated} notifications marked as read.")