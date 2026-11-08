"""§3.2 Order search list — calls sp_Order_SearchDetailed; update/delete via §2.1."""

from flask import Blueprint, flash, g, render_template, request

import db

bp = Blueprint("search", __name__)


@bp.route("/search", methods=["GET", "POST"])
def search_screen():
    rows = []
    error = None

    if request.method == "POST":
        city = request.form.get("city_id") or None
        status = request.form.get("status") or None
        payment = request.form.get("payment_method") or None
        phone = request.form.get("customer_phone") or None
        from_date = request.form.get("from_date") or None
        to_date = request.form.get("to_date") or None
        sort_by = request.form.get("sort_by") or "CREATED_DESC"

        g.last_sql = (
            f"CALL sp_Order_SearchDetailed({city!r}, {status!r}, {payment!r}, "
            f"{phone!r}, {from_date!r}, {to_date!r}, {sort_by!r})"
        )
        rows, error = db.call_proc(
            "sp_Order_SearchDetailed",
            [city, status, payment, phone, from_date, to_date, sort_by],
        )
        if error:
            flash(error, "danger")

    return render_template("search.html", rows=rows, error=error)
