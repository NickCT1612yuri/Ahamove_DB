# TRACK D — Oral defense

## sp_Order_SearchDetailed
- **Rules / shape:** Multi-table WHERE filters from UI + dynamic ORDER BY (§2.3.1); involves §2.1 `ORDER` table.
- **DML:** Read-only joins across ORDER, CUSTOMER, ACCOUNT, SERVICE, CITY, driver ACCOUNT.
- **Why not a thin list-by-id proc:** Presentation filters + sort keys come from textboxes/combos; not a near-duplicate of list-by-PK.
