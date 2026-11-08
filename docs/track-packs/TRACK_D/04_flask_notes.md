# TRACK D — §3.2 Flask notes

Wire `app/routes/search.py` + `templates/search.html`.

| Form field | Param |
|---|---|
| `city_id` | `p_CityID` |
| `status` | `p_Status` |
| `payment_method` | `p_PaymentMethod` |
| `customer_phone` | `p_CustomerPhoneKeyword` |
| `from_date` / `to_date` | `p_FromDate` / `p_ToDate` |
| `sort_by` | `p_SortBy` (`CREATED_DESC` / `FEE_DESC` / `DISTANCE_ASC`) |

List row actions (Assign / Withdraw / Cancel / Delete) must call Track A procedures only — never raw `UPDATE`/`DELETE` on `` `ORDER` ``.

## Merge

Replace `sp_Order_SearchDetailed` in `sql/03_programmability.sql`; update `tests/test_sp_order_search.sql`; merge staff/partner seed into `02_seed.sql`.
