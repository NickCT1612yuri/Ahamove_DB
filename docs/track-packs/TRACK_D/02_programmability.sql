-- TRACK D programmability lego
-- COPY from here → PASTE into sql/03_programmability.sql at:
--   “§2.3 Query procedures — Track D / Track E” (replace SearchDetailed stub;
--   insert C10 triggers + sp_Validate_PartnerIntegrations before Track E KPI).
-- Keeps frozen signatures. SARGable dates; parent PartnerID lock; BI NULL-OK /
-- BU Integration strict; validate LEFT JOIN.
USE ahamove_a2;
DELIMITER $$

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
  -- Track D §2.3.1: multi-table WHERE + ORDER BY for §3.2 UI
  -- Unknown p_SortBy falls through to CreatedAt DESC (final ORDER BY key).
  DECLARE v_phone_kw VARCHAR(40);

  IF p_FromDate IS NOT NULL AND p_ToDate IS NOT NULL AND p_FromDate > p_ToDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '[Search] p_FromDate must be <= p_ToDate.';
  END IF;

  -- Escape LIKE wildcards so keyword "%" / "_" are literals, not pattern metachars
  SET v_phone_kw = REPLACE(REPLACE(REPLACE(IFNULL(p_CustomerPhoneKeyword, ''), '\\', '\\\\'), '%', '\\%'), '_', '\\_');

  SELECT
    o.OrderID,
    o.Status,
    o.PaymentMethod,
    o.Distance,
    o.TotalFee,
    o.WithdrawCount,
    o.CreatedAt,
    o.CityID,
    o.GroupCode,
    s.SvcName,
    c.CityName,
    cust.AccountID AS CustomerID,
    ca.Name AS CustomerName,
    ca.PhoneNumber AS CustomerPhone,
    o.DriverID,
    da.Name AS DriverName
  FROM `ORDER` o
  JOIN CUSTOMER cust ON cust.AccountID = o.CustomerID
  JOIN ACCOUNT ca ON ca.AccountID = cust.AccountID
  JOIN SERVICE s ON s.CityID = o.CityID AND s.GroupCode = o.GroupCode
  JOIN CITY c ON c.CityID = o.CityID
  LEFT JOIN ACCOUNT da ON da.AccountID = o.DriverID
  WHERE (p_CityID IS NULL OR o.CityID = p_CityID)
    AND (p_Status IS NULL OR o.Status = p_Status)
    AND (p_PaymentMethod IS NULL OR o.PaymentMethod = p_PaymentMethod)
    AND (
      p_CustomerPhoneKeyword IS NULL
      OR ca.PhoneNumber LIKE CONCAT('%', v_phone_kw, '%') ESCAPE '\\'
    )
    AND (p_FromDate IS NULL OR o.CreatedAt >= TIMESTAMP(p_FromDate))
    AND (p_ToDate IS NULL OR o.CreatedAt < DATE_ADD(TIMESTAMP(p_ToDate), INTERVAL 1 DAY))
  ORDER BY
    CASE WHEN IFNULL(p_SortBy, 'CREATED_DESC') = 'FEE_DESC' THEN o.TotalFee END DESC,
    CASE WHEN IFNULL(p_SortBy, 'CREATED_DESC') = 'DISTANCE_ASC' THEN o.Distance END ASC,
    CASE WHEN IFNULL(p_SortBy, 'CREATED_DESC') = 'CREATED_DESC' THEN o.CreatedAt END DESC,
    o.CreatedAt DESC;
END $$

