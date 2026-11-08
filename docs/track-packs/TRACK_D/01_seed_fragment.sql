-- TRACK D seed lego
-- COPY from here → PASTE into sql/02_seed.sql at “PASTE TRACK_D HERE”
-- D-owned only: STAFF, STAFF_PERMISSION, PARTNER, PARTNER_ROLE, ROLE_PERMISSION
-- + CUSTOMER PartnerID/RoleName/ParentID UPDATEs (C10 links).
--
-- Cross-track deps: ask owner to add to THEIR pack; propose under their PASTE
-- slot in sql/02_seed.sql (commented INSERTs). Do not insert under Track D.
--
-- Ask Track B (ACCOUNT/CUSTOMER) — already in TRACK_B/01:
-- INSERT INTO ACCOUNT (AccountID, PhoneNumber, Email, Name, AccountStatus, AccountType) VALUES
-- (16, '0901000016', 'bhx.int@example.com', 'BHX Integration', 'ACTIVE', 'CUSTOMER')
-- ON DUPLICATE KEY UPDATE Name = VALUES(Name);
-- INSERT INTO CUSTOMER (AccountID, Balance, CreditLimit, ParentID, PartnerID, RoleName) VALUES
-- (16, 250000, 1000000, NULL, NULL, NULL)
-- ON DUPLICATE KEY UPDATE Balance = VALUES(Balance);
-- Also needs ACCOUNT/CUSTOMER 1–5 and ACCOUNT 11–15 (staff) from TRACK_B/01.
--
-- Ask Track C (OWNER for PARTNER.OwnerID) — already in TRACK_C/01:
-- INSERT INTO OWNER (OwnerID, OwnerType) VALUES
-- (5, 'PARTNER'),
-- (6, 'PARTNER')
-- ON DUPLICATE KEY UPDATE OwnerType = VALUES(OwnerType);
--
-- Integration map (C10 INTEGRATES ↔ BELONGS_TO):
--   Partner 1 Coffee      IntegrationID=3  → cust 3 PartnerID=1 Admin
--   Partner 2 Pharmacity  IntegrationID=4  → cust 4 PartnerID=2 Admin
--   Partner 3 Fahasa      IntegrationID=1  → cust 1 PartnerID=3 Viewer
--   Partner 4 TikiNow     IntegrationID=2  → cust 2 PartnerID=4 Viewer
--   Partner 5 BHX         IntegrationID=16 → cust 16 PartnerID=5 Admin
-- Hierarchy: cust 5 ParentID=3, PartnerID=1, RoleName=Viewer (child under Coffee)
USE ahamove_a2;
SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO STAFF (AccountID, Position) VALUES
(11, 'Ops Supervisor'),
(12, 'Support Agent'),
(13, 'Catalogue Admin'),
(14, 'Promo Manager'),
(15, 'Driver Verifier')
ON DUPLICATE KEY UPDATE Position = VALUES(Position);

INSERT INTO STAFF_PERMISSION (StaffID, Permission) VALUES
(11, 'CANCEL_ORDER'),
(11, 'SUPERVISE_ORDER'),
(12, 'SUPERVISE_ORDER'),
(13, 'MANAGE_CATALOGUE'),
(14, 'MANAGE_PROMOTION'),
(15, 'VERIFY_DRIVER')
ON DUPLICATE KEY UPDATE Permission = VALUES(Permission);

INSERT INTO PARTNER (PartnerID, APIKey, LegalName, WebhookURL, IntegrationID, OwnerID) VALUES
(1, 'key_coffee_01', 'Coffee House HQ', 'https://example.com/hook/coffee', 3, 5),
(2, 'key_pharma_02', 'Pharmacity', 'https://example.com/hook/pharma', 4, 6),
(3, 'key_fahasa_03', 'Fahasa', 'https://example.com/hook/fahasa', 1, NULL),
(4, 'key_tiki_04', 'TikiNow', 'https://example.com/hook/tiki', 2, NULL),
(5, 'key_bhx_05', 'Bach Hoa Xanh', 'https://example.com/hook/bhx', 16, NULL)
ON DUPLICATE KEY UPDATE
  LegalName = VALUES(LegalName),
  IntegrationID = VALUES(IntegrationID);

