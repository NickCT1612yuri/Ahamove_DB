-- TRACK A: sp_Order_Create / UpdateLifecycle / Delete
USE ahamove_a2;
DELIMITER $$

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
  DECLARE v_active INT DEFAULT 0;
  DECLARE v_max_stops INT;
  DECLARE v_base BIGINT;
  DECLARE v_perkm BIGINT;
  DECLARE v_stopfee_unit BIGINT;
  DECLARE v_dist_fee BIGINT;
  DECLARE v_stop_fee BIGINT;
  DECLARE v_discount BIGINT DEFAULT 0;
  DECLARE v_total BIGINT;
  DECLARE v_bal BIGINT;
  DECLARE v_limit BIGINT;
  DECLARE v_dtype VARCHAR(20);
  DECLARE v_dval DECIMAL(12,2);
  DECLARE v_maxd BIGINT;
  DECLARE v_from DATETIME;
  DECLARE v_to DATETIME;
  DECLARE v_order_id INT;
  DECLARE v_status VARCHAR(20);
  DECLARE v_txn_id INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_active FROM CUSTOMER c
    JOIN ACCOUNT a ON a.AccountID = c.AccountID
   WHERE c.AccountID = p_CustomerID AND a.AccountStatus = 'ACTIVE';
  IF v_active = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C3_Customer] Customer not found or inactive.';
  END IF;

  IF p_Distance IS NULL OR p_Distance <= 0 OR p_Weight IS NULL OR p_Weight <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C1_Input] Distance and Weight must be > 0.';
  END IF;

  SELECT MaxStops, BaseFee, PerKmFee, StopFee
    INTO v_max_stops, v_base, v_perkm, v_stopfee_unit
  FROM SERVICE WHERE CityID = p_CityID AND GroupCode = p_GroupCode;
  IF v_max_stops IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C1_Service] Service not found for CityID/GroupCode.';
  END IF;
  IF p_DropoffCount IS NULL OR p_DropoffCount < 1 OR p_DropoffCount > v_max_stops THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C1_Route] DropoffCount must be between 1 and service MaxStops.';
  END IF;
  IF p_PaymentMethod = 'CASH_BY_RECIPIENT' AND p_DropoffCount > 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C3_Payment] CASH_BY_RECIPIENT allowed only for exactly one drop-off.';
  END IF;
  IF p_ScheduledAt IS NOT NULL AND p_ScheduledAt < DATE_ADD(NOW(), INTERVAL 15 MINUTE) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C6_Schedule] ScheduledAt must be at least 15 minutes from now.';
  END IF;

  SET v_dist_fee = ROUND(v_base + v_perkm * p_Distance);
  SET v_stop_fee = ROUND(v_stopfee_unit * (p_DropoffCount - 1));

  IF p_PromoCode IS NOT NULL AND p_PromoCode <> '' THEN
    SELECT DiscountType, DiscountValue, MaxDiscount, ValidFrom, ValidTo
      INTO v_dtype, v_dval, v_maxd, v_from, v_to
    FROM PROMOTION WHERE PromoCode = p_PromoCode;
    IF v_dtype IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C13_Promo] Promotion code not found.';
    END IF;
    IF NOW() < v_from OR NOW() > v_to THEN
      SET @msg = CONCAT('[C13_Promo] Promotion code ', p_PromoCode, ' is outside its validity window.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
    END IF;
    IF v_dtype = 'FIXED' THEN
      SET v_discount = LEAST(ROUND(v_dval), v_maxd);
    ELSE
      SET v_discount = LEAST(ROUND((v_dist_fee + v_stop_fee) * v_dval / 100), v_maxd);
    END IF;
  END IF;

  SET v_total = v_dist_fee + v_stop_fee - v_discount;
  IF v_total < 0 THEN SET v_total = 0; END IF;

  IF p_PaymentMethod = 'BALANCE' THEN
    SELECT Balance, CreditLimit INTO v_bal, v_limit FROM CUSTOMER WHERE AccountID = p_CustomerID;
    IF v_bal + v_limit < v_total THEN
      SET @msg = CONCAT('[C3_Wallet] Customer #', p_CustomerID, ' available funds (',
        FORMAT(v_bal + v_limit, 0), ' VND) are below TotalFee (', FORMAT(v_total, 0), ' VND).');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
    END IF;
  END IF;

  SELECT IFNULL(MAX(OrderID), 100) + 1 INTO v_order_id FROM `ORDER`;
  SET v_status = IF(p_ScheduledAt IS NULL, 'ASSIGNING', 'IDLE');

  INSERT INTO `ORDER` (
    OrderID, Status, CreatedAt, PaymentMethod, Distance, Weight,
    DistanceFee, StopFee, RequestFee, Discount, TotalFee,
    CustomerID, CityID, GroupCode, DriverID, PromoCode,
    WithdrawCount, ScheduledAt
  ) VALUES (
    v_order_id, v_status, NOW(), p_PaymentMethod, p_Distance, p_Weight,
    v_dist_fee, v_stop_fee, 0, v_discount, v_total,
    p_CustomerID, p_CityID, p_GroupCode, NULL, NULLIF(p_PromoCode, ''),
    0, p_ScheduledAt
  );

  INSERT INTO PATH_POINT (OrderID, SeqNo, TrackingNumber, Address, Lat, Lng, ContactName, ContactMobile, COD, PointStatus)
  VALUES
    (v_order_id, 0, NULL, p_PickupAddress, 0, 0, p_PickupContactName, p_PickupContactMobile, 0, 'PENDING'),
    (v_order_id, 1, CONCAT('TRK', v_order_id), p_FirstDropAddress, 0, 0,
     p_FirstDropContactName, p_FirstDropContactMobile, IFNULL(p_FirstDropCOD, 0), 'PENDING');

  IF p_PaymentMethod = 'BALANCE' THEN
    SELECT IFNULL(MAX(TxnID), 0) + 1 INTO v_txn_id FROM TRANSACTION;
    INSERT INTO TRANSACTION (TxnID, TxnType, Amount, CreatedAt, AccountID, OrderID, SeqNo)
    VALUES (v_txn_id, 'PAYMENT', -v_total, NOW(), p_CustomerID, v_order_id, NULL);
  END IF;

  COMMIT;
  SELECT v_order_id AS NewOrderID, v_total AS TotalFee, v_status AS Status;
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
  DECLARE v_status VARCHAR(20);
  DECLARE v_cust INT;
  DECLARE v_driver INT;
  DECLARE v_pay VARCHAR(30);
  DECLARE v_total BIGINT;
  DECLARE v_wd INT;
  DECLARE v_atype VARCHAR(20);
  DECLARE v_has_perm INT DEFAULT 0;
  DECLARE v_txn_id INT;
  DECLARE v_city CHAR(3);
  DECLARE v_group VARCHAR(20);
  DECLARE v_weight DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT Status, CustomerID, DriverID, PaymentMethod, TotalFee, WithdrawCount, CityID, GroupCode, Weight
    INTO v_status, v_cust, v_driver, v_pay, v_total, v_wd, v_city, v_group, v_weight
  FROM `ORDER` WHERE OrderID = p_OrderID FOR UPDATE;
  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[LifecycleError] Order not found.';
  END IF;

  SELECT AccountType INTO v_atype FROM ACCOUNT WHERE AccountID = p_ActorAccountID;

  IF p_ActionType = 'ASSIGN_DRIVER' THEN
    IF v_status NOT IN ('IDLE', 'ASSIGNING') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[LifecycleError] Can only assign driver when IDLE or ASSIGNING.';
    END IF;
    -- C8 enforced by Track C trigger on UPDATE
    UPDATE `ORDER`
       SET DriverID = p_ActorAccountID, Status = 'ACCEPTED', AcceptedAt = NOW()
     WHERE OrderID = p_OrderID;
    UPDATE DRIVER SET WorkStatus = 'BUSY' WHERE AccountID = p_ActorAccountID;

  ELSEIF p_ActionType = 'WITHDRAW_DRIVER' THEN
    IF v_status <> 'ACCEPTED' OR v_driver IS NULL OR v_driver <> p_ActorAccountID THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C7_Withdraw] Driver may withdraw only while ACCEPTED on their order.';
    END IF;
    SET v_wd = v_wd + 1;
    IF v_wd >= 5 THEN
      UPDATE `ORDER` SET
        WithdrawCount = 5, Status = 'CANCELLED', DriverID = NULL, AcceptedAt = NULL,
        CancelledByType = 'SYSTEM', CancelledAt = NOW(),
        CancelReason = 'WithdrawCount reached 5'
      WHERE OrderID = p_OrderID;
      IF v_pay = 'BALANCE' THEN
        SELECT IFNULL(MAX(TxnID), 0) + 1 INTO v_txn_id FROM TRANSACTION;
        INSERT INTO TRANSACTION (TxnID, TxnType, Amount, CreatedAt, AccountID, OrderID, SeqNo)
        VALUES (v_txn_id, 'REFUND', v_total, NOW(), v_cust, p_OrderID, NULL);
      END IF;
      UPDATE DRIVER SET WorkStatus = 'ONLINE' WHERE AccountID = p_ActorAccountID;
    ELSE
      UPDATE `ORDER` SET WithdrawCount = v_wd, Status = 'ASSIGNING', DriverID = NULL, AcceptedAt = NULL
      WHERE OrderID = p_OrderID;
      UPDATE DRIVER SET WorkStatus = 'ONLINE' WHERE AccountID = p_ActorAccountID;
    END IF;

  ELSEIF p_ActionType = 'START_TRIP' THEN
    IF v_status <> 'ACCEPTED' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[LifecycleError] START_TRIP requires ACCEPTED.';
    END IF;
    UPDATE `ORDER` SET Status = 'IN_PROCESS', StartedAt = NOW() WHERE OrderID = p_OrderID;

  ELSEIF p_ActionType = 'COMPLETE_ORDER' THEN
    IF v_status <> 'IN_PROCESS' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[LifecycleError] COMPLETE_ORDER requires IN_PROCESS.';
    END IF;
    UPDATE `ORDER` SET Status = 'COMPLETED', CompletedAt = NOW() WHERE OrderID = p_OrderID;
    IF v_driver IS NOT NULL THEN
      UPDATE DRIVER SET WorkStatus = 'ONLINE' WHERE AccountID = v_driver;
    END IF;

  ELSEIF p_ActionType = 'CANCEL_ORDER' THEN
    IF v_status IN ('COMPLETED', 'CANCELLED') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[LifecycleError] Cannot cancel COMPLETED/CANCELLED order.';
    END IF;
    IF v_atype = 'CUSTOMER' THEN
      IF p_ActorAccountID <> v_cust THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C7_Cancel] Customer can only cancel own order.';
      END IF;
      IF v_status = 'IN_PROCESS' THEN
        SET @msg = CONCAT('[LifecycleError] Customer #', p_ActorAccountID,
          ' cannot cancel Order #', p_OrderID, ' because trip is already IN_PROCESS.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
      END IF;
      UPDATE `ORDER` SET Status = 'CANCELLED', CancelledBy = p_ActorAccountID, CancelledByType = 'CUSTOMER',
        CancelledAt = NOW(), CancelReason = p_CancelReason, DriverID = NULL
      WHERE OrderID = p_OrderID;
    ELSEIF v_atype = 'STAFF' THEN
      SELECT COUNT(*) INTO v_has_perm FROM STAFF_PERMISSION
       WHERE StaffID = p_ActorAccountID AND Permission = 'CANCEL_ORDER';
      IF v_has_perm = 0 THEN
        SET @msg = CONCAT('[PermissionError] Staff #', p_ActorAccountID, ' lacks CANCEL_ORDER permission required to cancel orders.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
      END IF;
      IF p_CancelReason IS NULL OR TRIM(p_CancelReason) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C7_Cancel] Staff cancel requires a non-empty CancelReason.';
      END IF;
      UPDATE `ORDER` SET Status = 'CANCELLED', CancelledBy = p_ActorAccountID, CancelledByType = 'STAFF',
        CancelledAt = NOW(), CancelReason = p_CancelReason, DriverID = NULL
      WHERE OrderID = p_OrderID;
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[LifecycleError] Actor cannot cancel this order.';
    END IF;
    IF v_pay = 'BALANCE' THEN
      SELECT IFNULL(MAX(TxnID), 0) + 1 INTO v_txn_id FROM TRANSACTION;
      INSERT INTO TRANSACTION (TxnID, TxnType, Amount, CreatedAt, AccountID, OrderID, SeqNo)
      VALUES (v_txn_id, 'REFUND', v_total, NOW(), v_cust, p_OrderID, NULL);
    END IF;

  ELSEIF p_ActionType = 'RATE_ORDER' THEN
    IF v_status <> 'COMPLETED' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C9_Rating] Can only rate COMPLETED orders.';
    END IF;
    IF p_RatingStars IS NULL OR p_RatingStars < 1 OR p_RatingStars > 5 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C9_Rating] RatingStars must be between 1 and 5.';
    END IF;
    IF (SELECT RatingStars FROM `ORDER` WHERE OrderID = p_OrderID) IS NOT NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C9_Rating] Order already rated.';
    END IF;
    UPDATE `ORDER` SET RatingStars = p_RatingStars, RatingComment = p_RatingComment WHERE OrderID = p_OrderID;

  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[LifecycleError] Unknown ActionType.';
  END IF;

  COMMIT;
