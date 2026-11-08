-- TRACK E seed: CITY, SERVICE, SERVICE_REQUEST (≥5 rows where possible)
-- Requires: SPECIAL_REQUEST from Track B before SERVICE_REQUEST (or FK checks off).
USE ahamove_a2;
SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO CITY (CityID, CityName) VALUES
('SGN', 'Ho Chi Minh City'),
('HAN', 'Ha Noi'),
('DAD', 'Da Nang'),
('CTO', 'Can Tho'),
('HPH', 'Hai Phong')
ON DUPLICATE KEY UPDATE CityName = VALUES(CityName);

INSERT INTO SERVICE (
  CityID, GroupCode, SvcName, MaxCOD, MaxStops, BaseFee, PerKmFee, StopFee,
  RequiredVehicleType, CommissionRate
) VALUES
('SGN', 'BIKE',    'SGN Bike',    2000000, 3, 15000, 5000, 8000,  'BIKE',  20.00),
('SGN', 'EXPRESS', 'SGN Express', 3000000, 2, 25000, 7000, 10000, 'BIKE',  18.00),
('SGN', 'VAN',     'SGN Van',     5000000, 5, 40000, 9000, 12000, 'VAN',   15.00),
('SGN', 'TRUCK',   'SGN Truck',   8000000, 5, 80000, 12000,15000,'TRUCK', 12.00),
('HAN', 'BIKE',    'HAN Bike',    2000000, 3, 14000, 4800, 7500,  'BIKE',  20.00),
('DAD', 'BIKE',    'DAD Bike',    1500000, 3, 13000, 4500, 7000,  'BIKE',  20.00)
ON DUPLICATE KEY UPDATE SvcName = VALUES(SvcName);

-- Prices used by Track B fee trigger / Track A create
INSERT INTO SERVICE_REQUEST (CityID, GroupCode, RequestCode, Price, MaxInput) VALUES
('SGN', 'BIKE', 'LOADING',     15000, 5),
('SGN', 'BIKE', 'WAITING',     10000, 3),
('SGN', 'BIKE', 'TIP',         5000,  10),
('SGN', 'BIKE', 'EXPRESS',     20000, 1),
('SGN', 'BIKE', 'RETURN_TRIP', 25000, 1),
('SGN', 'VAN',  'LOADING',     25000, 5),
('HAN', 'BIKE', 'LOADING',     14000, 5),
('DAD', 'BIKE', 'TIP',         5000,  10)
ON DUPLICATE KEY UPDATE Price = VALUES(Price);

SET FOREIGN_KEY_CHECKS = 1;
SELECT 'TRACK_E seed loaded' AS notice;
