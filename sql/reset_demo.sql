-- =============================================================================
-- reset_demo.sql — Recreate empty database ahamove_a2 only
--
-- SOURCE is a mysql *client* command and FAILS when piped with:
--   mysql … < sql/reset_demo.sql
--
-- Use reset_demo.sh from the A2/ repo root, OR run these four commands:
--
--   mysql -u root -p < sql/reset_demo.sql
--   mysql -u root -p ahamove_a2 < sql/01_schema.sql
--   mysql -u root -p ahamove_a2 < sql/02_seed.sql
--   mysql -u root -p ahamove_a2 < sql/03_programmability.sql
-- =============================================================================

DROP DATABASE IF EXISTS ahamove_a2;
-- utf8mb4_0900_ai_ci matches MySQL 8 default connection collation (avoids mix errors on CALL)
CREATE DATABASE ahamove_a2 CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

SELECT 'Database ahamove_a2 created. Now load 01_schema.sql, 02_seed.sql, 03_programmability.sql.' AS notice;
