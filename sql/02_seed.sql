-- =============================================================================
-- 02_seed.sql — Meaningful sample data (≥5 rows per table)
-- Respect fixed ID ranges so tracks can insert independently.
-- =============================================================================

USE ahamove_a2;

-- -----------------------------------------------------------------------------
-- ID CONTRACT (do not collide)
--   AccountID  1–5   = Customers
--   AccountID  16    = Extra customer (partner Integration)
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

-- =============================================================================
-- PASTE TRACK_B HERE: SPECIAL_REQUEST, ACCOUNT, CUSTOMER
-- docs/track-packs/TRACK_B/01_seed_fragment.sql
-- =============================================================================

-- =============================================================================
-- PASTE TRACK_E HERE: CITY, SERVICE, SERVICE_REQUEST
-- docs/track-packs/TRACK_E/01_seed_fragment.sql
-- =============================================================================

-- =============================================================================
-- PASTE TRACK_C HERE: OWNER, DRIVER, VEHICLE, VEHICLE_DOC, OPERATION
-- docs/track-packs/TRACK_C/01_seed_fragment.sql
-- =============================================================================

-- =============================================================================
-- PASTE TRACK_A HERE: PROMOTION, ORDER 101–108, PATH_POINT, …
-- docs/track-packs/TRACK_A/01_seed_fragment.sql
-- =============================================================================

-- =============================================================================
-- PASTE TRACK_B HERE: TRANSACTION, ORDER_REQUEST
-- docs/track-packs/TRACK_B/01_seed_fragment.sql
-- =============================================================================

-- =============================================================================
-- PASTE TRACK_D HERE: STAFF, STAFF_PERMISSION, PARTNER, PARTNER_ROLE, ROLE_PERMISSION
-- docs/track-packs/TRACK_D/01_seed_fragment.sql
-- =============================================================================

SELECT '02_seed.sql loaded' AS notice;
