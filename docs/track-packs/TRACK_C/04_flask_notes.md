# TRACK C — Flask notes

SQL-focused track. Eligibility is demoed via §3.1 lifecycle **Assign Driver** (Track A `sp_Order_UpdateLifecycle` or direct UPDATE in SQL tests).

Fleet panel on §3.3:

| Field | Param |
|---|---|
| `owner_id` | `p_OwnerID` |
| `reference_date` | `p_ReferenceDate` |

`SELECT fn_EvaluateFleetCompliance(%s, %s)`

## Merge

Replace C8 triggers + `fn_EvaluateFleetCompliance` in `sql/03_programmability.sql`; update `tests/test_c8_trigger.sql` and `tests/test_fn_fleet_compliance.sql`; merge fleet seed into `02_seed.sql`.
