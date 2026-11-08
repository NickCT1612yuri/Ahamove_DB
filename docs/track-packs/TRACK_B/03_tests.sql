USE ahamove_a2;

-- Before
SELECT OrderID, RequestFee, TotalFee FROM `ORDER` WHERE OrderID = 102;
SELECT AccountID, Balance FROM CUSTOMER WHERE AccountID = 3;

-- Fire Attribute B then A (LOADING on SGN-BIKE = 15000 * 2)
-- If TIP already exists on 102, delete first or use a clean ASSIGNING order.
INSERT INTO ORDER_REQUEST (OrderID, RequestCode, Quantity) VALUES (102, 'LOADING', 2);

-- After
SELECT OrderID, RequestFee, TotalFee FROM `ORDER` WHERE OrderID = 102;
SELECT AccountID, Balance FROM CUSTOMER WHERE AccountID = 3;
