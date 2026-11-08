"""§3.2 Order search list — calls sp_Order_SearchDetailed; update/delete via §2.1."""

from flask import Blueprint, flash, g, render_template, request

import db

bp = Blueprint("search", __name__)

# Demo actors — server-side only (ignore client-supplied actor_account_id).
ACTOR_ASSIGN = 6  # Driver happy-path
ACTOR_WITHDRAW_FALLBACK = 7
ACTOR_CANCEL_OK = 11  # Staff with CANCEL_ORDER
ACTOR_CANCEL_DENIED = 12  # Staff without CANCEL_ORDER (C12 negative demo)
ACTOR_DELETE = 1  # Customer delete-draft demo

ORDER_STATUSES = (
    "IDLE",
    "ASSIGNING",
    "ACCEPTED",
    "IN_PROCESS",
    "COMPLETED",
    "CANCELLED",
)
PAYMENT_METHODS = ("CASH", "CASH_BY_RECIPIENT", "BALANCE")

DEFAULT_FILTERS = {
    "city_id": "SGN",
    "status": "",
    "payment_method": "BALANCE",
    "customer_phone": "090",
    "from_date": "2026-10-01",
    "to_date": "2026-11-30",
    "sort_by": "FEE_DESC",
}

EMPTY_FILTERS = {
    "city_id": "",
    "status": "",
    "payment_method": "",
    "customer_phone": "",
    "from_date": "",
    "to_date": "",
    "sort_by": "CREATED_DESC",
}


