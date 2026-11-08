# TRACK A — Oral defense

## sp_Order_Create
- **Rules:** C1 stops/MaxStops; C3 payment + wallet; C4 fee snapshot; C6 schedule window; C13 promo window/cap.
- **DML:** INSERT `` `ORDER` ``, PATH_POINT, optional PAYMENT TRANSACTION.
- **Why not CHECK:** Cross-table SERVICE fees, wallet funds, promo validity need queries + multi-statement txn.

## sp_Order_UpdateLifecycle
- **Rules:** C6 transitions; C7 withdraw/cancel/refund; C9 rating once; C12 staff CANCEL_ORDER permission.
- **DML:** UPDATE `` `ORDER` `` / DRIVER; INSERT REFUND TRANSACTION when needed.
- **Why not CHECK:** State machine + actor permissions + refund side effects.

## sp_Order_Delete
- **Policy:** Hard-delete only IDLE/ASSIGNING drafts with no driver and WithdrawCount=0; strip draft PAYMENT then delete (child CASCADE).
- **Why not CHECK:** Audit protection for completed/cancelled history is procedural policy.
