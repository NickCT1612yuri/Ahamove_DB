-- =============================================================================
-- 03_programmability.sql — Section 2 procedures, triggers, functions
-- Signatures frozen at Phase 1 sync checkpoint. Bodies filled by track owners.
-- Error style: SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[RuleCode] ...';
-- =============================================================================

USE ahamove_a2;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- §2.1 CRUD on `ORDER` — Track A
-- -----------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_Order_Create $$
CREATE PROCEDURE sp_Order_Create(
  IN p_CustomerID INT,
  IN p_CityID CHAR(3),
  IN p_GroupCode VARCHAR(20),
  IN p_PaymentMethod VARCHAR(30),
  IN p_Distance DECIMAL(10,2),
  IN p_Weight DECIMAL(10,2),
  IN p_DropoffCount INT,
  IN p_PromoCode VARCHAR(30),
  IN p_ScheduledAt DATETIME,
  IN p_PickupAddress VARCHAR(255),
  IN p_PickupContactName VARCHAR(100),
  IN p_PickupContactMobile VARCHAR(20),
  IN p_FirstDropAddress VARCHAR(255),
  IN p_FirstDropContactName VARCHAR(100),
  IN p_FirstDropContactMobile VARCHAR(20),
  IN p_FirstDropCOD BIGINT
)
BEGIN
  -- TODO Track A: validate C1/C3/C4/C6/C11/C13; insert ORDER + PATH_POINT (+ txn)
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = '[NotImplemented] sp_Order_Create body not yet written (Track A).';
END $$

DROP PROCEDURE IF EXISTS sp_Order_UpdateLifecycle $$
CREATE PROCEDURE sp_Order_UpdateLifecycle(
  IN p_OrderID INT,
  IN p_ActionType VARCHAR(30),
  IN p_ActorAccountID INT,
  IN p_CancelReason VARCHAR(255),
  IN p_RatingStars INT,
  IN p_RatingComment VARCHAR(500)
)
BEGIN
  -- TODO Track A: C6/C7/C9/C12 lifecycle actions
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = '[NotImplemented] sp_Order_UpdateLifecycle body not yet written (Track A).';
END $$

DROP PROCEDURE IF EXISTS sp_Order_Delete $$
CREATE PROCEDURE sp_Order_Delete(
  IN p_OrderID INT,
  IN p_RequestingAccountID INT
)
BEGIN
  -- TODO Track A: allow only IDLE/ASSIGNING drafts with no audit trail
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = '[NotImplemented] sp_Order_Delete body not yet written (Track A).';
END $$

-- -----------------------------------------------------------------------------
-- §2.2.1 Business constraint (C8) — Track C
-- Companion BEFORE INSERT recommended when DriverID set on insert.
-- -----------------------------------------------------------------------------

-- DROP TRIGGER IF EXISTS trg_Order_BeforeUpdate_DriverEligibility $$
-- CREATE TRIGGER trg_Order_BeforeUpdate_DriverEligibility
-- BEFORE UPDATE ON `ORDER`
-- FOR EACH ROW
-- BEGIN
--   -- TODO Track C: ACTIVE, verified, ONLINE, no other busy order,
--   -- ACTIVE OPERATION, vehicle type/capacity, unexpired VEHICLE_DOC
-- END $$

-- DROP TRIGGER IF EXISTS trg_Order_BeforeInsert_DriverEligibility $$
-- CREATE TRIGGER trg_Order_BeforeInsert_DriverEligibility
-- BEFORE INSERT ON `ORDER`
-- FOR EACH ROW
-- BEGIN
--   -- TODO Track C: same C8 checks when NEW.DriverID IS NOT NULL
-- END $$

-- -----------------------------------------------------------------------------
-- §2.2.2 Derived attribute chain (B then A) — Track B
-- Attribute B: ORDER.RequestFee / TotalFee (C4)
-- Attribute A: CUSTOMER.Balance / DRIVER.Balance from TRANSACTION (C11)
-- -----------------------------------------------------------------------------

-- DROP TRIGGER IF EXISTS trg_OrderReq_SyncFee $$
-- CREATE TRIGGER trg_OrderReq_SyncFee
-- AFTER INSERT ON ORDER_REQUEST
-- FOR EACH ROW
-- BEGIN
--   -- TODO Track B: recompute RequestFee + TotalFee; adjust BALANCE payment txn
-- END $$
-- (also AFTER UPDATE / AFTER DELETE variants as needed)

-- DROP TRIGGER IF EXISTS trg_Txn_AfterChange_SyncBalance $$
-- CREATE TRIGGER trg_Txn_AfterChange_SyncBalance
-- AFTER INSERT ON TRANSACTION
-- FOR EACH ROW
-- BEGIN
--   -- TODO Track B: Balance = SUM(Amount); enforce Balance >= -CreditLimit
-- END $$

-- -----------------------------------------------------------------------------
-- §2.3 Query procedures — Track D / Track E
-- -----------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_Order_SearchDetailed $$
CREATE PROCEDURE sp_Order_SearchDetailed(
  IN p_CityID CHAR(3),
  IN p_Status VARCHAR(20),
  IN p_PaymentMethod VARCHAR(30),
  IN p_CustomerPhoneKeyword VARCHAR(20),
  IN p_FromDate DATE,
  IN p_ToDate DATE,
  IN p_SortBy VARCHAR(20)
)
BEGIN
  -- TODO Track D: ≥2 tables, WHERE + ORDER BY; linked to §3.2 UI
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = '[NotImplemented] sp_Order_SearchDetailed body not yet written (Track D).';
END $$

DROP PROCEDURE IF EXISTS sp_Service_RevenueAndDriverKPI $$
CREATE PROCEDURE sp_Service_RevenueAndDriverKPI(
  IN p_CityID CHAR(3),
  IN p_StartDate DATE,
  IN p_EndDate DATE,
  IN p_MinCompletedOrders INT,
  IN p_MinGrossRevenue BIGINT
)
BEGIN
  -- TODO Track E: aggregates, GROUP BY, HAVING, WHERE, ORDER BY, joins ≥2
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = '[NotImplemented] sp_Service_RevenueAndDriverKPI body not yet written (Track E).';
END $$

-- -----------------------------------------------------------------------------
-- §2.4 Functions (cursor + IF/LOOP + validation) — Track E / Track C
-- -----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS fn_CalculateDriverNetSettlement $$
CREATE FUNCTION fn_CalculateDriverNetSettlement(
  p_DriverID INT,
  p_StartDate DATETIME,
  p_EndDate DATETIME
) RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
  -- TODO Track E: cursor over COMPLETED orders; commission / earning / COD
  RETURN CONCAT('[NotImplemented] fn_CalculateDriverNetSettlement (Track E) driver=', IFNULL(p_DriverID, 'NULL'));
END $$

DROP FUNCTION IF EXISTS fn_EvaluateFleetCompliance $$
CREATE FUNCTION fn_EvaluateFleetCompliance(
  p_OwnerID INT,
  p_ReferenceDate DATE
) RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
  -- TODO Track C: cursor over VEHICLE_DOC; C9 AlertLevel tiers; readiness score
  RETURN CONCAT('[NotImplemented] fn_EvaluateFleetCompliance (Track C) owner=', IFNULL(p_OwnerID, 'NULL'));
END $$

DELIMITER ;

SELECT '03_programmability.sql: stub signatures loaded; replace TODOs per track.' AS notice;
