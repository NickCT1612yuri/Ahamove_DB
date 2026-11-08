-- =============================================================================
-- 01_schema.sql — Full DDL (PK / FK / CHECK / indexes) — Phase 1 schema freeze
-- Source: A1 report §6 mapping (AccountID surrogates) + A2 planning tweaks
-- Assumes database ahamove_a2 already exists; reset_demo creates it.
-- =============================================================================

USE ahamove_a2;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Drop in reverse dependency order (safe re-run)
DROP TABLE IF EXISTS PROOF_PHOTO;
DROP TABLE IF EXISTS ORDER_ITEM;
DROP TABLE IF EXISTS ORDER_REQUEST;
DROP TABLE IF EXISTS TRANSACTION;
DROP TABLE IF EXISTS PATH_POINT;
DROP TABLE IF EXISTS `ORDER`;
DROP TABLE IF EXISTS OPERATION;
DROP TABLE IF EXISTS SERVICE_REQUEST;
DROP TABLE IF EXISTS SERVICE;
DROP TABLE IF EXISTS VEHICLE_DOC;
DROP TABLE IF EXISTS VEHICLE;
DROP TABLE IF EXISTS ROLE_PERMISSION;
DROP TABLE IF EXISTS PARTNER_ROLE;
DROP TABLE IF EXISTS DRIVER;
DROP TABLE IF EXISTS STAFF_PERMISSION;
DROP TABLE IF EXISTS STAFF;
DROP TABLE IF EXISTS PARTNER;
DROP TABLE IF EXISTS CUSTOMER;
DROP TABLE IF EXISTS ACCOUNT;
DROP TABLE IF EXISTS OWNER;
DROP TABLE IF EXISTS PROMOTION;
DROP TABLE IF EXISTS SPECIAL_REQUEST;
DROP TABLE IF EXISTS CITY;

-- =============================================================================
-- Tier 1 — Independent lookups & roots
-- =============================================================================

