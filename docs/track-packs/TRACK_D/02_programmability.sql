-- TRACK D: sp_Order_SearchDetailed
USE ahamove_a2;
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_Order_SearchDetailed $$
CREATE PROCEDURE sp_Order_SearchDetailed(
  IN p_CityID CHAR(3),
  IN p_Status VARCHAR(20),
  IN p_PaymentMethod VARCHAR(30),
  IN p_CustomerPhoneKeyword VARCHAR(20),
  IN p_FromDate DATE,
  IN p_ToDate DATE,
  IN p_SortBy VARCHAR(20)
)
BEGIN
  SELECT
    o.OrderID,
    o.Status,
    o.PaymentMethod,
    o.Distance,
    o.TotalFee,
    o.WithdrawCount,
    o.CreatedAt,
    o.CityID,
    o.GroupCode,
    s.SvcName,
    c.CityName,
    cust.AccountID AS CustomerID,
    ca.Name AS CustomerName,
    ca.PhoneNumber AS CustomerPhone,
    o.DriverID,
    da.Name AS DriverName
  FROM `ORDER` o
  JOIN CUSTOMER cust ON cust.AccountID = o.CustomerID
  JOIN ACCOUNT ca ON ca.AccountID = cust.AccountID
  JOIN SERVICE s ON s.CityID = o.CityID AND s.GroupCode = o.GroupCode
  JOIN CITY c ON c.CityID = o.CityID
  LEFT JOIN ACCOUNT da ON da.AccountID = o.DriverID
  WHERE (p_CityID IS NULL OR o.CityID = p_CityID)
    AND (p_Status IS NULL OR o.Status = p_Status)
    AND (p_PaymentMethod IS NULL OR o.PaymentMethod = p_PaymentMethod)
    AND (p_CustomerPhoneKeyword IS NULL OR ca.PhoneNumber LIKE CONCAT('%', p_CustomerPhoneKeyword, '%'))
    AND (p_FromDate IS NULL OR DATE(o.CreatedAt) >= p_FromDate)
    AND (p_ToDate IS NULL OR DATE(o.CreatedAt) <= p_ToDate)
  ORDER BY
    CASE WHEN IFNULL(p_SortBy, 'CREATED_DESC') = 'FEE_DESC' THEN o.TotalFee END DESC,
    CASE WHEN IFNULL(p_SortBy, 'CREATED_DESC') = 'DISTANCE_ASC' THEN o.Distance END ASC,
    CASE WHEN IFNULL(p_SortBy, 'CREATED_DESC') = 'CREATED_DESC' THEN o.CreatedAt END DESC,
    o.CreatedAt DESC;
END $$

DELIMITER ;
SELECT 'TRACK_D programmability loaded' AS notice;
