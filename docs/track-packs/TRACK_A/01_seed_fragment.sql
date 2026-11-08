-- TRACK A seed: PROMOTION, ORDER, PATH_POINT, ORDER_ITEM, PROOF_PHOTO
USE ahamove_a2;
SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO PROMOTION (PromoCode, DiscountType, DiscountValue, MaxDiscount, FundedBy, ValidFrom, ValidTo) VALUES
('AHA50', 'FIXED', 5000, 5000, 'AHAMOVE', '2026-01-01 00:00:00', '2026-12-31 23:59:59'),
('PCT10', 'PERCENTAGE', 10, 20000, 'AHAMOVE', '2026-01-01 00:00:00', '2026-12-31 23:59:59'),
('SELL20', 'FIXED', 20000, 20000, 'SELLER', '2026-06-01 00:00:00', '2026-12-31 23:59:59'),
('EXP2025', 'FIXED', 10000, 10000, 'AHAMOVE', '2025-01-01 00:00:00', '2025-12-31 23:59:59'),
('NEWUSER', 'PERCENTAGE', 15, 15000, 'AHAMOVE', '2026-01-01 00:00:00', '2027-01-01 00:00:00')
ON DUPLICATE KEY UPDATE DiscountValue = VALUES(DiscountValue);

-- Orders 101–108 storyline (fees already snapshotted for demo)
INSERT INTO `ORDER` (
  OrderID, Status, CreatedAt, PaymentMethod, Distance, Weight,
  DistanceFee, StopFee, RequestFee, Discount, TotalFee,
  CustomerID, CityID, GroupCode, DriverID, PromoCode,
  AcceptedAt, RatingStars, RatingComment, CancelledBy, CancelledAt, CancelReason,
  WithdrawCount, CancelledByType, ScheduledAt, StartedAt, CompletedAt
) VALUES
(101, 'IDLE', '2026-11-01 08:00:00', 'CASH', 3.0, 2.0,
  30000, 0, 0, 0, 30000,
  1, 'SGN', 'BIKE', NULL, NULL,
  NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, '2026-11-10 18:00:00', NULL, NULL),
(102, 'ASSIGNING', '2026-10-15 09:00:00', 'BALANCE', 4.0, 5.0,
  35000, 0, 0, 0, 35000,
  3, 'SGN', 'BIKE', NULL, NULL,
  NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL),
(103, 'ACCEPTED', '2026-10-16 10:00:00', 'BALANCE', 5.0, 4.0,
  40000, 0, 0, 0, 48000,
  1, 'SGN', 'BIKE', 7, 'AHA50',
  '2026-10-16 10:30:00', NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL),
