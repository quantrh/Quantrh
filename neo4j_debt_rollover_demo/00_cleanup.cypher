// ============================================================================
// DEMO PHAT HIEN KHACH HANG CUNG CAP THANH KHOAN DAO NO
// File 00 - Xoa rieng bo du lieu demo
// Neo4j 5.x, khong yeu cau APOC/GDS
// ============================================================================

// Xoa node phai truoc, cac relationship lien quan se duoc DETACH DELETE.
MATCH (n)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
DETACH DELETE n;

// Cac constraint duoc giu lai de co the nap lai du lieu nhanh.
// Neu muon xoa ca constraint, chay them khoi lenh duoi:
//
// DROP CONSTRAINT dr_customer_id IF EXISTS;
// DROP CONSTRAINT dr_account_id IF EXISTS;
// DROP CONSTRAINT dr_bank_code IF EXISTS;
// DROP CONSTRAINT dr_loan_id IF EXISTS;
// DROP CONSTRAINT dr_transfer_id IF EXISTS;
// DROP CONSTRAINT dr_repayment_id IF EXISTS;
// DROP CONSTRAINT dr_disbursement_id IF EXISTS;
// DROP CONSTRAINT dr_balance_snapshot_id IF EXISTS;
// DROP CONSTRAINT dr_detected_chain_id IF EXISTS;
// DROP CONSTRAINT dr_alert_id IF EXISTS;

