-- =============================================================================
-- Track D — unified test harness
-- Run AFTER schema + seed + 03_programmability.sql
--   mysql -u root -p ahamove_a2 < tests/test_track_d.sql
--
-- §1 Search     — sp_Order_SearchDetailed happy + empty-result edges
-- §2 Constraints — C10 / C12 / UNIQUE / FK negatives via sp_TrackD_ExpectFail
-- §3 Final      — validate Integrations; drop helper
-- =============================================================================

USE ahamove_a2;

-- =============================================================================
-- §1 Search (sp_Order_SearchDetailed)
-- =============================================================================

-- Happy path: SGN + BALANCE + phone keyword, sort by fee
CALL sp_Order_SearchDetailed('SGN', NULL, 'BALANCE', '090', '2026-10-01', '2026-11-30', 'FEE_DESC');

-- Filter completed orders only
CALL sp_Order_SearchDetailed(NULL, 'COMPLETED', NULL, NULL, NULL, NULL, 'CREATED_DESC');

-- Broad list (all optional filters NULL except sort)
CALL sp_Order_SearchDetailed(NULL, NULL, NULL, NULL, NULL, NULL, 'DISTANCE_ASC');

-- Edge: unknown city → expect 0 rows
CALL sp_Order_SearchDetailed('XXX', NULL, NULL, NULL, NULL, NULL, 'CREATED_DESC');

-- Edge: phone keyword with no match → expect 0 rows
CALL sp_Order_SearchDetailed(NULL, NULL, NULL, '9999999999', NULL, NULL, 'CREATED_DESC');

-- Edge: date window outside seeded orders → expect 0 rows
CALL sp_Order_SearchDetailed(NULL, NULL, NULL, NULL, '2099-01-01', '2099-12-31', 'FEE_DESC');

-- Edge: unknown p_SortBy → still returns rows; ORDER BY falls back to CreatedAt DESC
CALL sp_Order_SearchDetailed(NULL, NULL, NULL, NULL, NULL, NULL, 'NOT_A_SORT');

-- =============================================================================
-- §2 Constraints (C10 / C12 / UNIQUE / FK + hole-audit)
-- Negatives via sp_TrackD_ExpectFail so the script continues after each error.
-- =============================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_TrackD_ExpectFail $$
CREATE PROCEDURE sp_TrackD_ExpectFail(
  IN p_Label VARCHAR(120),
  IN p_Sql TEXT
)
BEGIN
  DECLARE v_errno INT DEFAULT 0;
  DECLARE v_msg TEXT DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1
      v_errno = MYSQL_ERRNO,
      v_msg = MESSAGE_TEXT;
  END;

  SET v_errno = 0;
  SET v_msg = NULL;
  SET @dyn = p_Sql;
  PREPARE stmt FROM @dyn;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  IF v_errno = 0 THEN
    SELECT p_Label AS test_case, 'UNEXPECTED PASS' AS result, NULL AS errno, NULL AS message;
  ELSE
    SELECT p_Label AS test_case, 'EXPECTED FAIL' AS result, v_errno AS errno, v_msg AS message;
  END IF;
END $$

DELIMITER ;

-- ---------------------------------------------------------------------------
-- Happy path: Integration customers BELONG_TO their partners
-- ---------------------------------------------------------------------------
CALL sp_Validate_PartnerIntegrations();

-- ---------------------------------------------------------------------------
-- 1) Bad STAFF_PERMISSION → CHECK chk_staff_permission
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  '1 STAFF_PERMISSION bad enum',
  'INSERT INTO STAFF_PERMISSION (StaffID, Permission) VALUES (11, ''NOT_A_PERM'')'
);

-- ---------------------------------------------------------------------------
-- 2) Old invented portal perm PLACE_ORDER → CHECK chk_role_permission (A1 enum)
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  '2 ROLE_PERMISSION PLACE_ORDER rejected',
  'INSERT INTO ROLE_PERMISSION (PartnerID, RoleName, Permission) VALUES (1, ''Admin'', ''PLACE_ORDER'')'
);