END $$

DROP PROCEDURE IF EXISTS sp_Order_Delete $$
CREATE PROCEDURE sp_Order_Delete(
  IN p_OrderID INT,
  IN p_RequestingAccountID INT
)
BEGIN
  DECLARE v_status VARCHAR(20);
  DECLARE v_driver INT;
  DECLARE v_wd INT;
  DECLARE v_txn INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT Status, DriverID, WithdrawCount INTO v_status, v_driver, v_wd
  FROM `ORDER` WHERE OrderID = p_OrderID FOR UPDATE;
  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[DeleteBlocked] Order not found.';
  END IF;
  IF v_status NOT IN ('IDLE', 'ASSIGNING') OR v_driver IS NOT NULL OR v_wd <> 0 THEN
    SET @msg = CONCAT('[DeleteBlocked] Order #', p_OrderID, ' has status ', v_status,
      '. Historical/active orders cannot be deleted; use CANCEL_ORDER for active bookings.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
  END IF;

  SELECT COUNT(*) INTO v_txn FROM TRANSACTION WHERE OrderID = p_OrderID AND TxnType <> 'PAYMENT';
  IF v_txn > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[DeleteBlocked] Order has non-draft financial history.';
  END IF;

  DELETE FROM TRANSACTION WHERE OrderID = p_OrderID AND TxnType = 'PAYMENT';
  DELETE FROM `ORDER` WHERE OrderID = p_OrderID; -- cascades path/items/requests/photos

  COMMIT;
END $$

DELIMITER ;
SELECT 'TRACK_A programmability loaded' AS notice;
