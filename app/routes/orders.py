"""§3.1 Order booking & lifecycle — calls §2.1 procedures only for write ops."""

from flask import Blueprint, flash, g, redirect, render_template, request, url_for

import db

bp = Blueprint("orders", __name__)


@bp.route("/")
def home():
    return redirect(url_for("orders.order_screen"))


@bp.route("/orders", methods=["GET", "POST"])
def order_screen():
    """
    Stub screen for §3.1.
    Track A wires forms to sp_Order_Create / UpdateLifecycle / Delete.
    Track B adds before/after Balance & TotalFee inspector.
    """
    result_msg = None
    error = None

    if request.method == "POST":
        action = request.form.get("action", "create")
        if action == "create":
            g.last_sql = "CALL sp_Order_Create(...)"
            # TODO Track A: map form fields → call_proc("sp_Order_Create", [...])
            _rows, error = db.call_proc("sp_Order_Create", [
                request.form.get("customer_id", type=int),
                request.form.get("city_id"),
                request.form.get("group_code"),
                request.form.get("payment_method"),
                request.form.get("distance", type=float),
                request.form.get("weight", type=float),
                request.form.get("dropoff_count", type=int),
                request.form.get("promo_code") or None,
                None,  # scheduled_at
                request.form.get("pickup_address"),
                request.form.get("pickup_contact_name"),
                request.form.get("pickup_contact_mobile"),
                request.form.get("drop_address"),
                request.form.get("drop_contact_name"),
                request.form.get("drop_contact_mobile"),
                request.form.get("drop_cod", type=int) or 0,
            ])
            if error:
                flash(error, "danger")
            else:
                flash("Order create requested (stub).", "success")
                result_msg = "sp_Order_Create invoked"
        elif action == "lifecycle":
            g.last_sql = "CALL sp_Order_UpdateLifecycle(...)"
            _rows, error = db.call_proc("sp_Order_UpdateLifecycle", [
                request.form.get("order_id", type=int),
                request.form.get("action_type"),
                request.form.get("actor_account_id", type=int),
                request.form.get("cancel_reason") or None,
                request.form.get("rating_stars", type=int),
                request.form.get("rating_comment") or None,
            ])
            if error:
                flash(error, "danger")
            else:
                flash("Lifecycle update requested (stub).", "success")
        elif action == "delete":
            g.last_sql = "CALL sp_Order_Delete(...)"
            _rows, error = db.call_proc("sp_Order_Delete", [
                request.form.get("order_id", type=int),
                request.form.get("requesting_account_id", type=int),
            ])
            if error:
                flash(error, "danger")
            else:
                flash("Delete requested (stub).", "success")

        return redirect(url_for("orders.order_screen"))

    return render_template("orders.html", result_msg=result_msg, error=error)
