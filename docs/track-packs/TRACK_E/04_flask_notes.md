# TRACK E — §3.3 Flask notes

Wire `app/routes/analytics.py` + `templates/analytics.html` (already stubbed).

## KPI panel → `sp_Service_RevenueAndDriverKPI`

| Form field | Param |
|---|---|
| `city_id` (empty = NULL) | `p_CityID` |
| `start_date` | `p_StartDate` |
| `end_date` | `p_EndDate` |
| `min_completed_orders` | `p_MinCompletedOrders` (HAVING) |
| `min_gross_revenue` | `p_MinGrossRevenue` (HAVING) |

Use `db.call_proc(...)` and render returned rows. Flash `SIGNAL` text on error.

## Settlement panel → `fn_CalculateDriverNetSettlement`

| Form field | Param |
|---|---|
| `driver_id` | `p_DriverID` |
| `start_datetime` | `p_StartDate` |
| `end_datetime` | `p_EndDate` |

`db.call_function("SELECT fn_CalculateDriverNetSettlement(%s,%s,%s) AS result", (...))`

## Fleet panel

Owned by Track C (`fn_EvaluateFleetCompliance`) — leave wired but C owns the function body.

## Merge

Replace stubs in `sql/03_programmability.sql` for the two E objects; replace `tests/test_sp_service_kpi.sql` and `tests/test_fn_driver_settlement.sql`; append CITY/SERVICE/SERVICE_REQUEST inserts into `sql/02_seed.sql`.
