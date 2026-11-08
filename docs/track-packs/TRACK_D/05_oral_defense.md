# TRACK D — Oral defense

## sp_Order_SearchDetailed (§2.3.1)
- **Shape:** Multi-table WHERE + dynamic ORDER BY; joins ORDER, CUSTOMER, ACCOUNT (customer), SERVICE, CITY, LEFT JOIN ACCOUNT (driver) — matches A2 planning.
- **Why not list-by-PK:** Filters/sort come from UI combos; not a near-duplicate of get-by-id (rubric similarity rule).
- **Hardening:** Phone LIKE wildcards escaped; inverted dates SIGNAL; SARGable `CreatedAt` range (`>= TIMESTAMP(from)` / `< to+1 day`); unknown sort → `CreatedAt DESC`; supporting index `idx_order_city_status_created`.

## §3.2 UI
- Dropdowns for City / Status / Payment; phone + date range + sort; **Reset** clears to empty filters / `CREATED_DESC`.
- Columns: Payment, Distance, WithdrawCount, CreatedAt; status badge; Customer/Phone stacked.
- Inline actions: Assign, Withdraw, **Start**, **Complete**; modals for Cancel, Cancel-as-12, Rate, Delete — all CALL Track A §2.1 only.
- Footer preserves mutation SQL then refresh `SearchDetailed` (`action --> search`).
- No login screen (planning non-goal).

## Partner / staff governance (seed + C10/C12)
- **Six** portal permissions on `ROLE_PERMISSION` (A1 Fig 1.1d): `MANAGE_ORDERS`, `MANAGE_EMPLOYEES`, `MANAGE_API_ACCOUNT`, `UPDATE_ALL_ORDERS`, `UPDATE_OWN_ORDERS`, `VIEW_ALL_ORDERS`; five staff permissions; staff **12** lacks `CANCEL_ORDER` for C12 demo from the list.
- C10: shared `(PartnerID, RoleName)` FK; triggers for depth-1 PARENT_OF, parent PartnerID lock, Integration BELONGS_TO (BI allows NULL for seed; BU strict); `sp_Validate_PartnerIntegrations` LEFT JOIN after seed load.

## Cross-track
- Parent cannot place/cancel/pay for child — Track A behavioral C10.
- KPI / settlement screens — Track E.
- SQL lives in `TRACK_D/` until pasted into playground `sql/02` / `03` (see pack COPY→PASTE headers). Needs Track B ACCOUNT/CUSTOMER (and C OWNER if FK on) before D seed is meaningful.
