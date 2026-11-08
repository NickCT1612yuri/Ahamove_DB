-- TRACK E: sp_Service_RevenueAndDriverKPI + fn_CalculateDriverNetSettlement
USE ahamove_a2;
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_Service_RevenueAndDriverKPI $$
CREATE PROCEDURE sp_Service_RevenueAndDriverKPI(
  IN p_CityID CHAR(3),
  IN p_StartDate DATE,
  IN p_EndDate DATE,
  IN p_MinCompletedOrders INT,
  IN p_MinGrossRevenue BIGINT
)
BEGIN
  IF p_StartDate IS NULL OR p_EndDate IS NULL OR p_StartDate > p_EndDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '[KPI_Input] StartDate and EndDate are required and StartDate must be <= EndDate.';
  END IF;

  SELECT
    s.CityID,
    c.CityName,
    s.GroupCode,
    s.SvcName,
    s.CommissionRate,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COALESCE(SUM(o.TotalFee), 0) AS GrossRevenue,
    ROUND(COALESCE(SUM(o.TotalFee * s.CommissionRate / 100), 0)) AS PlatformCommission,
    COALESCE(SUM(pp.COD), 0) AS TotalCODHandled,
    AVG(o.RatingStars) AS AvgServiceRating
  FROM SERVICE s
  JOIN CITY c ON c.CityID = s.CityID
  LEFT JOIN `ORDER` o
    ON o.CityID = s.CityID AND o.GroupCode = s.GroupCode
   AND o.Status = 'COMPLETED'
   AND DATE(o.CompletedAt) BETWEEN p_StartDate AND p_EndDate
  LEFT JOIN PATH_POINT pp
    ON pp.OrderID = o.OrderID AND pp.SeqNo > 0
  WHERE (p_CityID IS NULL OR s.CityID = p_CityID)
  GROUP BY s.CityID, c.CityName, s.GroupCode, s.SvcName, s.CommissionRate
  HAVING COUNT(DISTINCT o.OrderID) >= IFNULL(p_MinCompletedOrders, 0)
     AND COALESCE(SUM(o.TotalFee), 0) >= IFNULL(p_MinGrossRevenue, 0)
  ORDER BY GrossRevenue DESC;
END $$

DROP FUNCTION IF EXISTS fn_CalculateDriverNetSettlement $$
CREATE FUNCTION fn_CalculateDriverNetSettlement(
  p_DriverID INT,
  p_StartDate DATETIME,
  p_EndDate DATETIME
) RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_done INT DEFAULT 0;
  DECLARE v_order_id INT;
  DECLARE v_fee BIGINT;
  DECLARE v_rate DECIMAL(5,2);
  DECLARE v_pay VARCHAR(30);
  DECLARE v_comm BIGINT DEFAULT 0;
  DECLARE v_earn BIGINT DEFAULT 0;
  DECLARE v_gross BIGINT DEFAULT 0;
  DECLARE v_orders INT DEFAULT 0;
  DECLARE v_unremitted BIGINT DEFAULT 0;
  DECLARE v_cod BIGINT;
  DECLARE v_remitted BIGINT;

  DECLARE cur CURSOR FOR
    SELECT o.OrderID, o.TotalFee, s.CommissionRate, o.PaymentMethod
    FROM `ORDER` o
    JOIN SERVICE s ON s.CityID = o.CityID AND s.GroupCode = o.GroupCode
    WHERE o.DriverID = p_DriverID
      AND o.Status = 'COMPLETED'
      AND o.CompletedAt BETWEEN p_StartDate AND p_EndDate;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  IF p_DriverID IS NULL OR p_StartDate IS NULL OR p_EndDate IS NULL THEN
    RETURN '[Settlement_Input] DriverID, StartDate, EndDate are required.';
  END IF;
  IF p_StartDate > p_EndDate THEN
    RETURN '[Settlement_Input] StartDate must be <= EndDate.';
  END IF;

  SELECT COUNT(*) INTO v_exists FROM DRIVER WHERE AccountID = p_DriverID;
  IF v_exists = 0 THEN
    RETURN CONCAT('[Settlement_Input] Driver #', p_DriverID, ' does not exist.');
  END IF;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_order_id, v_fee, v_rate, v_pay;
    IF v_done = 1 THEN
      LEAVE read_loop;
    END IF;
    SET v_orders = v_orders + 1;
    SET v_gross = v_gross + v_fee;
    SET v_comm = v_comm + ROUND(v_fee * v_rate / 100);
    IF v_pay = 'BALANCE' THEN
      SET v_earn = v_earn + v_fee;
    END IF;

    SELECT COALESCE(SUM(pp.COD), 0) INTO v_cod
    FROM PATH_POINT pp
    WHERE pp.OrderID = v_order_id AND pp.SeqNo > 0 AND pp.PointStatus = 'SUCCESS';

    SELECT COALESCE(SUM(ABS(t.Amount)), 0) INTO v_remitted
    FROM TRANSACTION t
    WHERE t.AccountID = p_DriverID AND t.OrderID = v_order_id AND t.TxnType = 'COD';

    IF v_cod > v_remitted THEN
      SET v_unremitted = v_unremitted + (v_cod - v_remitted);
    END IF;
  END LOOP;
  CLOSE cur;

  RETURN CONCAT(
    'Orders: ', v_orders,
    ' | Gross: ', FORMAT(v_gross, 0),
    ' | Comm: -', FORMAT(v_comm, 0),
    ' | BalEarn: +', FORMAT(v_earn, 0),
    ' | UnremittedCOD: ', FORMAT(v_unremitted, 0),
    ' | NetPayout: ', FORMAT(v_earn - v_comm - v_unremitted, 0), ' VND'
  );
END $$

DELIMITER ;
SELECT 'TRACK_E programmability loaded' AS notice;
