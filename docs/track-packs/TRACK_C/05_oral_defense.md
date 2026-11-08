# TRACK C — Oral defense

## C8 eligibility triggers
- **Rules:** ACTIVE account, verified, ONLINE, no other ACCEPTED/IN_PROCESS order, ACTIVE OPERATION for service, vehicle type/capacity OK, no expired VEHICLE_DOC.
- **DML:** BEFORE INSERT/UPDATE on `` `ORDER` `` when DriverID / ACCEPTED / weight / service changes.
- **Why not CHECK:** Spans ACCOUNT, DRIVER, OPERATION, VEHICLE, VEHICLE_DOC, SERVICE.

## fn_EvaluateFleetCompliance
- **Rules:** C9 alert tiers by days-to-expiry; cursor over owner’s documents; readiness score.
- **DML:** Read VEHICLE + VEHICLE_DOC.
- **Why not CHECK:** Multi-row classification with LOOP/IF and formatted summary string.