-- ---------------------------------------------------------------------------
-- 3) Duplicate IntegrationID → UNIQUE uk_partner_integration
-- Disposable customer with PartnerID NULL so PARTNER C10 BI does not fire first
-- (cross-BELONGS_TO path is covered by H3).
-- ---------------------------------------------------------------------------
INSERT INTO ACCOUNT (AccountID, PhoneNumber, Email, Name, AccountStatus, AccountType) VALUES
(98, '0901000098', 'dup.int@example.com', 'Dup Integration Target', 'ACTIVE', 'CUSTOMER')
ON DUPLICATE KEY UPDATE Name = VALUES(Name);
INSERT INTO CUSTOMER (AccountID, Balance, CreditLimit, ParentID, PartnerID, RoleName) VALUES
(98, 0, 0, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE Balance = VALUES(Balance);
INSERT INTO PARTNER (PartnerID, APIKey, LegalName, WebhookURL, IntegrationID, OwnerID) VALUES
(98, 'key_tmp_98', 'Temp Partner For Unique', 'https://example.com/hook/tmp98', 98, NULL)
ON DUPLICATE KEY UPDATE LegalName = VALUES(LegalName);
CALL sp_TrackD_ExpectFail(
  '3 duplicate IntegrationID',
  'INSERT INTO PARTNER (PartnerID, APIKey, LegalName, WebhookURL, IntegrationID, OwnerID) VALUES (99, ''key_dup_99'', ''Dup Integration Partner'', ''https://example.com/hook/dup'', 98, NULL)'
);
DELETE FROM PARTNER WHERE PartnerID = 98;
DELETE FROM CUSTOMER WHERE AccountID = 98;
DELETE FROM ACCOUNT WHERE AccountID = 98;

-- ---------------------------------------------------------------------------
-- 4) RoleName not defined for customer's partner → composite FK
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  '4 cross/missing partner role FK',
  'UPDATE CUSTOMER SET PartnerID = 1, RoleName = ''DoesNotExist'' WHERE AccountID = 3'
);
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 3;

-- ---------------------------------------------------------------------------
-- 5) Child-as-parent (depth-1) → C10 (child 5 cannot be parent of 16)
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  '5 depth-1 PARENT_OF',
  'UPDATE CUSTOMER SET PartnerID = 1, RoleName = ''Viewer'', ParentID = 5 WHERE AccountID = 16'
);
UPDATE CUSTOMER SET PartnerID = 5, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 16;

-- ---------------------------------------------------------------------------
-- 6) Cross-partner ParentID → C10
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  '6 cross-partner ParentID',
  'UPDATE CUSTOMER SET PartnerID = 2, RoleName = ''Admin'', ParentID = 3 WHERE AccountID = 4'
);
UPDATE CUSTOMER SET PartnerID = 2, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 4;

-- ---------------------------------------------------------------------------
-- 7) Detach Integration customer PartnerID → C10 AFTER UPDATE
-- Cust 4 (Pharmacity Integration, no children) so parent-PartnerID lock does
-- not fire first (that path is H4).
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  '7 detach Integration BELONGS_TO',
  'UPDATE CUSTOMER SET PartnerID = NULL, RoleName = NULL, ParentID = NULL WHERE AccountID = 4'
);
UPDATE CUSTOMER SET PartnerID = 2, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 4;

-- ---------------------------------------------------------------------------
-- H2) Self-parent → C10
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  'H2 self-parent',
  'UPDATE CUSTOMER SET ParentID = 3 WHERE AccountID = 3'
);
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 3;

-- ---------------------------------------------------------------------------
-- H1) Demote parent that already has children → C10 depth-1
-- Cust 3 is parent of 5; cannot set ParentID on 3.
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  'H1 demote parent with children',
  'UPDATE CUSTOMER SET ParentID = 16, PartnerID = 1, RoleName = ''Admin'' WHERE AccountID = 3'
);
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 3;
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Viewer', ParentID = 3 WHERE AccountID = 5;

-- ---------------------------------------------------------------------------
-- H3) Retarget PARTNER.IntegrationID to customer belonging to another partner
-- Cust 5 BELONGS_TO partner 1; partner 5 must not INTEGRATE 5.
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  'H3 PARTNER IntegrationID cross-BELONGS_TO',
  'UPDATE PARTNER SET IntegrationID = 5 WHERE PartnerID = 5'
);
UPDATE PARTNER SET IntegrationID = 16 WHERE PartnerID = 5;
UPDATE CUSTOMER SET PartnerID = 5, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 16;

-- ---------------------------------------------------------------------------
-- H4) Parent PartnerID change while children exist → C10
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  'H4 parent PartnerID change with children',
  'UPDATE CUSTOMER SET PartnerID = 2, RoleName = ''Admin'', ParentID = NULL WHERE AccountID = 3'
);
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Admin', ParentID = NULL WHERE AccountID = 3;
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Viewer', ParentID = 3 WHERE AccountID = 5;

-- ---------------------------------------------------------------------------
-- H5 note (validate-missing-customer): sp_Validate_PartnerIntegrations uses
-- LEFT JOIN CUSTOMER so a missing IntegrationID row counts as bad.
-- Live demo: after seed, CALL sp_Validate_PartnerIntegrations() → OK.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- H9) Search inverted date window → SIGNAL
-- ---------------------------------------------------------------------------
CALL sp_TrackD_ExpectFail(
  'H9 inverted date window',
  'CALL sp_Order_SearchDetailed(NULL, NULL, NULL, NULL, ''2026-12-01'', ''2026-01-01'', ''CREATED_DESC'')'
);

-- =============================================================================
-- §3 Final
-- =============================================================================

CALL sp_Validate_PartnerIntegrations();

DROP PROCEDURE IF EXISTS sp_TrackD_ExpectFail;

SELECT 'test_track_d.sql finished' AS notice;
