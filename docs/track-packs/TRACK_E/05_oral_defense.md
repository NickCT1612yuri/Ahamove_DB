# TRACK E — Oral defense

## sp_Service_RevenueAndDriverKPI
- **Rules:** Aggregate completed-order revenue by service; filter with WHERE dates/city; HAVING min orders & min revenue (rubric §2.3.2).
- **DML:** Read-only SELECT across SERVICE, CITY, ORDER, PATH_POINT.
- **Why not CHECK:** Cross-table aggregates and HAVING cannot be table constraints.

## fn_CalculateDriverNetSettlement
- **Rules:** C4 commission = TotalFee × rate; C11 BALANCE earning + unremitted COD via cursor LOOP/IF.
- **DML:** Reads ORDER, SERVICE, PATH_POINT, TRANSACTION.
- **Why not CHECK:** Cursor over multiple completed orders with conditional earning/COD math; needs validation messages for bad DriverID/dates.
