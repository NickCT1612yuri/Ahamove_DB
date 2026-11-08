# TRACK A — §3.1 Flask notes

`app/routes/orders.py` + `templates/orders.html` are already wired to these procedure names.

## Create → `sp_Order_Create`

Map form fields 1:1 to the 16 IN params (see signature). Empty promo → `NULL`.

## Lifecycle → `sp_Order_UpdateLifecycle`

| UI | ActionType |
|---|---|
| Assign Driver | `ASSIGN_DRIVER` (ActorAccountID = driver) |
| Withdraw | `WITHDRAW_DRIVER` |
| Start / Complete | `START_TRIP` / `COMPLETE_ORDER` |
| Cancel | `CANCEL_ORDER` (+ reason for staff) |
| Rate | `RATE_ORDER` (+ stars/comment) |

## Delete → `sp_Order_Delete`

Only drafts. Flash `[DeleteBlocked]…` from SIGNAL.

## Integration lead duties

- Merge accepted packs into `02_seed.sql` / `03_programmability.sql`
- Keep procedure signatures frozen
- Run full reset smoke test before presentation
