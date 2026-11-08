# TRACK D — §3.2 Flask notes

**Lego (source of truth for Track D SQL):** `01_seed_fragment.sql` + `02_programmability.sql` — paste into `sql/02_seed.sql` / `03_programmability.sql` when integrating. Tests: `03_tests.sql` → `tests/test_track_d.sql`. UI: `app/routes/search.py`, `app/templates/search.html`. Full `/search` needs B+E+C+A seeds + Track A §2.1 pasted too.

Planning non-goal: **no login/JWT** — actors are server-side constants.

## Search → `sp_Order_SearchDetailed`

| Form control | Param |
|---|---|
| City `<select>` from `CITY` (empty → NULL) | `p_CityID` |
| Status `<select>` IDLE…CANCELLED | `p_Status` |
| Payment `<select>` CASH / CASH_BY_RECIPIENT / BALANCE | `p_PaymentMethod` |
| Phone keyword textbox | `p_CustomerPhoneKeyword` (LIKE wildcards escaped in proc) |
| From / To date | `p_FromDate` / `p_ToDate` (SIGNAL if from > to; SARGable bounds) |
| Sort `<select>` | `p_SortBy` |
| Reset link `?reset=1` | empty filters, `CREATED_DESC` |

GET `/search` runs demo defaults; `?reset=1` clears them.

## List actions → Track A §2.1 (server-side actors)

| Control | Procedure | Actor |
|---|---|---|
| Assign | `UpdateLifecycle` / `ASSIGN_DRIVER` | Driver **6** |
| Withdraw | `WITHDRAW_DRIVER` | Row `DriverID` (fallback 7) |
| Start | `START_TRIP` | Row `DriverID` (fallback 6) |
| Complete | `COMPLETE_ORDER` | Row `DriverID` (fallback 6) |
| Cancel (modal) | `CANCEL_ORDER` | Staff **11** + reason |
| Cancel as 12 (modal) | `CANCEL_ORDER` | Staff **12** (C12 negative) |
| Rate (modal) | `RATE_ORDER` | Row `CustomerID` + stars/comment |
| Delete (modal) | `sp_Order_Delete` | Customer **1** |

Hidden `order_driver_id` / `order_customer_id` avoid extra SELECTs. Footer: `UpdateLifecycle --> SearchDetailed`.
