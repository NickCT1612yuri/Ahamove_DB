-- TRACK C: C8 eligibility triggers + fn_EvaluateFleetCompliance
USE ahamove_a2;
DELIMITER $$

DROP PROCEDURE IF EXISTS _assert_driver_eligibility $$
CREATE PROCEDURE _assert_driver_eligibility(
  IN p_DriverID INT,
  IN p_OrderID INT,
  IN p_Weight DECIMAL(10,2),
  IN p_CityID CHAR(3),
  IN p_GroupCode VARCHAR(20)
)
main: BEGIN
  DECLARE v_status VARCHAR(20);
  DECLARE v_type VARCHAR(20);
  DECLARE v_work VARCHAR(20);
  DECLARE v_verified INT;
  DECLARE v_busy INT;
  DECLARE v_op INT;
  DECLARE v_plate VARCHAR(20);
  DECLARE v_vtype VARCHAR(30);
  DECLARE v_cap DECIMAL(10,2);
  DECLARE v_need VARCHAR(30);
  DECLARE v_expired INT;
  DECLARE v_msg VARCHAR(255);

  IF p_DriverID IS NULL THEN
    LEAVE main;
  END IF;

  SELECT a.AccountStatus, a.AccountType, d.WorkStatus,
         CASE WHEN d.VerifiedBy IS NULL THEN 0 ELSE 1 END
    INTO v_status, v_type, v_work, v_verified
  FROM ACCOUNT a
  JOIN DRIVER d ON d.AccountID = a.AccountID
  WHERE a.AccountID = p_DriverID;

  IF v_type IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '[C8_Eligibility] Driver account not found.';
  END IF;
  IF v_status <> 'ACTIVE' THEN
    SET v_msg = CONCAT('[C8_Eligibility] Driver #', p_DriverID, ' account is not ACTIVE.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF v_verified = 0 THEN
    SET v_msg = CONCAT('[C8_Eligibility] Driver #', p_DriverID, ' is not verified.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF v_work <> 'ONLINE' AND v_work <> 'BUSY' THEN
    -- allow BUSY only if this same order already assigned; else must be ONLINE
    SET v_msg = CONCAT('[C8_Eligibility] Driver #', p_DriverID, ' WorkStatus must be ONLINE to accept.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SELECT COUNT(*) INTO v_busy
  FROM `ORDER`
  WHERE DriverID = p_DriverID
    AND Status IN ('ACCEPTED', 'IN_PROCESS')
    AND (p_OrderID IS NULL OR OrderID <> p_OrderID);
  IF v_busy > 0 THEN
    SET v_msg = CONCAT('[C8_Eligibility] Driver #', p_DriverID, ' already has an active order.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SELECT COUNT(*), MAX(PlateNumber) INTO v_op, v_plate
  FROM OPERATION
  WHERE DriverID = p_DriverID AND CityID = p_CityID AND GroupCode = p_GroupCode AND OpStatus = 'ACTIVE';
  IF IFNULL(v_op, 0) = 0 THEN
    SET v_msg = CONCAT('[C8_Eligibility] Driver #', p_DriverID, ' has no ACTIVE OPERATION for ', p_CityID, '-', p_GroupCode, '.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SELECT RequiredVehicleType INTO v_need FROM SERVICE WHERE CityID = p_CityID AND GroupCode = p_GroupCode;
  SELECT VehicleType, LoadCapacity INTO v_vtype, v_cap FROM VEHICLE WHERE PlateNumber = v_plate;
  IF v_vtype <> v_need THEN
    SET v_msg = CONCAT('[C8_Eligibility] Vehicle type ', v_vtype, ' does not match required ', v_need, '.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF v_cap < p_Weight THEN
    SET v_msg = CONCAT('[C8_Eligibility] Vehicle capacity ', v_cap, ' < order weight ', p_Weight, '.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SELECT COUNT(*) INTO v_expired
  FROM VEHICLE_DOC
  WHERE PlateNumber = v_plate AND ExpiryDate < CURDATE();
  IF v_expired > 0 THEN
    SET v_msg = CONCAT('[C8_Eligibility] Vehicle ', v_plate, ' has an expired document.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
END main $$

DROP TRIGGER IF EXISTS trg_Order_BeforeUpdate_DriverEligibility $$
CREATE TRIGGER trg_Order_BeforeUpdate_DriverEligibility
BEFORE UPDATE ON `ORDER`
FOR EACH ROW
BEGIN
  IF NEW.DriverID IS NOT NULL
     AND (NEW.Status = 'ACCEPTED' OR (OLD.DriverID <=> NEW.DriverID) = 0 OR NEW.Weight <> OLD.Weight
          OR NEW.CityID <> OLD.CityID OR NEW.GroupCode <> OLD.GroupCode) THEN
    IF NEW.Status IN ('ACCEPTED', 'IN_PROCESS') OR (NEW.DriverID IS NOT NULL AND NEW.Status = 'ACCEPTED') THEN
      CALL _assert_driver_eligibility(NEW.DriverID, NEW.OrderID, NEW.Weight, NEW.CityID, NEW.GroupCode);
    END IF;
  END IF;
  IF NEW.Status = 'ACCEPTED' AND NEW.DriverID IS NOT NULL THEN
    CALL _assert_driver_eligibility(NEW.DriverID, NEW.OrderID, NEW.Weight, NEW.CityID, NEW.GroupCode);
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_Order_BeforeInsert_DriverEligibility $$
CREATE TRIGGER trg_Order_BeforeInsert_DriverEligibility
BEFORE INSERT ON `ORDER`
FOR EACH ROW
BEGIN
  IF NEW.DriverID IS NOT NULL THEN
    CALL _assert_driver_eligibility(NEW.DriverID, NEW.OrderID, NEW.Weight, NEW.CityID, NEW.GroupCode);
  END IF;
END $$

DROP FUNCTION IF EXISTS fn_EvaluateFleetCompliance $$
CREATE FUNCTION fn_EvaluateFleetCompliance(
  p_OwnerID INT,
  p_ReferenceDate DATE
) RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_done INT DEFAULT 0;
  DECLARE v_plate VARCHAR(20);
  DECLARE v_doc VARCHAR(30);
  DECLARE v_exp DATE;
  DECLARE v_days INT;
  DECLARE v_score INT DEFAULT 100;
  DECLARE v_urgent INT DEFAULT 0;
  DECLARE v_alarm INT DEFAULT 0;
  DECLARE v_remind INT DEFAULT 0;
  DECLARE v_ok INT DEFAULT 0;

  DECLARE cur CURSOR FOR
    SELECT v.PlateNumber, d.DocType, d.ExpiryDate
    FROM VEHICLE v
    JOIN VEHICLE_DOC d ON d.PlateNumber = v.PlateNumber
    WHERE v.OwnerID = p_OwnerID;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  IF p_OwnerID IS NULL OR p_ReferenceDate IS NULL THEN
    RETURN '[Fleet_Input] OwnerID and ReferenceDate are required.';
  END IF;
  SELECT COUNT(*) INTO v_exists FROM OWNER WHERE OwnerID = p_OwnerID;
  IF v_exists = 0 THEN
    RETURN CONCAT('[Fleet_Input] Owner #', p_OwnerID, ' does not exist.');
  END IF;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_plate, v_doc, v_exp;
    IF v_done = 1 THEN LEAVE read_loop; END IF;
    SET v_days = DATEDIFF(v_exp, p_ReferenceDate);
    IF v_days < 7 THEN
      SET v_urgent = v_urgent + 1;
      SET v_score = v_score - 25;
    ELSEIF v_days <= 14 THEN
      SET v_alarm = v_alarm + 1;
      SET v_score = v_score - 15;
    ELSEIF v_days <= 30 THEN
      SET v_remind = v_remind + 1;
      SET v_score = v_score - 5;
    ELSE
      SET v_ok = v_ok + 1;
    END IF;
  END LOOP;
  CLOSE cur;

  IF v_score < 0 THEN SET v_score = 0; END IF;

  RETURN CONCAT(
    'Owner ', p_OwnerID, ' score=', v_score,
    ' | OK=', v_ok, ' REMINDER=', v_remind, ' ALARM=', v_alarm, ' URGENT=', v_urgent,
    IF(v_urgent > 0, ' | DISPATCH=BLOCKED', ' | DISPATCH=OK')
  );
END $$

DELIMITER ;
SELECT 'TRACK_C programmability loaded' AS notice;
