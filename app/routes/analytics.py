"""§3.3 Analytics & function tester — KPI proc + both §2.4 functions."""

from flask import Blueprint, flash, g, render_template, request

import db

bp = Blueprint("analytics", __name__)


@bp.route("/analytics", methods=["GET", "POST"])
def analytics_screen():
    kpi_rows = []
    settlement = None
    fleet = None
    error = None

    if request.method == "POST":
        panel = request.form.get("panel", "kpi")

        if panel == "kpi":
            city = request.form.get("city_id") or None
            start = request.form.get("start_date")
            end = request.form.get("end_date")
            min_orders = request.form.get("min_completed_orders", type=int) or 0
            min_revenue = request.form.get("min_gross_revenue", type=int) or 0
            g.last_sql = (
                f"CALL sp_Service_RevenueAndDriverKPI({city!r}, {start!r}, {end!r}, "
                f"{min_orders}, {min_revenue})"
            )
            kpi_rows, error = db.call_proc(
                "sp_Service_RevenueAndDriverKPI",
                [city, start, end, min_orders, min_revenue],
            )
        elif panel == "settlement":
            driver_id = request.form.get("driver_id", type=int)
            start = request.form.get("start_datetime")
            end = request.form.get("end_datetime")
            g.last_sql = (
                f"SELECT fn_CalculateDriverNetSettlement({driver_id}, {start!r}, {end!r})"
            )
            settlement, error = db.call_function(
                "SELECT fn_CalculateDriverNetSettlement(%s, %s, %s) AS result",
                (driver_id, start, end),
            )
        elif panel == "fleet":
            owner_id = request.form.get("owner_id", type=int)
            ref_date = request.form.get("reference_date")
            g.last_sql = f"SELECT fn_EvaluateFleetCompliance({owner_id}, {ref_date!r})"
            fleet, error = db.call_function(
                "SELECT fn_EvaluateFleetCompliance(%s, %s) AS result",
                (owner_id, ref_date),
            )

        if error:
            flash(error, "danger")

    return render_template(
        "analytics.html",
        kpi_rows=kpi_rows,
        settlement=settlement,
        fleet=fleet,
        error=error,
    )