CREATE TABLE CITY (
  CityID   CHAR(3)      NOT NULL,
  CityName VARCHAR(100) NOT NULL,
  PRIMARY KEY (CityID),
  UNIQUE KEY uk_city_name (CityName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE SPECIAL_REQUEST (
  RequestCode VARCHAR(30)  NOT NULL,
  ReqName     VARCHAR(100) NOT NULL,
  RequestType VARCHAR(20)  NOT NULL,
  PRIMARY KEY (RequestCode),
  CONSTRAINT chk_special_request_type
    CHECK (RequestType IN ('BOOLEAN', 'PER_UNIT'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PROMOTION (
  PromoCode     VARCHAR(30)    NOT NULL,
  DiscountType  VARCHAR(20)    NOT NULL,
  DiscountValue DECIMAL(12,2)  NOT NULL,
  MaxDiscount   BIGINT         NOT NULL,
  FundedBy      VARCHAR(30)    NOT NULL,
  ValidFrom     DATETIME       NOT NULL,
  ValidTo       DATETIME       NOT NULL,
  PRIMARY KEY (PromoCode),
  CONSTRAINT chk_promo_discount_type
    CHECK (DiscountType IN ('FIXED', 'PERCENTAGE')),
  CONSTRAINT chk_promo_percentage_cap
    CHECK (DiscountType = 'FIXED' OR DiscountValue <= 100),
  CONSTRAINT chk_promo_values
    CHECK (DiscountValue >= 0 AND MaxDiscount >= 0),
  CONSTRAINT chk_promo_window
    CHECK (ValidFrom < ValidTo),
  CONSTRAINT chk_promo_funded_by
    CHECK (FundedBy IN ('AHAMOVE', 'SELLER'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE OWNER (
  OwnerID   INT         NOT NULL,
  OwnerType VARCHAR(20) NOT NULL,
  PRIMARY KEY (OwnerID),
  CONSTRAINT chk_owner_type
    CHECK (OwnerType IN ('DRIVER', 'PARTNER'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ACCOUNT (
  AccountID     INT          NOT NULL,
  PhoneNumber   VARCHAR(20)  NOT NULL,
  Email         VARCHAR(120) NOT NULL,
  Name          VARCHAR(100) NOT NULL,
  AccountStatus VARCHAR(20)  NOT NULL,
  AccountType   VARCHAR(20)  NOT NULL,
  PRIMARY KEY (AccountID),
  UNIQUE KEY uk_account_phone (PhoneNumber),
  UNIQUE KEY uk_account_email (Email),
  CONSTRAINT chk_account_status
    CHECK (AccountStatus IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
  CONSTRAINT chk_account_type
    CHECK (AccountType IN ('CUSTOMER', 'DRIVER', 'STAFF'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- Tier 2 — Account subclasses & partner roles
-- =============================================================================

CREATE TABLE STAFF (
  AccountID INT          NOT NULL,
  Position  VARCHAR(100) NOT NULL,
  PRIMARY KEY (AccountID),
  CONSTRAINT fk_staff_account
    FOREIGN KEY (AccountID) REFERENCES ACCOUNT (AccountID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE STAFF_PERMISSION (
  StaffID    INT         NOT NULL,
  Permission VARCHAR(40) NOT NULL,
  PRIMARY KEY (StaffID, Permission),
  CONSTRAINT fk_staff_perm_staff
    FOREIGN KEY (StaffID) REFERENCES STAFF (AccountID)
    ON DELETE CASCADE,
  CONSTRAINT chk_staff_permission
    CHECK (Permission IN (
      'VERIFY_DRIVER',
      'CANCEL_ORDER',
      'SUPERVISE_ORDER',
      'MANAGE_CATALOGUE',
      'MANAGE_PROMOTION'
    ))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CUSTOMER (
  AccountID   INT    NOT NULL,
  Balance     BIGINT NOT NULL DEFAULT 0,
  CreditLimit BIGINT NOT NULL DEFAULT 0,
  ParentID    INT    NULL,
  PartnerID   INT    NULL,
  RoleName    VARCHAR(50) NULL,
  PRIMARY KEY (AccountID),
  CONSTRAINT fk_customer_account
    FOREIGN KEY (AccountID) REFERENCES ACCOUNT (AccountID),
  CONSTRAINT fk_customer_parent
    FOREIGN KEY (ParentID) REFERENCES CUSTOMER (AccountID),
  CONSTRAINT chk_customer_credit
    CHECK (CreditLimit >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PARTNER (
  PartnerID     INT           NOT NULL,
  APIKey        VARCHAR(64)   NOT NULL,
  LegalName     VARCHAR(200)  NOT NULL,
  WebhookURL    VARCHAR(500)  NOT NULL,
  IntegrationID INT           NOT NULL,
  OwnerID       INT           NULL,
  PRIMARY KEY (PartnerID),
  UNIQUE KEY uk_partner_apikey (APIKey),
  UNIQUE KEY uk_partner_integration (IntegrationID),
  UNIQUE KEY uk_partner_owner (OwnerID),
  CONSTRAINT fk_partner_integration
    FOREIGN KEY (IntegrationID) REFERENCES CUSTOMER (AccountID),
  CONSTRAINT fk_partner_owner
    FOREIGN KEY (OwnerID) REFERENCES OWNER (OwnerID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Close CUSTOMER → PARTNER cycle (PartnerID / role)
ALTER TABLE CUSTOMER
  ADD CONSTRAINT fk_customer_partner
    FOREIGN KEY (PartnerID) REFERENCES PARTNER (PartnerID);

CREATE TABLE PARTNER_ROLE (
  PartnerID INT         NOT NULL,
  RoleName  VARCHAR(50) NOT NULL,
  PRIMARY KEY (PartnerID, RoleName),
  CONSTRAINT fk_partner_role_partner
    FOREIGN KEY (PartnerID) REFERENCES PARTNER (PartnerID)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE CUSTOMER
  ADD CONSTRAINT fk_customer_partner_role
    FOREIGN KEY (PartnerID, RoleName)
    REFERENCES PARTNER_ROLE (PartnerID, RoleName);

CREATE TABLE ROLE_PERMISSION (
  PartnerID  INT         NOT NULL,
  RoleName   VARCHAR(50) NOT NULL,
  Permission VARCHAR(40) NOT NULL,
  PRIMARY KEY (PartnerID, RoleName, Permission),
  CONSTRAINT fk_role_perm_role
    FOREIGN KEY (PartnerID, RoleName)
    REFERENCES PARTNER_ROLE (PartnerID, RoleName)
    ON DELETE CASCADE,
  CONSTRAINT chk_role_permission
    CHECK (Permission IN (
      'PLACE_ORDER',
      'CANCEL_ORDER',
      'VIEW_ORDER',
      'MANAGE_CHILD',
      'MANAGE_WEBHOOK',
      'MANAGE_ROLE'
    ))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE DRIVER (
  AccountID   INT            NOT NULL,
  NationalID  VARCHAR(30)    NOT NULL,
  WorkStatus  VARCHAR(20)    NOT NULL,
  Lat         DECIMAL(10,7)  NULL,
  Lng         DECIMAL(10,7)  NULL,
  UpdatedAt   DATETIME       NULL,
  VerifiedBy  INT            NULL,
  VerifiedAt  DATETIME       NULL,
  OwnerID     INT            NULL,
  Balance     BIGINT         NOT NULL DEFAULT 0,
  CreditLimit BIGINT         NOT NULL DEFAULT 500000,
  AvgRating   DECIMAL(3,2)   NOT NULL DEFAULT 0.00,
  PRIMARY KEY (AccountID),
  UNIQUE KEY uk_driver_national (NationalID),
  UNIQUE KEY uk_driver_owner (OwnerID),
  CONSTRAINT fk_driver_account
    FOREIGN KEY (AccountID) REFERENCES ACCOUNT (AccountID),
  CONSTRAINT fk_driver_verified_by
    FOREIGN KEY (VerifiedBy) REFERENCES STAFF (AccountID),
  CONSTRAINT fk_driver_owner
    FOREIGN KEY (OwnerID) REFERENCES OWNER (OwnerID),
  CONSTRAINT chk_driver_work_status
    CHECK (WorkStatus IN ('ONLINE', 'OFFLINE', 'BUSY')),
  CONSTRAINT chk_driver_credit
    CHECK (CreditLimit = 500000),
  CONSTRAINT chk_driver_avg_rating
    CHECK (AvgRating >= 0 AND AvgRating <= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- Tier 3 — Fleet & service catalog
-- =============================================================================

CREATE TABLE VEHICLE (
  PlateNumber   VARCHAR(20)    NOT NULL,
  ChassisNo     VARCHAR(40)    NOT NULL,
  VehicleType   VARCHAR(30)    NOT NULL,
  LoadCapacity  DECIMAL(10,2)  NOT NULL,
  OwnerID       INT            NOT NULL,
  PRIMARY KEY (PlateNumber),
  UNIQUE KEY uk_vehicle_chassis (ChassisNo),
  CONSTRAINT fk_vehicle_owner
    FOREIGN KEY (OwnerID) REFERENCES OWNER (OwnerID),
  CONSTRAINT chk_vehicle_type
    CHECK (VehicleType IN ('BIKE', 'VAN', 'TRUCK')),
  CONSTRAINT chk_vehicle_capacity
    CHECK (LoadCapacity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE VEHICLE_DOC (
  PlateNumber VARCHAR(20)  NOT NULL,
  DocType     VARCHAR(30)  NOT NULL,
  DocNumber   VARCHAR(60)  NOT NULL,
  IssueDate   DATE         NOT NULL,
  ExpiryDate  DATE         NOT NULL,
  AlertLevel  VARCHAR(15)  NULL,
  PRIMARY KEY (PlateNumber, DocType),
  CONSTRAINT fk_vehicle_doc_vehicle
    FOREIGN KEY (PlateNumber) REFERENCES VEHICLE (PlateNumber)
    ON DELETE CASCADE,
  CONSTRAINT chk_vehicle_doc_dates
    CHECK (IssueDate < ExpiryDate),
  CONSTRAINT chk_vehicle_doc_alert
    CHECK (AlertLevel IS NULL OR AlertLevel IN ('OK', 'REMINDER', 'ALARM', 'URGENT'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE SERVICE (
  CityID              CHAR(3)        NOT NULL,
  GroupCode           VARCHAR(20)    NOT NULL,
  SvcName             VARCHAR(100)   NOT NULL,
  MaxCOD              BIGINT         NOT NULL,
  MaxStops            INT            NOT NULL,
  BaseFee             BIGINT         NOT NULL,
  PerKmFee            BIGINT         NOT NULL,
  StopFee             BIGINT         NOT NULL,
  RequiredVehicleType VARCHAR(30)    NOT NULL,
  CommissionRate      DECIMAL(5,2)   NOT NULL,
  PRIMARY KEY (CityID, GroupCode),
  CONSTRAINT fk_service_city
    FOREIGN KEY (CityID) REFERENCES CITY (CityID),
  CONSTRAINT chk_service_fees
    CHECK (MaxCOD >= 0 AND MaxStops >= 1
       AND BaseFee >= 0 AND PerKmFee >= 0 AND StopFee >= 0),
  CONSTRAINT chk_service_vehicle
    CHECK (RequiredVehicleType IN ('BIKE', 'VAN', 'TRUCK')),
  CONSTRAINT chk_service_commission
    CHECK (CommissionRate >= 0 AND CommissionRate <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE SERVICE_REQUEST (
  CityID      CHAR(3)      NOT NULL,
  GroupCode   VARCHAR(20)  NOT NULL,
  RequestCode VARCHAR(30)  NOT NULL,
  Price       BIGINT       NOT NULL,
  MaxInput    INT          NOT NULL,
  PRIMARY KEY (CityID, GroupCode, RequestCode),
  CONSTRAINT fk_svc_req_service
    FOREIGN KEY (CityID, GroupCode) REFERENCES SERVICE (CityID, GroupCode)
    ON DELETE CASCADE,
  CONSTRAINT fk_svc_req_special
    FOREIGN KEY (RequestCode) REFERENCES SPECIAL_REQUEST (RequestCode),
  CONSTRAINT chk_svc_req_price
    CHECK (Price >= 0 AND MaxInput >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE OPERATION (
  DriverID    INT         NOT NULL,
  CityID      CHAR(3)     NOT NULL,
  GroupCode   VARCHAR(20) NOT NULL,
  PlateNumber VARCHAR(20) NOT NULL,
  ActivatedAt DATETIME    NOT NULL,
  OpStatus    VARCHAR(20) NOT NULL,
  PRIMARY KEY (DriverID, CityID, GroupCode),
  CONSTRAINT fk_operation_driver
    FOREIGN KEY (DriverID) REFERENCES DRIVER (AccountID),
  CONSTRAINT fk_operation_service
    FOREIGN KEY (CityID, GroupCode) REFERENCES SERVICE (CityID, GroupCode),
  CONSTRAINT fk_operation_vehicle
    FOREIGN KEY (PlateNumber) REFERENCES VEHICLE (PlateNumber),
  CONSTRAINT chk_operation_status
    CHECK (OpStatus IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- Tier 4 — Order graph & wallet ledger
-- =============================================================================

CREATE TABLE `ORDER` (
  OrderID         INT            NOT NULL,
  Status          VARCHAR(20)    NOT NULL,
  CreatedAt       DATETIME       NOT NULL,
  PaymentMethod   VARCHAR(30)    NOT NULL,
  Distance        DECIMAL(10,2)  NOT NULL,
  Weight          DECIMAL(10,2)  NOT NULL,
  DistanceFee     BIGINT         NOT NULL,
  StopFee         BIGINT         NOT NULL,
  RequestFee      BIGINT         NOT NULL DEFAULT 0,
  Discount        BIGINT         NOT NULL DEFAULT 0,
  TotalFee        BIGINT         NOT NULL DEFAULT 0,
  CustomerID      INT            NOT NULL,
  CityID          CHAR(3)        NOT NULL,
  GroupCode       VARCHAR(20)    NOT NULL,
  DriverID        INT            NULL,
  PromoCode       VARCHAR(30)    NULL,
  AcceptedAt      DATETIME       NULL,
  RatingStars     INT            NULL,
  RatingComment   VARCHAR(500)   NULL,
  CancelledBy     INT            NULL,
  CancelledAt     DATETIME       NULL,
  CancelReason    VARCHAR(255)   NULL,
  WithdrawCount   INT            NOT NULL DEFAULT 0,
  CancelledByType VARCHAR(20)    NULL,
  ScheduledAt     DATETIME       NULL,
  StartedAt       DATETIME       NULL,
  CompletedAt     DATETIME       NULL,
  PRIMARY KEY (OrderID),
  CONSTRAINT fk_order_customer
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER (AccountID),
  CONSTRAINT fk_order_service
    FOREIGN KEY (CityID, GroupCode) REFERENCES SERVICE (CityID, GroupCode),
  CONSTRAINT fk_order_driver
    FOREIGN KEY (DriverID) REFERENCES DRIVER (AccountID),
  CONSTRAINT fk_order_promo
    FOREIGN KEY (PromoCode) REFERENCES PROMOTION (PromoCode),
  CONSTRAINT fk_order_cancelled_by
    FOREIGN KEY (CancelledBy) REFERENCES ACCOUNT (AccountID),
  CONSTRAINT chk_order_status
    CHECK (Status IN (
      'IDLE', 'ASSIGNING', 'ACCEPTED', 'IN_PROCESS', 'COMPLETED', 'CANCELLED'
    )),
  CONSTRAINT chk_order_payment
    CHECK (PaymentMethod IN ('CASH', 'CASH_BY_RECIPIENT', 'BALANCE')),
  CONSTRAINT chk_order_fees
    CHECK (
      Distance > 0 AND Weight > 0
      AND DistanceFee >= 0 AND StopFee >= 0
      AND RequestFee >= 0 AND Discount >= 0 AND TotalFee >= 0
    ),
  CONSTRAINT chk_order_withdraw
    CHECK (WithdrawCount BETWEEN 0 AND 5),
  CONSTRAINT chk_order_rating
    CHECK (RatingStars IS NULL OR RatingStars BETWEEN 1 AND 5),
  CONSTRAINT chk_order_cancel_type
    CHECK (
      CancelledByType IS NULL
      OR CancelledByType IN ('CUSTOMER', 'STAFF', 'SYSTEM')
    ),
  KEY idx_order_status_created (Status, CreatedAt),
  KEY idx_order_driver_status (DriverID, Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PATH_POINT (
  OrderID        INT            NOT NULL,
  SeqNo          INT            NOT NULL,
  TrackingNumber VARCHAR(40)    NULL,
  Address        VARCHAR(255)   NOT NULL,
  Lat            DECIMAL(10,7)  NOT NULL,
  Lng            DECIMAL(10,7)  NOT NULL,
  ContactName    VARCHAR(100)   NOT NULL,
  ContactMobile  VARCHAR(20)    NOT NULL,
  COD            BIGINT         NOT NULL DEFAULT 0,
  PointStatus    VARCHAR(20)    NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (OrderID, SeqNo),
  UNIQUE KEY uk_path_tracking (TrackingNumber),
  CONSTRAINT fk_path_order
    FOREIGN KEY (OrderID) REFERENCES `ORDER` (OrderID)
    ON DELETE CASCADE,
  CONSTRAINT chk_path_seq
    CHECK (SeqNo >= 0),
  CONSTRAINT chk_path_cod
    CHECK (COD >= 0 AND (SeqNo > 0 OR COD = 0)),
  CONSTRAINT chk_path_status
    CHECK (PointStatus IN ('PENDING', 'SUCCESS', 'FAILED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PROOF_PHOTO (
  OrderID  INT          NOT NULL,
  SeqNo    INT          NOT NULL,
  PhotoNo  INT          NOT NULL,
  PhotoURL VARCHAR(500) NOT NULL,
  FileSize INT          NOT NULL,
  PRIMARY KEY (OrderID, SeqNo, PhotoNo),
  CONSTRAINT fk_proof_path
    FOREIGN KEY (OrderID, SeqNo) REFERENCES PATH_POINT (OrderID, SeqNo)
    ON DELETE CASCADE,
  CONSTRAINT chk_proof_size
    CHECK (FileSize > 0 AND FileSize <= 10485760),
  CONSTRAINT chk_proof_no
    CHECK (PhotoNo >= 1 AND SeqNo >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ORDER_REQUEST (
  OrderID     INT         NOT NULL,
  RequestCode VARCHAR(30) NOT NULL,
  Quantity    INT         NOT NULL,
  PRIMARY KEY (OrderID, RequestCode),
  CONSTRAINT fk_order_req_order
    FOREIGN KEY (OrderID) REFERENCES `ORDER` (OrderID)
    ON DELETE CASCADE,
  CONSTRAINT fk_order_req_special
    FOREIGN KEY (RequestCode) REFERENCES SPECIAL_REQUEST (RequestCode),
  CONSTRAINT chk_order_req_qty
    CHECK (Quantity >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ORDER_ITEM (
  OrderID  INT            NOT NULL,
  ItemID   INT            NOT NULL,
  Name     VARCHAR(200)   NOT NULL,
  Price    BIGINT         NOT NULL,
  Quantity INT            NOT NULL,
  SeqNo    INT            NOT NULL,
  PRIMARY KEY (OrderID, ItemID),
  CONSTRAINT fk_order_item_order
    FOREIGN KEY (OrderID) REFERENCES `ORDER` (OrderID)
    ON DELETE CASCADE,
  CONSTRAINT fk_order_item_path
    FOREIGN KEY (OrderID, SeqNo) REFERENCES PATH_POINT (OrderID, SeqNo)
    ON DELETE CASCADE,
  CONSTRAINT chk_order_item_vals
    CHECK (Price >= 0 AND Quantity >= 1 AND SeqNo >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE TRANSACTION (
  TxnID     INT          NOT NULL,
  TxnType   VARCHAR(30)  NOT NULL,
  Amount    BIGINT       NOT NULL,
  CreatedAt DATETIME     NOT NULL,
  AccountID INT          NOT NULL,
  OrderID   INT          NULL,
  SeqNo     INT          NULL,
  PRIMARY KEY (TxnID),
  CONSTRAINT fk_txn_account
    FOREIGN KEY (AccountID) REFERENCES ACCOUNT (AccountID),
  CONSTRAINT fk_txn_order
    FOREIGN KEY (OrderID) REFERENCES `ORDER` (OrderID),
  CONSTRAINT fk_txn_path
    FOREIGN KEY (OrderID, SeqNo) REFERENCES PATH_POINT (OrderID, SeqNo),
  CONSTRAINT chk_txn_amount_nonzero
    CHECK (Amount <> 0),
  CONSTRAINT chk_txn_type
    CHECK (TxnType IN (
      'TOPUP', 'PAYMENT', 'REFUND', 'COMMISSION', 'EARNING', 'COD'
    )),
  KEY idx_txn_account_created (AccountID, CreatedAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

SELECT '01_schema.sql loaded — 23 tables ready for seed / programmability.' AS notice;