def _empty_to_none(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.strip()
    return value or None


def _filters_from_mapping(src) -> dict:
    city = _empty_to_none(src.get("city_id"))
    status = _empty_to_none(src.get("status"))
    payment = _empty_to_none(src.get("payment_method"))
    phone = _empty_to_none(src.get("customer_phone"))
    from_date = _empty_to_none(src.get("from_date"))
    to_date = _empty_to_none(src.get("to_date"))
    sort_by = _empty_to_none(src.get("sort_by")) or "CREATED_DESC"
    return {
        "city_id": city or "",
        "status": status or "",
        "payment_method": payment or "",
        "customer_phone": phone or "",
        "from_date": from_date or "",
        "to_date": to_date or "",
        "sort_by": sort_by,
        "_city": city,
        "_status": status,
        "_payment": payment,
        "_phone": phone,
        "_from": from_date,
        "_to": to_date,
        "_sort": sort_by,
    }


def _load_cities() -> list[dict]:
    rows, err = db.fetch_all("SELECT CityID, CityName FROM CITY ORDER BY CityID")
    if err:
        return []
    return rows or []


def _render(rows, filters: dict, **extra):
    public = (
        {k: v for k, v in filters.items() if not k.startswith("_")}
        if any(k.startswith("_") for k in filters)
        else filters
    )
    return render_template(
        "search.html",
        rows=rows,
        filters=public,
        cities=_load_cities(),
        statuses=ORDER_STATUSES,
        payments=PAYMENT_METHODS,
        **extra,
    )


def _run_search(filters: dict):
    city = filters["_city"]
    status = filters["_status"]
    payment = filters["_payment"]
    phone = filters["_phone"]
    from_date = filters["_from"]
    to_date = filters["_to"]
    sort_by = filters["_sort"]

    g.last_sql = (
        f"CALL sp_Order_SearchDetailed({city!r}, {status!r}, {payment!r}, "
        f"{phone!r}, {from_date!r}, {to_date!r}, {sort_by!r})"
    )
    rows, error = db.call_proc(
        "sp_Order_SearchDetailed",
        [city, status, payment, phone, from_date, to_date, sort_by],
    )
    public = {k: v for k, v in filters.items() if not k.startswith("_")}
    return rows, error, public


def _run_search_from_form():
    return _run_search(_filters_from_mapping(request.form))


def _refresh_after_action(action_sql: str):
    """Re-run search but keep mutation SQL visible in the footer."""
    rows, search_err, filters = _run_search_from_form()
    g.last_sql = f"{action_sql}  -->  {g.last_sql}"
    if search_err:
        flash(search_err, "danger")
    return rows, filters


@bp.route("/search", methods=["GET", "POST"])
def search_screen():
    if request.method == "GET":
        initial = EMPTY_FILTERS if request.args.get("reset") else DEFAULT_FILTERS
        rows, error, filters = _run_search(_filters_from_mapping(initial))
        if error:
            flash(error, "danger")
        elif not rows:
            flash("No orders matched these filters.", "warning")
        return _render(rows, filters)

    action = request.form.get("action", "search")

    if action == "search":
        rows, error, filters = _run_search_from_form()
        if error:
            flash(error, "danger")
        elif not rows:
            flash("No orders matched these filters.", "warning")
        return _render(rows, filters)

    lifecycle_actions = (
        "assign",
        "withdraw",
        "start",
        "complete",
        "cancel",
        "cancel_denied",
        "rate",
        "delete",
    )
    if action in lifecycle_actions:
        order_id = request.form.get("order_id", type=int)
        rating_stars = None
        rating_comment = None
        cancel_reason = None
        form_driver = request.form.get("order_driver_id", type=int)
        form_customer = request.form.get("order_customer_id", type=int)

        if action == "assign":
            actor_id = ACTOR_ASSIGN
            action_type = "ASSIGN_DRIVER"
        elif action == "withdraw":
            actor_id = form_driver or ACTOR_WITHDRAW_FALLBACK
            action_type = "WITHDRAW_DRIVER"
        elif action == "start":
            actor_id = form_driver or ACTOR_ASSIGN
            action_type = "START_TRIP"
        elif action == "complete":
            actor_id = form_driver or ACTOR_ASSIGN
            action_type = "COMPLETE_ORDER"
        elif action == "cancel":
            actor_id = ACTOR_CANCEL_OK
            action_type = "CANCEL_ORDER"
            cancel_reason = (
                _empty_to_none(request.form.get("cancel_reason"))
                or "Staff cancel from §3.2 list"
            )
        elif action == "cancel_denied":
            actor_id = ACTOR_CANCEL_DENIED
            action_type = "CANCEL_ORDER"
            cancel_reason = (
                _empty_to_none(request.form.get("cancel_reason"))
                or "C12 negative: staff 12 lacks CANCEL_ORDER"
            )
        elif action == "rate":
            actor_id = form_customer
            action_type = "RATE_ORDER"
            rating_stars = request.form.get("rating_stars", type=int)
            rating_comment = _empty_to_none(request.form.get("rating_comment"))
            if actor_id is None:
                flash(f"Order #{order_id}: missing customer id for rating.", "danger")
                rows, filters = _refresh_after_action(
                    f"(rate skipped — no CustomerID for order {order_id})"
                )
                return _render(rows, filters)
        else:  # delete
            actor_id = ACTOR_DELETE
            action_type = None

        if action == "delete":
            action_sql = f"CALL sp_Order_Delete({order_id}, {actor_id})"
            g.last_sql = action_sql
            _rows, error = db.call_proc("sp_Order_Delete", [order_id, actor_id])
        else:
            action_sql = (
                f"CALL sp_Order_UpdateLifecycle({order_id}, {action_type!r}, "
                f"{actor_id}, {cancel_reason!r}, {rating_stars!r}, {rating_comment!r})"
            )
            g.last_sql = action_sql
            _rows, error = db.call_proc(
                "sp_Order_UpdateLifecycle",
                [
                    order_id,
                    action_type,
                    actor_id,
                    cancel_reason,
                    rating_stars,
                    rating_comment,
                ],
            )

        if error:
            flash(error, "danger")
        else:
            flash(f"Order #{order_id}: {action} via §2.1 procedure OK.", "success")

        rows, filters = _refresh_after_action(action_sql)
        return _render(rows, filters)

    rows, error, filters = _run_search_from_form()
    if error:
        flash(error, "danger")
    return _render(rows, filters)
