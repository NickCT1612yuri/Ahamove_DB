-- TRACK B: derived fee (B) then wallet balance (A)
USE ahamove_a2;
DELIMITER $$

DROP PROCEDURE IF EXISTS _recompute_order_request_fee $$
CREATE PROCEDURE _recompute_order_request_fee(IN p_OrderID INT)
BEGIN
  DECLARE v_req BIGINT DEFAULT 0;
  DECLARE v_dist BIGINT;
  DECLARE v_stop BIGINT;
  DECLARE v_disc BIGINT;
  DECLARE v_total BIGINT;
  DECLARE v_pay VARCHAR(30);
  DECLARE v_status VARCHAR(20);
  DECLARE v_cust INT;
  DECLARE v_txn INT;

  SELECT COALESCE(SUM(sr.Price * orq.Quantity), 0) INTO v_req
  FROM ORDER_REQUEST orq
  JOIN `ORDER` o ON o.OrderID = orq.OrderID
  JOIN SERVICE_REQUEST sr
    ON sr.CityID = o.CityID AND sr.GroupCode = o.GroupCode AND sr.RequestCode = orq.RequestCode
  WHERE orq.OrderID = p_OrderID;

  SELECT DistanceFee, StopFee, Discount, PaymentMethod, Status, CustomerID
    INTO v_dist, v_stop, v_disc, v_pay, v_status, v_cust
  FROM `ORDER` WHERE OrderID = p_OrderID;

  SET v_total = v_dist + v_stop + v_req - v_disc;
  IF v_total < 0 THEN SET v_total = 0; END IF;

  UPDATE `ORDER`
     SET RequestFee = v_req, TotalFee = v_total
   WHERE OrderID = p_OrderID;

  -- Adjust unstarted BALANCE payment txn to match new TotalFee
  IF v_pay = 'BALANCE' AND v_status IN ('IDLE', 'ASSIGNING') THEN
    SELECT TxnID INTO v_txn FROM TRANSACTION
     WHERE OrderID = p_OrderID AND AccountID = v_cust AND TxnType = 'PAYMENT'
     ORDER BY TxnID LIMIT 1;
    IF v_txn IS NOT NULL THEN
      UPDATE TRANSACTION SET Amount = -v_total WHERE TxnID = v_txn;
    END IF;
  END IF;
END $$

DROP PROCEDURE IF EXISTS _sync_account_balance $$
CREATE PROCEDURE _sync_account_balance(IN p_AccountID INT)
BEGIN
  DECLARE v_sum BIGINT DEFAULT 0;
  DECLARE v_limit BIGINT DEFAULT 0;
  DECLARE v_type VARCHAR(20);

  SELECT AccountType INTO v_type FROM ACCOUNT WHERE AccountID = p_AccountID;
  SELECT COALESCE(SUM(Amount), 0) INTO v_sum FROM TRANSACTION WHERE AccountID = p_AccountID;

  IF v_type = 'CUSTOMER' THEN
    SELECT CreditLimit INTO v_limit FROM CUSTOMER WHERE AccountID = p_AccountID;
    IF v_sum < -v_limit THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C11_Wallet] Balance would fall below -CreditLimit.';
    END IF;
    UPDATE CUSTOMER SET Balance = v_sum WHERE AccountID = p_AccountID;
  ELSEIF v_type = 'DRIVER' THEN
    SELECT CreditLimit INTO v_limit FROM DRIVER WHERE AccountID = p_AccountID;
    IF v_sum < -v_limit THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '[C11_Wallet] Driver balance would fall below -CreditLimit.';
    END IF;
    UPDATE DRIVER SET Balance = v_sum WHERE AccountID = p_AccountID;
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_OrderReq_AfterInsert_SyncFee $$
CREATE TRIGGER trg_OrderReq_AfterInsert_SyncFee
AFTER INSERT ON ORDER_REQUEST
FOR EACH ROW
BEGIN
  CALL _recompute_order_request_fee(NEW.OrderID);
END $$

DROP TRIGGER IF EXISTS trg_OrderReq_AfterUpdate_SyncFee $$
CREATE TRIGGER trg_OrderReq_AfterUpdate_SyncFee
AFTER UPDATE ON ORDER_REQUEST
FOR EACH ROW
BEGIN
  CALL _recompute_order_request_fee(NEW.OrderID);
END $$

DROP TRIGGER IF EXISTS trg_OrderReq_AfterDelete_SyncFee $$
CREATE TRIGGER trg_OrderReq_AfterDelete_SyncFee
AFTER DELETE ON ORDER_REQUEST
FOR EACH ROW
BEGIN
  CALL _recompute_order_request_fee(OLD.OrderID);
END $$

DROP TRIGGER IF EXISTS trg_Txn_AfterInsert_SyncBalance $$
CREATE TRIGGER trg_Txn_AfterInsert_SyncBalance
AFTER INSERT ON TRANSACTION
FOR EACH ROW
BEGIN
  CALL _sync_account_balance(NEW.AccountID);
END $$

DROP TRIGGER IF EXISTS trg_Txn_AfterUpdate_SyncBalance $$
CREATE TRIGGER trg_Txn_AfterUpdate_SyncBalance
AFTER UPDATE ON TRANSACTION
FOR EACH ROW
BEGIN
  CALL _sync_account_balance(NEW.AccountID);
  IF OLD.AccountID <> NEW.AccountID THEN
    CALL _sync_account_balance(OLD.AccountID);
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_Txn_AfterDelete_SyncBalance $$
CREATE TRIGGER trg_Txn_AfterDelete_SyncBalance
AFTER DELETE ON TRANSACTION
FOR EACH ROW
BEGIN
  CALL _sync_account_balance(OLD.AccountID);
END $$

DELIMITER ;
SELECT 'TRACK_B programmability loaded (helpers + triggers)' AS notice;
