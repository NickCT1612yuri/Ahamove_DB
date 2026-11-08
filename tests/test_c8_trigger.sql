-- Track C — §2.2.1 C8 driver/vehicle eligibility
-- Run after reset_demo.sql once triggers + seed rows exist.

USE ahamove_a2;

-- Happy path: Driver 6 accepts Order 102
-- UPDATE `ORDER` SET DriverID = 6, Status = 'ACCEPTED', AcceptedAt = NOW() WHERE OrderID = 102;

-- Failure: Driver 9 has expired INSURANCE on vehicle
-- UPDATE `ORDER` SET DriverID = 9, Status = 'ACCEPTED', AcceptedAt = NOW() WHERE OrderID = 102;
-- Expected: [C8_Eligibility] ... expired INSURANCE ...

SELECT 'TODO: uncomment C8 demo statements after Track C implements triggers + seed.' AS notice;
