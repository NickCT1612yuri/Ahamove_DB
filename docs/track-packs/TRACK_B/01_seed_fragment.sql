-- TRACK B seed: SPECIAL_REQUEST, ACCOUNT, CUSTOMER, TRANSACTION, ORDER_REQUEST
USE ahamove_a2;
SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO SPECIAL_REQUEST (RequestCode, ReqName, RequestType) VALUES
('EXPRESS', 'Express handling', 'BOOLEAN'),
('RETURN_TRIP', 'Return trip', 'BOOLEAN'),
('TIP', 'Driver tip', 'PER_UNIT'),
('LOADING', 'Loading help', 'PER_UNIT'),
('WAITING', 'Waiting time', 'PER_UNIT')
ON DUPLICATE KEY UPDATE ReqName = VALUES(ReqName);

-- Accounts 1–5 customers, 6–10 drivers, 11–15 staff
INSERT INTO ACCOUNT (AccountID, PhoneNumber, Email, Name, AccountStatus, AccountType) VALUES
(1,  '0901000001', 'cust1@example.com', 'Minh Nhat Customer', 'ACTIVE', 'CUSTOMER'),
(2,  '0901000002', 'cust2@example.com', 'Low Balance Customer', 'ACTIVE', 'CUSTOMER'),
(3,  '0901000003', 'coffee.int@example.com', 'Coffee House Integration', 'ACTIVE', 'CUSTOMER'),
(4,  '0901000004', 'pharma.int@example.com', 'Pharmacity Integration', 'ACTIVE', 'CUSTOMER'),
(5,  '0901000005', 'cust5@example.com', 'Child Partner Customer', 'ACTIVE', 'CUSTOMER'),
(6,  '0902000006', 'drv6@example.com', 'Driver Happy Path', 'ACTIVE', 'DRIVER'),
(7,  '0902000007', 'drv7@example.com', 'Driver Busy', 'ACTIVE', 'DRIVER'),
(8,  '0902000008', 'drv8@example.com', 'Driver Unverified', 'ACTIVE', 'DRIVER'),
(9,  '0902000009', 'drv9@example.com', 'Driver Expired Docs', 'ACTIVE', 'DRIVER'),
(10, '0902000010', 'drv10@example.com', 'Driver Offline', 'ACTIVE', 'DRIVER'),
(11, '0903000011', 'staff11@example.com', 'Staff Cancel Ops', 'ACTIVE', 'STAFF'),
(12, '0903000012', 'staff12@example.com', 'Staff No Cancel', 'ACTIVE', 'STAFF'),
(13, '0903000013', 'staff13@example.com', 'Staff Catalogue', 'ACTIVE', 'STAFF'),
(14, '0903000014', 'staff14@example.com', 'Staff Promo', 'ACTIVE', 'STAFF'),
(15, '0903000015', 'staff15@example.com', 'Staff Verify', 'ACTIVE', 'STAFF')
ON DUPLICATE KEY UPDATE Name = VALUES(Name);

INSERT INTO CUSTOMER (AccountID, Balance, CreditLimit, ParentID, PartnerID, RoleName) VALUES
(1, 500000, 0, NULL, NULL, NULL),
(2, 20000, 0, NULL, NULL, NULL),
(3, 465000, 5000000, NULL, NULL, NULL),
(4, 300000, 2000000, NULL, NULL, NULL),
(5, 100000, 0, 3, NULL, NULL)
ON DUPLICATE KEY UPDATE Balance = VALUES(Balance);

-- Load TRANSACTION / ORDER_REQUEST AFTER Track A orders exist (or keep FK checks off).
INSERT INTO TRANSACTION (TxnID, TxnType, Amount, CreatedAt, AccountID, OrderID, SeqNo) VALUES
(1,  'TOPUP',    500000,  '2026-10-01 08:00:00', 1, NULL, NULL),
(2,  'TOPUP',    20000,   '2026-10-01 08:00:00', 2, NULL, NULL),
(3,  'TOPUP',    500000,  '2026-10-01 08:00:00', 3, NULL, NULL),
(4,  'PAYMENT', -35000,   '2026-10-15 09:00:00', 3, 102, NULL),
(5,  'PAYMENT', -48000,   '2026-10-16 10:00:00', 1, 103, NULL),
(6,  'TOPUP',    300000,  '2026-10-02 08:00:00', 4, NULL, NULL),
(7,  'TOPUP',    100000,  '2026-10-02 08:00:00', 5, NULL, NULL),
(8,  'EARNING',  80000,   '2026-10-20 18:00:00', 6, 105, NULL),
(9,  'COMMISSION',-16000, '2026-10-20 18:00:00', 6, 105, NULL),
(10, 'EARNING',  90000,   '2026-10-21 18:00:00', 6, 106, NULL),
(11, 'COMMISSION',-18000, '2026-10-21 18:00:00', 6, 106, NULL),
(12, 'COD',     -200000,  '2026-10-20 18:05:00', 6, 105, 1)
ON DUPLICATE KEY UPDATE Amount = VALUES(Amount);

INSERT INTO ORDER_REQUEST (OrderID, RequestCode, Quantity) VALUES
(105, 'LOADING', 1),
(105, 'TIP', 2),
(106, 'EXPRESS', 1),
(107, 'WAITING', 1),
(102, 'TIP', 1)
ON DUPLICATE KEY UPDATE Quantity = VALUES(Quantity);

SET FOREIGN_KEY_CHECKS = 1;
SELECT 'TRACK_B seed loaded' AS notice;
