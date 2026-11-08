-- Track B — §2.2.2 derived RequestFee/TotalFee → Balance chain
-- Run after reset_demo.sql once triggers + seed rows exist.

USE ahamove_a2;

-- Before state (Order 102 / Customer 3):
-- SELECT OrderID, RequestFee, TotalFee FROM `ORDER` WHERE OrderID = 102;
-- SELECT AccountID, Balance FROM CUSTOMER WHERE AccountID = 3;

-- Fire Attribute B then A:
-- INSERT INTO ORDER_REQUEST (OrderID, RequestCode, Quantity) VALUES (102, 'LOADING', 2);

-- After state:
-- SELECT OrderID, RequestFee, TotalFee FROM `ORDER` WHERE OrderID = 102;
-- SELECT AccountID, Balance FROM CUSTOMER WHERE AccountID = 3;

SELECT 'TODO: uncomment derived-fee demo after Track B implements triggers + seed.' AS notice;
