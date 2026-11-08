-- =============================================================================
-- 00_schema_skeleton.sql — Frozen contracts (reference only)
-- Full runnable DDL lives in 01_schema.sql (Phase 1 freeze).
-- =============================================================================

SELECT 'See 01_schema.sql for the frozen 23-table DDL.' AS notice;

-- Tables (23):
--   CITY, SPECIAL_REQUEST, PROMOTION, OWNER, ACCOUNT,
--   STAFF, STAFF_PERMISSION, CUSTOMER, PARTNER, PARTNER_ROLE, ROLE_PERMISSION, DRIVER,
--   VEHICLE, VEHICLE_DOC, SERVICE, SERVICE_REQUEST, OPERATION,
--   `ORDER`, PATH_POINT, PROOF_PHOTO, ORDER_REQUEST, ORDER_ITEM, TRANSACTION
--
-- Materialized derived columns:
--   `ORDER`.TotalFee, VEHICLE_DOC.AlertLevel, DRIVER.AvgRating
--
-- Enums (frozen strings):
--   ACCOUNT.AccountType: CUSTOMER | DRIVER | STAFF
--   ACCOUNT.AccountStatus: ACTIVE | INACTIVE | SUSPENDED
--   `ORDER`.Status: IDLE | ASSIGNING | ACCEPTED | IN_PROCESS | COMPLETED | CANCELLED
--   `ORDER`.PaymentMethod: CASH | CASH_BY_RECIPIENT | BALANCE
--   OPERATION.OpStatus: ACTIVE | INACTIVE
--   DRIVER.WorkStatus: ONLINE | OFFLINE | BUSY
--   VEHICLE_DOC.AlertLevel: OK | REMINDER | ALARM | URGENT
--
-- Seed ID ranges: Accounts 1–5 customers, 6–10 drivers, 11–15 staff; Orders 101–108
-- Error style: SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[RuleCode] ...'
