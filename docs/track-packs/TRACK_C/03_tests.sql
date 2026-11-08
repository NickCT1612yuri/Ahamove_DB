USE ahamove_a2;

-- Fail C8: Driver 9 expired insurance on 59-X1 999.99
-- Expected: [C8_Eligibility] Vehicle 59-X1 999.99 has an expired document.
-- UPDATE `ORDER` SET DriverID = 9, Status = 'ACCEPTED', AcceptedAt = NOW() WHERE OrderID = 102;

-- Success: Driver 6
UPDATE `ORDER` SET DriverID = 6, Status = 'ACCEPTED', AcceptedAt = NOW() WHERE OrderID = 102;

SELECT fn_EvaluateFleetCompliance(1, '2026-11-05') AS FleetOwner1;
SELECT fn_EvaluateFleetCompliance(4, '2026-11-05') AS FleetOwner4Expired;
SELECT fn_EvaluateFleetCompliance(999, '2026-11-05') AS InvalidOwner;
