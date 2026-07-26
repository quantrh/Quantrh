// ============================================================================
// DEMO PHAT HIEN KHACH HANG CUNG CAP THANH KHOAN DAO NO
// File 01 - Schema, constraint va index
// Neo4j 5.x, khong yeu cau APOC/GDS
// ============================================================================

CREATE CONSTRAINT dr_customer_id IF NOT EXISTS
FOR (n:DRCustomer)
REQUIRE n.customerId IS UNIQUE;

CREATE CONSTRAINT dr_account_id IF NOT EXISTS
FOR (n:DRAccount)
REQUIRE n.accountId IS UNIQUE;

CREATE CONSTRAINT dr_bank_code IF NOT EXISTS
FOR (n:DRBank)
REQUIRE n.bankCode IS UNIQUE;

CREATE CONSTRAINT dr_loan_id IF NOT EXISTS
FOR (n:DRLoan)
REQUIRE n.loanId IS UNIQUE;

CREATE CONSTRAINT dr_transfer_id IF NOT EXISTS
FOR (n:DRTransfer)
REQUIRE n.transferId IS UNIQUE;

CREATE CONSTRAINT dr_repayment_id IF NOT EXISTS
FOR (n:DRRepayment)
REQUIRE n.repaymentId IS UNIQUE;

CREATE CONSTRAINT dr_disbursement_id IF NOT EXISTS
FOR (n:DRDisbursement)
REQUIRE n.disbursementId IS UNIQUE;

CREATE CONSTRAINT dr_balance_snapshot_id IF NOT EXISTS
FOR (n:DRBalanceSnapshot)
REQUIRE n.snapshotId IS UNIQUE;

CREATE CONSTRAINT dr_detected_chain_id IF NOT EXISTS
FOR (n:DRDetectedChain)
REQUIRE n.chainId IS UNIQUE;

CREATE CONSTRAINT dr_alert_id IF NOT EXISTS
FOR (n:DRAlert)
REQUIRE n.alertId IS UNIQUE;

// Index phuc vu diem bat dau tu su kien thu no va cac cua so thoi gian.
CREATE INDEX dr_repayment_time IF NOT EXISTS
FOR (n:DRRepayment)
ON (n.eventTime);

CREATE INDEX dr_disbursement_time IF NOT EXISTS
FOR (n:DRDisbursement)
ON (n.eventTime);

CREATE INDEX dr_transfer_time IF NOT EXISTS
FOR (n:DRTransfer)
ON (n.eventTime);

CREATE INDEX dr_snapshot_time IF NOT EXISTS
FOR (n:DRBalanceSnapshot)
ON (n.asOf);

CREATE INDEX dr_chain_level IF NOT EXISTS
FOR (n:DRDetectedChain)
ON (n.chainLevel);

