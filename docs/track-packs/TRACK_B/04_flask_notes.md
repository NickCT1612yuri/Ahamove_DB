# TRACK B — Flask notes

SQL-only track for owned objects. On §3.1 (Track A screen), add a **Before / After inspector**:

```sql
SELECT OrderID, RequestFee, TotalFee FROM `ORDER` WHERE OrderID = ?;
SELECT AccountID, Balance FROM CUSTOMER WHERE AccountID = ?;
```

Show values before inserting an `ORDER_REQUEST`, submit insert (raw SQL or helper route), then refresh. Do not bypass triggers.

## Merge

Merge helper procedures + triggers into `sql/03_programmability.sql` (keep names; helpers `_recompute_*` / `_sync_*` are OK as support objects). Update `tests/test_derived_fee.sql`. Merge seed into `02_seed.sql`.
