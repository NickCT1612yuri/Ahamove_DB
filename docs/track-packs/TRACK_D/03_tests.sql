USE ahamove_a2;

CALL sp_Order_SearchDetailed('SGN', NULL, 'BALANCE', '090', '2026-10-01', '2026-11-30', 'FEE_DESC');
CALL sp_Order_SearchDetailed(NULL, 'COMPLETED', NULL, NULL, NULL, NULL, 'CREATED_DESC');
