USE ahamove_a2;

-- Happy create
CALL sp_Order_Create(
  1, 'SGN', 'BIKE', 'BALANCE', 6.5, 5.0, 1, 'AHA50', NULL,
  '268 Ly Thuong Kiet Q10', 'Minh Nhat', '0901000001',
  '01 Vo Van Ngan Thu Duc', 'The Nhan', '0909111222', 150000
);

-- Failure: expired promo
-- CALL sp_Order_Create(1,'SGN','BIKE','CASH',3,2,1,'EXP2025',NULL,'a','n','0901','b','m','0902',0);

-- Failure: low wallet customer 2
-- CALL sp_Order_Create(2,'SGN','BIKE','BALANCE',10,5,1,NULL,NULL,'a','n','0901','b','m','0902',0);

-- Withdraw on 103 (WithdrawCount 4 → 5 → SYSTEM cancel + refund)
CALL sp_Order_UpdateLifecycle(103, 'WITHDRAW_DRIVER', 7, NULL, NULL, NULL);

-- Delete draft 101
CALL sp_Order_Delete(101, 1);

-- Delete completed should fail
-- CALL sp_Order_Delete(105, 1);