(104, 'IN_PROCESS', '2026-10-17 11:00:00', 'CASH', 6.0, 3.0,
  45000, 0, 0, 0, 45000,
  1, 'SGN', 'BIKE', 6, NULL,
  '2026-10-17 11:20:00', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-10-17 11:40:00', NULL),
(105, 'COMPLETED', '2026-10-18 09:00:00', 'BALANCE', 8.0, 5.0,
  55000, 0, 25000, 0, 80000,
  1, 'SGN', 'BIKE', 6, NULL,
  '2026-10-18 09:30:00', 5, 'Great', NULL, NULL, NULL, 0, NULL, NULL, '2026-10-18 10:00:00', '2026-10-20 18:00:00'),
(106, 'COMPLETED', '2026-10-19 09:00:00', 'BALANCE', 7.0, 4.0,
  50000, 0, 20000, 0, 90000,
  3, 'SGN', 'BIKE', 6, NULL,
  '2026-10-19 09:30:00', 4, 'OK', NULL, NULL, NULL, 0, NULL, NULL, '2026-10-19 10:00:00', '2026-10-21 18:00:00'),
(107, 'COMPLETED', '2026-10-20 09:00:00', 'CASH', 5.0, 2.0,
  40000, 0, 10000, 0, 50000,
  4, 'SGN', 'BIKE', 7, NULL,
  '2026-10-20 09:30:00', 5, 'Fast', NULL, NULL, NULL, 0, NULL, NULL, '2026-10-20 10:00:00', '2026-10-22 18:00:00'),
(108, 'CANCELLED', '2026-10-12 09:00:00', 'BALANCE', 4.0, 2.0,
  35000, 0, 0, 5000, 30000,
  2, 'SGN', 'BIKE', NULL, 'AHA50',
  NULL, NULL, NULL, 1, '2026-10-12 09:20:00', 'Changed mind', 0, 'CUSTOMER', NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE Status = VALUES(Status);

INSERT INTO PATH_POINT (OrderID, SeqNo, TrackingNumber, Address, Lat, Lng, ContactName, ContactMobile, COD, PointStatus) VALUES
(101, 0, NULL, '268 Ly Thuong Kiet Q10', 10.77, 106.66, 'Minh Nhat', '0901000001', 0, 'PENDING'),
(101, 1, 'TRK101', '01 Vo Van Ngan', 10.85, 106.77, 'The Nhan', '0909111222', 0, 'PENDING'),
(102, 0, NULL, 'Coffee House HQ', 10.78, 106.70, 'Coffee', '0901000003', 0, 'PENDING'),
(102, 1, 'TRK102', 'District 1 drop', 10.77, 106.70, 'Recv', '0909111000', 150000, 'PENDING'),
(103, 0, NULL, 'Pickup 103', 10.76, 106.68, 'Minh Nhat', '0901000001', 0, 'PENDING'),
(103, 1, 'TRK103', 'Drop 103', 10.80, 106.72, 'Recv103', '0909111001', 0, 'PENDING'),
(104, 0, NULL, 'Pickup 104', 10.76, 106.68, 'Minh Nhat', '0901000001', 0, 'SUCCESS'),
(104, 1, 'TRK104', 'Drop 104', 10.81, 106.73, 'Recv104', '0909111002', 0, 'PENDING'),
(105, 0, NULL, 'Pickup 105', 10.76, 106.68, 'Minh Nhat', '0901000001', 0, 'SUCCESS'),
(105, 1, 'TRK105', 'Drop 105', 10.82, 106.74, 'Recv105', '0909111003', 200000, 'SUCCESS'),
(106, 0, NULL, 'Pickup 106', 10.76, 106.68, 'Coffee', '0901000003', 0, 'SUCCESS'),
(106, 1, 'TRK106', 'Drop 106', 10.83, 106.75, 'Recv106', '0909111004', 0, 'SUCCESS'),
(107, 0, NULL, 'Pickup 107', 10.76, 106.68, 'Pharma', '0901000004', 0, 'SUCCESS'),
(107, 1, 'TRK107', 'Drop 107', 10.84, 106.76, 'Recv107', '0909111005', 50000, 'SUCCESS'),
(108, 0, NULL, 'Pickup 108', 10.76, 106.68, 'LowBal', '0901000002', 0, 'PENDING'),
(108, 1, 'TRK108', 'Drop 108', 10.79, 106.71, 'Recv108', '0909111006', 0, 'PENDING'),
(105, 2, 'TRK105B', 'Second drop 105', 10.825, 106.745, 'Recv105b', '0909111007', 0, 'SUCCESS'),
(106, 2, 'TRK106B', 'Second drop 106', 10.835, 106.755, 'Recv106b', '0909111008', 0, 'SUCCESS')
ON DUPLICATE KEY UPDATE Address = VALUES(Address);

INSERT INTO ORDER_ITEM (OrderID, ItemID, Name, Price, Quantity, SeqNo) VALUES
(105, 1, 'Documents', 0, 1, 1),
(105, 2, 'Sample box', 0, 1, 1),
(106, 1, 'Parcel A', 0, 1, 1),
(106, 2, 'Parcel B', 0, 2, 2),
(107, 1, 'Medicine pack', 0, 1, 1),
(104, 1, 'Goods', 0, 1, 1),
(103, 1, 'Bag', 0, 1, 1),
(102, 1, 'Coffee supplies', 0, 1, 1)
ON DUPLICATE KEY UPDATE Name = VALUES(Name);

INSERT INTO PROOF_PHOTO (OrderID, SeqNo, PhotoNo, PhotoURL, FileSize) VALUES
(105, 1, 1, 'https://cdn.example.com/105-1-1.jpg', 204800),
(105, 1, 2, 'https://cdn.example.com/105-1-2.jpg', 198000),
(105, 2, 1, 'https://cdn.example.com/105-2-1.jpg', 210000),
(106, 1, 1, 'https://cdn.example.com/106-1-1.jpg', 180000),
(106, 2, 1, 'https://cdn.example.com/106-2-1.jpg', 190000),
(107, 1, 1, 'https://cdn.example.com/107-1-1.jpg', 175000)
ON DUPLICATE KEY UPDATE PhotoURL = VALUES(PhotoURL);

SET FOREIGN_KEY_CHECKS = 1;
SELECT 'TRACK_A seed loaded' AS notice;