-- -----------------------------------------------------------------------------
-- Track D — C10 structural enforcement (A1: INTEGRATES / PARENT_OF / HOLDS_ROLE)
-- Shared (PartnerID, RoleName) FK already blocks cross-partner roles.
-- -----------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_customer_bi_c10 $$
CREATE TRIGGER trg_customer_bi_c10
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
BEGIN
  DECLARE v_parent_partner INT;
  DECLARE v_parent_parent INT;

  IF NEW.RoleName IS NOT NULL AND NEW.PartnerID IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '[C10] Standalone customers (PartnerID IS NULL) cannot hold a portal role.';
  END IF;

  IF NEW.ParentID IS NOT NULL THEN
    IF NEW.ParentID = NEW.AccountID THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Customer cannot be its own parent.';
    END IF;

    IF NEW.PartnerID IS NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Child customers must belong to a partner (PartnerID NOT NULL).';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM CUSTOMER WHERE AccountID = NEW.ParentID) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] ParentID must reference an existing customer.';
    END IF;

    SELECT PartnerID, ParentID INTO v_parent_partner, v_parent_parent
    FROM CUSTOMER WHERE AccountID = NEW.ParentID;

    IF v_parent_parent IS NOT NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] PARENT_OF is strictly single-level; parent cannot itself be a child.';
    END IF;

    IF v_parent_partner IS NULL OR v_parent_partner <> NEW.PartnerID THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Parent and child must belong to the same partner.';
    END IF;
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_customer_bu_c10 $$
CREATE TRIGGER trg_customer_bu_c10
BEFORE UPDATE ON CUSTOMER
FOR EACH ROW
BEGIN
  DECLARE v_parent_partner INT;
  DECLARE v_parent_parent INT;

  IF NEW.RoleName IS NOT NULL AND NEW.PartnerID IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '[C10] Standalone customers (PartnerID IS NULL) cannot hold a portal role.';
  END IF;

  -- Parent PartnerID change would orphan/split children across partners
  IF NOT (NEW.PartnerID <=> OLD.PartnerID)
     AND EXISTS (SELECT 1 FROM CUSTOMER WHERE ParentID = NEW.AccountID) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '[C10] Cannot change PartnerID: this customer has children.';
  END IF;

  IF NEW.ParentID IS NOT NULL THEN
    IF NEW.ParentID = NEW.AccountID THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Customer cannot be its own parent.';
    END IF;

    -- H1: demoting a parent that already has children would create depth > 1
    IF EXISTS (SELECT 1 FROM CUSTOMER WHERE ParentID = NEW.AccountID) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Cannot assign ParentID: this customer already has children (depth-1).';
    END IF;

    IF NEW.PartnerID IS NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Child customers must belong to a partner (PartnerID NOT NULL).';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM CUSTOMER WHERE AccountID = NEW.ParentID) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] ParentID must reference an existing customer.';
    END IF;

    SELECT PartnerID, ParentID INTO v_parent_partner, v_parent_parent
    FROM CUSTOMER WHERE AccountID = NEW.ParentID;

    IF v_parent_parent IS NOT NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] PARENT_OF is strictly single-level; parent cannot itself be a child.';
    END IF;

    IF v_parent_partner IS NULL OR v_parent_partner <> NEW.PartnerID THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Parent and child must belong to the same partner.';
    END IF;
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_customer_au_c10_integrates $$
CREATE TRIGGER trg_customer_au_c10_integrates
AFTER UPDATE ON CUSTOMER
FOR EACH ROW
BEGIN
  DECLARE v_partner INT;

  IF NOT (NEW.PartnerID <=> OLD.PartnerID) THEN
    SELECT PartnerID INTO v_partner
    FROM PARTNER
    WHERE IntegrationID = NEW.AccountID
    LIMIT 1;

    IF v_partner IS NOT NULL AND (NEW.PartnerID IS NULL OR NEW.PartnerID <> v_partner) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] Integration customer must BELONG_TO the partner that INTEGRATES it.';
    END IF;
  END IF;
END $$

-- H3: block PARTNER INSERT/UPDATE that points IntegrationID at a customer
-- belonging to a *different* partner. PartnerID NULL on the customer is allowed
-- during seed bootstrap (then CUSTOMER UPDATEs + sp_Validate close the path).
DROP TRIGGER IF EXISTS trg_partner_bi_c10_integrates $$
CREATE TRIGGER trg_partner_bi_c10_integrates
BEFORE INSERT ON PARTNER
FOR EACH ROW
BEGIN
  DECLARE v_cust_partner INT;

  SELECT PartnerID INTO v_cust_partner
  FROM CUSTOMER WHERE AccountID = NEW.IntegrationID;

  IF v_cust_partner IS NOT NULL AND v_cust_partner <> NEW.PartnerID THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '[C10] IntegrationID customer already BELONGS_TO a different partner.';
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_partner_bu_c10_integrates $$
CREATE TRIGGER trg_partner_bu_c10_integrates
BEFORE UPDATE ON PARTNER
FOR EACH ROW
BEGIN
  DECLARE v_cust_partner INT;

  IF NOT (NEW.IntegrationID <=> OLD.IntegrationID)
     OR NOT (NEW.PartnerID <=> OLD.PartnerID) THEN
    SELECT PartnerID INTO v_cust_partner
    FROM CUSTOMER WHERE AccountID = NEW.IntegrationID;

    -- Strict on UPDATE: Integration customer must already BELONG_TO this partner
    IF v_cust_partner IS NULL OR v_cust_partner <> NEW.PartnerID THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C10] IntegrationID customer must BELONG_TO this partner (PartnerID required).';
    END IF;
  END IF;
END $$

DROP PROCEDURE IF EXISTS sp_Validate_PartnerIntegrations $$
CREATE PROCEDURE sp_Validate_PartnerIntegrations()
BEGIN
  DECLARE v_bad INT DEFAULT 0;

  -- LEFT JOIN so a missing Integration customer counts as bad (not silently OK)
  SELECT COUNT(*) INTO v_bad
  FROM PARTNER p
  LEFT JOIN CUSTOMER c ON c.AccountID = p.IntegrationID
  WHERE c.AccountID IS NULL
     OR c.PartnerID IS NULL
     OR c.PartnerID <> p.PartnerID;

  IF v_bad > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '[C10] One or more IntegrationID customers do not BELONG_TO their partner.';
  END IF;

  SELECT 'OK: all IntegrationID customers BELONG_TO their partner' AS notice;
END $$

DELIMITER ;
-- After seed links: CALL sp_Validate_PartnerIntegrations();
SELECT 'TRACK_D programmability loaded' AS notice;