INSERT INTO PARTNER_ROLE (PartnerID, RoleName) VALUES
(1, 'Admin'),
(1, 'mod'),
(1, 'Viewer'),
(2, 'Admin'),
(2, 'Viewer'),
(3, 'Admin'),
(3, 'Viewer'),
(4, 'Admin'),
(4, 'Viewer'),
(5, 'Admin'),
(5, 'Viewer')
ON DUPLICATE KEY UPDATE RoleName = VALUES(RoleName);

-- A1 six portal permissions
INSERT INTO ROLE_PERMISSION (PartnerID, RoleName, Permission) VALUES
(1, 'Admin', 'MANAGE_ORDERS'),
(1, 'Admin', 'MANAGE_EMPLOYEES'),
(1, 'Admin', 'MANAGE_API_ACCOUNT'),
(1, 'Admin', 'UPDATE_ALL_ORDERS'),
(1, 'Admin', 'UPDATE_OWN_ORDERS'),
(1, 'Admin', 'VIEW_ALL_ORDERS'),
(1, 'mod', 'UPDATE_ALL_ORDERS'),
(1, 'mod', 'UPDATE_OWN_ORDERS'),
(1, 'mod', 'VIEW_ALL_ORDERS'),
(1, 'Viewer', 'VIEW_ALL_ORDERS'),
(2, 'Admin', 'MANAGE_ORDERS'),
(2, 'Admin', 'MANAGE_EMPLOYEES'),
(2, 'Admin', 'MANAGE_API_ACCOUNT'),
(2, 'Admin', 'UPDATE_ALL_ORDERS'),
(2, 'Admin', 'UPDATE_OWN_ORDERS'),
(2, 'Admin', 'VIEW_ALL_ORDERS'),
(2, 'Viewer', 'VIEW_ALL_ORDERS'),
(3, 'Admin', 'MANAGE_ORDERS'),
(3, 'Admin', 'VIEW_ALL_ORDERS'),
(3, 'Viewer', 'VIEW_ALL_ORDERS'),
(4, 'Admin', 'MANAGE_ORDERS'),
(4, 'Admin', 'MANAGE_API_ACCOUNT'),
(4, 'Admin', 'VIEW_ALL_ORDERS'),
(4, 'Viewer', 'VIEW_ALL_ORDERS'),
(5, 'Admin', 'MANAGE_ORDERS'),
(5, 'Admin', 'MANAGE_EMPLOYEES'),
(5, 'Admin', 'MANAGE_API_ACCOUNT'),
(5, 'Admin', 'UPDATE_ALL_ORDERS'),
(5, 'Admin', 'UPDATE_OWN_ORDERS'),
(5, 'Admin', 'VIEW_ALL_ORDERS'),
(5, 'Viewer', 'VIEW_ALL_ORDERS')
ON DUPLICATE KEY UPDATE Permission = VALUES(Permission);

UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Admin',  ParentID = NULL WHERE AccountID = 3;
UPDATE CUSTOMER SET PartnerID = 2, RoleName = 'Admin',  ParentID = NULL WHERE AccountID = 4;
UPDATE CUSTOMER SET PartnerID = 3, RoleName = 'Viewer', ParentID = NULL WHERE AccountID = 1;
UPDATE CUSTOMER SET PartnerID = 4, RoleName = 'Viewer', ParentID = NULL WHERE AccountID = 2;
UPDATE CUSTOMER SET PartnerID = 5, RoleName = 'Admin',  ParentID = NULL WHERE AccountID = 16;
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Viewer', ParentID = 3    WHERE AccountID = 5;

SET FOREIGN_KEY_CHECKS = 1;

-- After 03_programmability.sql (Track D) is loaded:
--   CALL sp_Validate_PartnerIntegrations();

SELECT 'TRACK_D seed loaded' AS notice;
