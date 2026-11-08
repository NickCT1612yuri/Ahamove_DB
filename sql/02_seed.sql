-- =============================================================================
-- 02_seed.sql — Meaningful sample data (≥5 rows per table)
-- Respect fixed ID ranges so tracks can insert independently.
-- =============================================================================

USE ahamove_a2;

-- -----------------------------------------------------------------------------
-- ID CONTRACT (do not collide)
--   AccountID  1–5   = Customers
--   AccountID  6–10  = Drivers
--              6 = verified ONLINE happy path
--              7 = BUSY (active order) — fails C8 single-order
--              8 = unverified — fails C8
--              9 = expired vehicle docs — fails C8
--   AccountID 11–15  = Staff
--   PartnerID  1–5
--   OwnerID    1–6
--   OrderID  101–108
--     101 IDLE draft (delete demo)
--     102 ASSIGNING BALANCE (C8 eligibility demo)
--     103 ACCEPTED WithdrawCount=4 (C7 withdraw→cancel)
--     104 IN_PROCESS (cancel-too-late demo)
--     105–107 COMPLETED (analytics / settlement)
--     108 reserved / CANCELLED as needed
-- -----------------------------------------------------------------------------

-- TODO Track B: ACCOUNT, CUSTOMER, TRANSACTION, SPECIAL_REQUEST, ORDER_REQUEST
-- TODO Track C: OWNER, DRIVER, VEHICLE, VEHICLE_DOC, OPERATION
-- TODO Track D: STAFF, STAFF_PERMISSION, PARTNER, PARTNER_ROLE, ROLE_PERMISSION
-- TODO Track E: CITY, SERVICE, SERVICE_REQUEST
-- TODO Track A: `ORDER`, PROMOTION, PATH_POINT, ORDER_ITEM, PROOF_PHOTO

SELECT '02_seed.sql: insert ≥5 rows per table using the ID contract above.' AS notice;
