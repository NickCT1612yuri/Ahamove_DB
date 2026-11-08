-- Track A — §2.1 ORDER CRUD procedures

USE ahamove_a2;

-- Happy path create (BALANCE + promo):
-- CALL sp_Order_Create(
--   1, 'SGN', 'BIKE', 'BALANCE', 6.5, 5.0, 1, 'AHA50', NULL,
--   '268 Ly Thuong Kiet Q10', 'Minh Nhat', '0901000001',
--   '01 Vo Van Ngan Thu Duc', 'The Nhan', '0909111222', 150000
-- );

-- Lifecycle withdraw (Order 103 WithdrawCount 4 → 5 → SYSTEM cancel):
-- CALL sp_Order_UpdateLifecycle(103, 'WITHDRAW_DRIVER', 7, NULL, NULL, NULL);

-- Delete draft Order 101:
-- CALL sp_Order_Delete(101, 1);

-- Failure: delete completed order
-- CALL sp_Order_Delete(105, 1);

SELECT 'TODO: uncomment CRUD calls after Track A implements procedure bodies + seed.' AS notice;
