-- TRACK E tests (run after full seed + programmability)
USE ahamove_a2;

-- Happy KPI
CALL sp_Service_RevenueAndDriverKPI('SGN', '2026-10-01', '2026-11-30', 1, 0);

-- Failure: bad dates
-- Expected: [KPI_Input] ...
-- CALL sp_Service_RevenueAndDriverKPI('SGN', '2026-12-01', '2026-11-01', 1, 0);

-- Settlement happy (Driver 6)
SELECT fn_CalculateDriverNetSettlement(6, '2026-10-01 00:00:00', '2026-11-30 23:59:59') AS SettlementReport;

-- Settlement invalid driver
SELECT fn_CalculateDriverNetSettlement(999, '2026-10-01 00:00:00', '2026-11-30 23:59:59') AS InvalidDriverTest;
