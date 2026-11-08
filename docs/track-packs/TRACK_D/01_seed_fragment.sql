-- TRACK D seed: STAFF, STAFF_PERMISSION, PARTNER, PARTNER_ROLE, ROLE_PERMISSION
-- Requires ACCOUNT 11–15 (staff) and CUSTOMER rows for IntegrationID (Track B).
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
(3, 'key_fahasa_03', 'Fahasa', 'https://example.com/hook/fahasa', 5, NULL),
(4, 'key_tiki_04', 'TikiNow', 'https://example.com/hook/tiki', 3, NULL),
(5, 'key_bhx_05', 'Bach Hoa Xanh', 'https://example.com/hook/bhx', 4, NULL)
ON DUPLICATE KEY UPDATE LegalName = VALUES(LegalName);

INSERT INTO PARTNER_ROLE (PartnerID, RoleName) VALUES
(1, 'Dispatcher'),
(1, 'Viewer'),
(2, 'Dispatcher'),
(3, 'Viewer'),
(4, 'Dispatcher'),
(5, 'Viewer')
ON DUPLICATE KEY UPDATE RoleName = VALUES(RoleName);

INSERT INTO ROLE_PERMISSION (PartnerID, RoleName, Permission) VALUES
(1, 'Dispatcher', 'PLACE_ORDER'),
(1, 'Dispatcher', 'CANCEL_ORDER'),
(1, 'Dispatcher', 'VIEW_ORDER'),
(1, 'Viewer', 'VIEW_ORDER'),
(2, 'Dispatcher', 'PLACE_ORDER'),
(2, 'Dispatcher', 'VIEW_ORDER'),
(3, 'Viewer', 'VIEW_ORDER'),
(4, 'Dispatcher', 'PLACE_ORDER'),
(4, 'Dispatcher', 'MANAGE_WEBHOOK'),
(5, 'Viewer', 'VIEW_ORDER')
ON DUPLICATE KEY UPDATE Permission = VALUES(Permission);

-- Link partner customers to roles (optional updates; Track B may set PartnerID)
UPDATE CUSTOMER SET PartnerID = 1, RoleName = 'Dispatcher' WHERE AccountID = 3;
UPDATE CUSTOMER SET PartnerID = 2, RoleName = 'Dispatcher' WHERE AccountID = 4;

SET FOREIGN_KEY_CHECKS = 1;
SELECT 'TRACK_D seed loaded' AS notice;
