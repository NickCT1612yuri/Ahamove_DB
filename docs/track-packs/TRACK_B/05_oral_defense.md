# TRACK B — Oral defense

## Derived trigger chain
- **Rules:** C4 `TotalFee = DistanceFee + StopFee + RequestFee - Discount`; C11 `Balance = SUM(TRANSACTION.Amount)` and `Balance >= -CreditLimit`.
- **DML:** INSERT/UPDATE/DELETE on `ORDER_REQUEST` (Attribute B); INSERT/UPDATE/DELETE on `TRANSACTION` (Attribute A). Fee change also updates BALANCE payment txn amount for unstarted orders, which re-fires balance sync.
- **Why not CHECK:** Needs joins to `SERVICE_REQUEST` prices and ledger SUM; Attribute B must run before A (assignment note).
- **MySQL note:** Helpers called from triggers avoid mutating-table issues on `` `ORDER` `` from an ORDER trigger; fee recompute is driven from `ORDER_REQUEST`.
