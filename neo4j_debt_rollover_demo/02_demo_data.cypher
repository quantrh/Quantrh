// ============================================================================
// DEMO PHAT HIEN KHACH HANG CUNG CAP THANH KHOAN DAO NO
// File 02 - Du lieu nghiep vu goc
// Ky phan tich: 01/06/2026 - 30/06/2026, mui gio +07:00
// Co du lieu den 05/07/2026 de xu ly cua so 7 ngay cuoi thang.
//
// Luu y:
// - Khong gan nhan X/B vao node de query phat hien khong "biet truoc X".
// - Khong co quan he CIF giua X001 va B001-B004.
// - referenceText chi de hien thi khi dieu tra; query khong duoc su dung.
// - UNOBSERVED_PATH la quan he suy luan, khong phai giao dich Bank A quan sat.
// ============================================================================

// ----------------------------------------------------------------------------
// 1. NGAN HANG
// ----------------------------------------------------------------------------
UNWIND [
  {bankCode:'BANK_A', bankName:'Ngân hàng A', observationRole:'REPORTING_BANK'},
  {bankCode:'BANK_B', bankName:'Ngân hàng B', observationRole:'EXTERNAL_BANK'},
  {bankCode:'BANK_C', bankName:'Ngân hàng C', observationRole:'EXTERNAL_BANK'},
  {bankCode:'BANK_D', bankName:'Ngân hàng D', observationRole:'EXTERNAL_BANK'}
] AS row
MERGE (n:DRBank {bankCode:row.bankCode})
SET n.bankName = row.bankName,
    n.observationRole = row.observationRole,
    n.pocDataset = 'debt_rollover_liquidity_v1';

// ----------------------------------------------------------------------------
// 2. KHACH HANG
// X001-X005 va B001-B010 chi la ma du lieu; query khong loc theo tien to ma.
// ----------------------------------------------------------------------------
UNWIND [
  {customerId:'X001', name:'Công ty Minh Phát', customerType:'COMPANY'},
  {customerId:'X002', name:'Công ty Thương mại An Bình', customerType:'COMPANY'},
  {customerId:'X003', name:'Nguyễn Văn Nam', customerType:'INDIVIDUAL'},
  {customerId:'X004', name:'Công ty Đầu tư Đông Dương', customerType:'COMPANY'},
  {customerId:'X005', name:'Trần Minh Khoa', customerType:'INDIVIDUAL'},

  {customerId:'B001', name:'Công ty Cơ khí Sao Việt', customerType:'COMPANY'},
  {customerId:'B002', name:'Nguyễn Hoàng Anh', customerType:'INDIVIDUAL'},
  {customerId:'B003', name:'Công ty Bao bì Tân Phúc', customerType:'COMPANY'},
  {customerId:'B004', name:'Lê Thu Hà', customerType:'INDIVIDUAL'},
  {customerId:'B005', name:'Công ty Nội thất Hòa Bình', customerType:'COMPANY'},
  {customerId:'B006', name:'Phạm Quốc Việt', customerType:'INDIVIDUAL'},
  {customerId:'B007', name:'Công ty Vận tải Thành Công', customerType:'COMPANY'},
  {customerId:'B008', name:'Công ty Phân phối Gia Long', customerType:'COMPANY'},
  {customerId:'B009', name:'Đỗ Minh Tuấn', customerType:'INDIVIDUAL'},
  {customerId:'B010', name:'Công ty Dịch vụ Ánh Dương', customerType:'COMPANY'}
] AS row
MERGE (n:DRCustomer {customerId:row.customerId})
SET n.name = row.name,
    n.customerType = row.customerType,
    n.pocDataset = 'debt_rollover_liquidity_v1';

// ----------------------------------------------------------------------------
// 3. TAI KHOAN NOI BO TAI BANK A
// ----------------------------------------------------------------------------
UNWIND [
  {accountId:'A-X001-01', customerId:'X001', accountName:'TK thanh toán X001'},
  {accountId:'A-X002-01', customerId:'X002', accountName:'TK thanh toán X002'},
  {accountId:'A-X003-01', customerId:'X003', accountName:'TK thanh toán X003'},
  {accountId:'A-X004-01', customerId:'X004', accountName:'TK thanh toán X004'},
  {accountId:'A-X005-01', customerId:'X005', accountName:'TK thanh toán X005'},
  {accountId:'A-B001-01', customerId:'B001', accountName:'TK thanh toán B001'},
  {accountId:'A-B002-01', customerId:'B002', accountName:'TK thanh toán B002'},
  {accountId:'A-B003-01', customerId:'B003', accountName:'TK thanh toán B003'},
  {accountId:'A-B004-01', customerId:'B004', accountName:'TK thanh toán B004'},
  {accountId:'A-B005-01', customerId:'B005', accountName:'TK thanh toán B005'},
  {accountId:'A-B006-01', customerId:'B006', accountName:'TK thanh toán B006'},
  {accountId:'A-B007-01', customerId:'B007', accountName:'TK thanh toán B007'},
  {accountId:'A-B008-01', customerId:'B008', accountName:'TK thanh toán B008'},
  {accountId:'A-B009-01', customerId:'B009', accountName:'TK thanh toán B009'},
  {accountId:'A-B010-01', customerId:'B010', accountName:'TK thanh toán B010'}
] AS row
MATCH (c:DRCustomer {customerId:row.customerId})
MATCH (bank:DRBank {bankCode:'BANK_A'})
MERGE (a:DRAccount {accountId:row.accountId})
SET a.accountName = row.accountName,
    a.bankCode = 'BANK_A',
    a.isInternal = true,
    a.observationScope = 'BANK_A_FULL',
    a.pocDataset = 'debt_rollover_liquidity_v1'
MERGE (c)-[:OWNS]->(a)
MERGE (a)-[:HELD_AT]->(bank);

// ----------------------------------------------------------------------------
// 4. TAI KHOAN NGOAI BANK A
// Bank A chi biet thong tin doi tac tren lenh di/den, khong thay lich su noi bo.
// ----------------------------------------------------------------------------
UNWIND [
  // Tai khoan nhan giai ngan
  {accountId:'EXT-D-B001-01', bankCode:'BANK_B', accountName:'TK ngoài NH nhận GN B001'},
  {accountId:'EXT-D-B002-01', bankCode:'BANK_C', accountName:'TK ngoài NH nhận GN B002'},
  {accountId:'EXT-D-B003-01', bankCode:'BANK_B', accountName:'TK ngoài NH nhận GN B003'},
  {accountId:'EXT-D-B004-01', bankCode:'BANK_D', accountName:'TK ngoài NH nhận GN B004'},
  {accountId:'EXT-D-B005-01', bankCode:'BANK_B', accountName:'TK ngoài NH nhận GN B005'},
  {accountId:'EXT-D-B007-01', bankCode:'BANK_C', accountName:'TK ngoài NH nhận GN B007'},
  {accountId:'EXT-D-B008-01', bankCode:'BANK_B', accountName:'TK ngoài NH nhận GN B008'},
  {accountId:'EXT-D-B009-01', bankCode:'BANK_C', accountName:'TK ngoài NH nhận GN B009'},
  {accountId:'EXT-D-B010-01', bankCode:'BANK_D', accountName:'TK ngoài NH nhận GN B010'},

  // Tai khoan chuyen tien quay lai
  {accountId:'EXT-R-B001-01', bankCode:'BANK_B', accountName:'TK ngoài NH chuyển về X001 / B001'},
  {accountId:'EXT-R-B002-01', bankCode:'BANK_C', accountName:'TK ngoài NH 1 chuyển về X001 / B002'},
  {accountId:'EXT-R-B002-02', bankCode:'BANK_D', accountName:'TK ngoài NH 2 chuyển về X001 / B002'},
  {accountId:'EXT-R-B003-01', bankCode:'BANK_B', accountName:'TK ngoài NH chuyển về X001 / B003'},
  {accountId:'EXT-R-B004-01', bankCode:'BANK_B', accountName:'TK ngoài NH 1 chuyển về X001 / B004'},
  {accountId:'EXT-R-B004-02', bankCode:'BANK_C', accountName:'TK ngoài NH 2 chuyển về X001 / B004'},
  {accountId:'EXT-R-B004-03', bankCode:'BANK_D', accountName:'TK ngoài NH 3 chuyển về X001 / B004'},
  {accountId:'EXT-R-B005-01', bankCode:'BANK_B', accountName:'TK ngoài NH chuyển về X003 / B005'},

  // Nguon tien kinh doanh thong thuong / doi chung
  {accountId:'EXT-N-X001-01', bankCode:'BANK_C', accountName:'Đối tác kinh doanh nhỏ của X001'},
  {accountId:'EXT-N-X002-01', bankCode:'BANK_B', accountName:'Đối tác kinh doanh của X002'},
  {accountId:'EXT-N-X005-01', bankCode:'BANK_D', accountName:'Đối tác kinh doanh của X005'}
] AS row
MATCH (bank:DRBank {bankCode:row.bankCode})
MERGE (a:DRAccount {accountId:row.accountId})
SET a.accountName = row.accountName,
    a.bankCode = row.bankCode,
    a.isInternal = false,
    a.observationScope = 'COUNTERPARTY_VISIBLE_ONLY',
    a.pocDataset = 'debt_rollover_liquidity_v1'
MERGE (a)-[:HELD_AT]->(bank);

// ----------------------------------------------------------------------------
// 5. KHOAN VAY CU VA KHOAN VAY MOI
// ----------------------------------------------------------------------------
UNWIND [
  {loanId:'L-OLD-B001', customerId:'B001', loanRole:'OLD', productType:'TERM_LOAN', status:'CLOSED'},
  {loanId:'L-NEW-B001', customerId:'B001', loanRole:'NEW', productType:'REVOLVING_DRAW', status:'ACTIVE'},
  {loanId:'L-OLD-B002', customerId:'B002', loanRole:'OLD', productType:'TERM_LOAN', status:'ACTIVE'},
  {loanId:'L-NEW-B002', customerId:'B002', loanRole:'NEW', productType:'NEW_LOAN', status:'ACTIVE'},
  {loanId:'L-OLD-B003', customerId:'B003', loanRole:'OLD', productType:'WORKING_CAPITAL', status:'ACTIVE'},
  {loanId:'L-NEW-B003', customerId:'B003', loanRole:'NEW', productType:'REVOLVING_DRAW', status:'ACTIVE'},
  {loanId:'L-OLD-B004', customerId:'B004', loanRole:'OLD', productType:'TERM_LOAN', status:'CLOSED'},
  {loanId:'L-NEW-B004', customerId:'B004', loanRole:'NEW', productType:'NEW_LOAN', status:'ACTIVE'},
  {loanId:'L-OLD-B005', customerId:'B005', loanRole:'OLD', productType:'WORKING_CAPITAL', status:'CLOSED'},
  {loanId:'L-NEW-B005', customerId:'B005', loanRole:'NEW', productType:'NEW_LOAN', status:'ACTIVE'},
  {loanId:'L-OLD-B006', customerId:'B006', loanRole:'OLD', productType:'TERM_LOAN', status:'ACTIVE'},
  {loanId:'L-OLD-B007', customerId:'B007', loanRole:'OLD', productType:'WORKING_CAPITAL', status:'ACTIVE'},
  {loanId:'L-NEW-B007', customerId:'B007', loanRole:'NEW', productType:'REVOLVING_DRAW', status:'ACTIVE'},
  {loanId:'L-OLD-B008', customerId:'B008', loanRole:'OLD', productType:'WORKING_CAPITAL', status:'ACTIVE'},
  {loanId:'L-NEW-B008', customerId:'B008', loanRole:'NEW', productType:'REVOLVING_DRAW', status:'ACTIVE'},
  {loanId:'L-OLD-B009', customerId:'B009', loanRole:'OLD', productType:'TERM_LOAN', status:'CLOSED'},
  {loanId:'L-NEW-B009', customerId:'B009', loanRole:'NEW', productType:'NEW_LOAN', status:'ACTIVE'},
  {loanId:'L-OLD-B010', customerId:'B010', loanRole:'OLD', productType:'WORKING_CAPITAL', status:'ACTIVE'},
  {loanId:'L-NEW-B010', customerId:'B010', loanRole:'NEW', productType:'REVOLVING_DRAW', status:'ACTIVE'}
] AS row
MATCH (c:DRCustomer {customerId:row.customerId})
MERGE (l:DRLoan {loanId:row.loanId})
SET l.loanRole = row.loanRole,
    l.productType = row.productType,
    l.status = row.status,
    l.currency = 'VND',
    l.pocDataset = 'debt_rollover_liquidity_v1'
MERGE (c)-[:BORROWER_OF]->(l);

// ----------------------------------------------------------------------------
// 6. SNAPSHOT SO DU KHA DUNG TRUOC GIAO DICH DAU TIEN TU NGUON X
// Co them snapshot cu cua B001 de kiem tra query chon snapshot gan nhat.
// ----------------------------------------------------------------------------
UNWIND [
  {snapshotId:'BS-B001-OLD', customerId:'B001', asOf:'2026-05-31T18:00:00+07:00', availableBalance:1500000000},
  {snapshotId:'BS-B001-01', customerId:'B001', asOf:'2026-06-02T07:59:00+07:00', availableBalance:100000000},
  {snapshotId:'BS-B002-01', customerId:'B002', asOf:'2026-06-09T07:59:00+07:00', availableBalance:250000000},
  {snapshotId:'BS-B003-01', customerId:'B003', asOf:'2026-06-16T07:59:00+07:00', availableBalance:300000000},
  {snapshotId:'BS-B004-01', customerId:'B004', asOf:'2026-06-27T07:59:00+07:00', availableBalance:400000000},
  {snapshotId:'BS-B005-01', customerId:'B005', asOf:'2026-06-05T08:59:00+07:00', availableBalance:150000000},
  {snapshotId:'BS-B006-01', customerId:'B006', asOf:'2026-06-12T07:59:00+07:00', availableBalance:100000000},
  {snapshotId:'BS-B007-01', customerId:'B007', asOf:'2026-06-19T07:59:00+07:00', availableBalance:250000000},

  // X002 la doi chung: B008-B010 da du tien truoc khi nhan tien.
  {snapshotId:'BS-B008-01', customerId:'B008', asOf:'2026-06-04T08:59:00+07:00', availableBalance:700000000},
  {snapshotId:'BS-B009-01', customerId:'B009', asOf:'2026-06-14T08:59:00+07:00', availableBalance:800000000},
  {snapshotId:'BS-B010-01', customerId:'B010', asOf:'2026-06-24T08:59:00+07:00', availableBalance:1000000000}
] AS row
MATCH (c:DRCustomer {customerId:row.customerId})
MERGE (s:DRBalanceSnapshot {snapshotId:row.snapshotId})
SET s.asOf = datetime(row.asOf),
    s.availableBalance = row.availableBalance,
    s.currency = 'VND',
    s.snapshotScope = 'AVAILABLE_BALANCE_BEFORE_SUPPORT',
    s.pocDataset = 'debt_rollover_liquidity_v1'
MERGE (c)-[:HAS_BALANCE_SNAPSHOT]->(s);

// ----------------------------------------------------------------------------
// 7. SU KIEN THU NO
// Chi 3 repaymentType dau duoc dung trong phat hien.
// ----------------------------------------------------------------------------
UNWIND [
  {repaymentId:'RP-B001-01', customerId:'B001', accountId:'A-B001-01', loanId:'L-OLD-B001', eventTime:'2026-06-02T13:00:00+07:00', amount:900000000, repaymentType:'FULL_SETTLEMENT'},
  {repaymentId:'RP-B002-01', customerId:'B002', accountId:'A-B002-01', loanId:'L-OLD-B002', eventTime:'2026-06-10T04:00:00+07:00', amount:1400000000, repaymentType:'LARGE_PRINCIPAL_REPAYMENT'},
  {repaymentId:'RP-B003-01', customerId:'B003', accountId:'A-B003-01', loanId:'L-OLD-B003', eventTime:'2026-06-18T08:00:00+07:00', amount:1000000000, repaymentType:'PRINCIPAL_REPAYMENT'},
  {repaymentId:'RP-B004-01', customerId:'B004', accountId:'A-B004-01', loanId:'L-OLD-B004', eventTime:'2026-06-27T18:00:00+07:00', amount:2300000000, repaymentType:'FULL_SETTLEMENT'},
  {repaymentId:'RP-B005-01', customerId:'B005', accountId:'A-B005-01', loanId:'L-OLD-B005', eventTime:'2026-06-05T17:00:00+07:00', amount:700000000, repaymentType:'FULL_SETTLEMENT'},
  {repaymentId:'RP-B006-01', customerId:'B006', accountId:'A-B006-01', loanId:'L-OLD-B006', eventTime:'2026-06-12T20:00:00+07:00', amount:600000000, repaymentType:'LARGE_PRINCIPAL_REPAYMENT'},
  {repaymentId:'RP-B007-01', customerId:'B007', accountId:'A-B007-01', loanId:'L-OLD-B007', eventTime:'2026-06-19T14:00:00+07:00', amount:900000000, repaymentType:'PRINCIPAL_REPAYMENT'},
  {repaymentId:'RP-B008-01', customerId:'B008', accountId:'A-B008-01', loanId:'L-OLD-B008', eventTime:'2026-06-04T17:00:00+07:00', amount:400000000, repaymentType:'PRINCIPAL_REPAYMENT'},
  {repaymentId:'RP-B009-01', customerId:'B009', accountId:'A-B009-01', loanId:'L-OLD-B009', eventTime:'2026-06-15T09:00:00+07:00', amount:500000000, repaymentType:'FULL_SETTLEMENT'},
  {repaymentId:'RP-B010-01', customerId:'B010', accountId:'A-B010-01', loanId:'L-OLD-B010', eventTime:'2026-06-26T09:00:00+07:00', amount:600000000, repaymentType:'PRINCIPAL_REPAYMENT'},

  // Giao dich nhieu de chung minh query loai tru dung loai thu no.
  {repaymentId:'RP-NOISE-B001-INT', customerId:'B001', accountId:'A-B001-01', loanId:'L-NEW-B001', eventTime:'2026-06-07T09:00:00+07:00', amount:15000000, repaymentType:'INTEREST_ONLY'},
  {repaymentId:'RP-NOISE-B002-FEE', customerId:'B002', accountId:'A-B002-01', loanId:'L-OLD-B002', eventTime:'2026-06-09T03:00:00+07:00', amount:5000000, repaymentType:'FEE_PAYMENT'},
  {repaymentId:'RP-NOISE-B003-SMALL', customerId:'B003', accountId:'A-B003-01', loanId:'L-NEW-B003', eventTime:'2026-06-25T10:00:00+07:00', amount:20000000, repaymentType:'SMALL_SCHEDULED_PRINCIPAL'}
] AS row
MATCH (c:DRCustomer {customerId:row.customerId})
MATCH (a:DRAccount {accountId:row.accountId})
MATCH (l:DRLoan {loanId:row.loanId})
MERGE (r:DRRepayment {repaymentId:row.repaymentId})
SET r.eventTime = datetime(row.eventTime),
    r.amount = row.amount,
    r.currency = 'VND',
    r.repaymentType = row.repaymentType,
    r.observedByBankA = true,
    r.pocDataset = 'debt_rollover_liquidity_v1'
MERGE (c)-[:MADE_REPAYMENT]->(r)
MERGE (a)-[:PAYMENT_ACCOUNT_FOR]->(r)
MERGE (r)-[:REPAID]->(l);

// ----------------------------------------------------------------------------
// 8. SU KIEN GIAI NGAN MOI
// B006 khong co giai ngan moi: doi chung Muc 1.
// ----------------------------------------------------------------------------
UNWIND [
  {disbursementId:'DB-B001-01', customerId:'B001', loanId:'L-NEW-B001', destinationAccountId:'EXT-D-B001-01', eventTime:'2026-06-03T13:00:00+07:00', amount:1000000000},
  {disbursementId:'DB-B002-01', customerId:'B002', loanId:'L-NEW-B002', destinationAccountId:'EXT-D-B002-01', eventTime:'2026-06-12T04:00:00+07:00', amount:1500000000},
  {disbursementId:'DB-B003-01', customerId:'B003', loanId:'L-NEW-B003', destinationAccountId:'EXT-D-B003-01', eventTime:'2026-06-21T08:00:00+07:00', amount:900000000},
  {disbursementId:'DB-B004-01', customerId:'B004', loanId:'L-NEW-B004', destinationAccountId:'EXT-D-B004-01', eventTime:'2026-06-28T18:00:00+07:00', amount:2500000000},
  {disbursementId:'DB-B005-01', customerId:'B005', loanId:'L-NEW-B005', destinationAccountId:'EXT-D-B005-01', eventTime:'2026-06-06T17:00:00+07:00', amount:800000000},
  {disbursementId:'DB-B007-01', customerId:'B007', loanId:'L-NEW-B007', destinationAccountId:'EXT-D-B007-01', eventTime:'2026-06-21T14:00:00+07:00', amount:1000000000},

  // X002 van khong bi canh bao vi so du truoc ho tro cua B da du.
  {disbursementId:'DB-B008-01', customerId:'B008', loanId:'L-NEW-B008', destinationAccountId:'EXT-D-B008-01', eventTime:'2026-06-05T17:00:00+07:00', amount:450000000},
  {disbursementId:'DB-B009-01', customerId:'B009', loanId:'L-NEW-B009', destinationAccountId:'EXT-D-B009-01', eventTime:'2026-06-17T09:00:00+07:00', amount:550000000},
  {disbursementId:'DB-B010-01', customerId:'B010', loanId:'L-NEW-B010', destinationAccountId:'EXT-D-B010-01', eventTime:'2026-06-27T09:00:00+07:00', amount:650000000}
] AS row
MATCH (c:DRCustomer {customerId:row.customerId})
MATCH (l:DRLoan {loanId:row.loanId})
MATCH (a:DRAccount {accountId:row.destinationAccountId})
MERGE (d:DRDisbursement {disbursementId:row.disbursementId})
SET d.eventTime = datetime(row.eventTime),
    d.amount = row.amount,
    d.currency = 'VND',
    d.observedByBankA = true,
    d.pocDataset = 'debt_rollover_liquidity_v1'
MERGE (c)-[:RECEIVED_DISBURSEMENT]->(d)
MERGE (l)-[:HAS_DISBURSEMENT]->(d)
MERGE (d)-[:PAID_TO]->(a);

// ----------------------------------------------------------------------------
// 9. GIAO DICH CHUYEN TIEN BANK A QUAN SAT DUOC
// sourceAccount -[:SENT]-> Transfer -[:RECEIVED_BY]-> destinationAccount
// ----------------------------------------------------------------------------
UNWIND [
  // ---- Bon cum X001 chuyen cho B001-B004 ----
  {transferId:'TR-X001-B001-01', sourceAccountId:'A-X001-01', destinationAccountId:'A-B001-01', eventTime:'2026-06-02T08:00:00+07:00', amount:800000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},

  {transferId:'TR-X001-B002-01', sourceAccountId:'A-X001-01', destinationAccountId:'A-B002-01', eventTime:'2026-06-09T08:00:00+07:00', amount:400000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},
  {transferId:'TR-X001-B002-02', sourceAccountId:'A-X001-01', destinationAccountId:'A-B002-01', eventTime:'2026-06-09T09:00:00+07:00', amount:350000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},
  {transferId:'TR-X001-B002-03', sourceAccountId:'A-X001-01', destinationAccountId:'A-B002-01', eventTime:'2026-06-09T10:00:00+07:00', amount:450000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},

  {transferId:'TR-X001-B003-01', sourceAccountId:'A-X001-01', destinationAccountId:'A-B003-01', eventTime:'2026-06-16T08:00:00+07:00', amount:600000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},
  {transferId:'TR-X001-B004-01', sourceAccountId:'A-X001-01', destinationAccountId:'A-B004-01', eventTime:'2026-06-27T08:00:00+07:00', amount:2000000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},

  // ---- Tien quay lai X001 tu cac tai khoan ngoai Bank A ----
  {transferId:'TR-RET-X001-B001-01', sourceAccountId:'EXT-R-B001-01', destinationAccountId:'A-X001-01', eventTime:'2026-06-05T10:00:00+07:00', amount:820000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},

  {transferId:'TR-RET-X001-B002-01', sourceAccountId:'EXT-R-B002-01', destinationAccountId:'A-X001-01', eventTime:'2026-06-13T10:00:00+07:00', amount:600000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},
  {transferId:'TR-RET-X001-B002-02', sourceAccountId:'EXT-R-B002-02', destinationAccountId:'A-X001-01', eventTime:'2026-06-14T09:00:00+07:00', amount:500000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},

  {transferId:'TR-RET-X001-B003-01', sourceAccountId:'EXT-R-B003-01', destinationAccountId:'A-X001-01', eventTime:'2026-06-23T09:00:00+07:00', amount:450000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},

  {transferId:'TR-RET-X001-B004-01', sourceAccountId:'EXT-R-B004-01', destinationAccountId:'A-X001-01', eventTime:'2026-06-30T10:00:00+07:00', amount:800000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},
  {transferId:'TR-RET-X001-B004-02', sourceAccountId:'EXT-R-B004-02', destinationAccountId:'A-X001-01', eventTime:'2026-07-01T09:00:00+07:00', amount:700000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},
  {transferId:'TR-RET-X001-B004-03', sourceAccountId:'EXT-R-B004-03', destinationAccountId:'A-X001-01', eventTime:'2026-07-02T11:00:00+07:00', amount:600000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},

  // Hai khoan tien kinh doanh nho cua X001 nam ngoai cac cua so quay lai.
  {transferId:'TR-NORMAL-X001-01', sourceAccountId:'EXT-N-X001-01', destinationAccountId:'A-X001-01', eventTime:'2026-06-11T10:00:00+07:00', amount:20000000, directionClass:'EXTERNAL_IN', referenceText:'Thanh toán thông thường'},
  {transferId:'TR-NORMAL-X001-02', sourceAccountId:'EXT-N-X001-01', destinationAccountId:'A-X001-01', eventTime:'2026-06-20T10:00:00+07:00', amount:25000000, directionClass:'EXTERNAL_IN', referenceText:'Thanh toán thông thường'},

  // ---- X003: mot chuoi hoan chinh, chi dat Muc 3 ----
  {transferId:'TR-X003-B005-01', sourceAccountId:'A-X003-01', destinationAccountId:'A-B005-01', eventTime:'2026-06-05T09:00:00+07:00', amount:500000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},
  {transferId:'TR-RET-X003-B005-01', sourceAccountId:'EXT-R-B005-01', destinationAccountId:'A-X003-01', eventTime:'2026-06-08T10:00:00+07:00', amount:480000000, directionClass:'EXTERNAL_IN', referenceText:'Tiền vào liên ngân hàng'},

  // ---- X004: dat Muc 1, khong co giai ngan lai ----
  {transferId:'TR-X004-B006-01', sourceAccountId:'A-X004-01', destinationAccountId:'A-B006-01', eventTime:'2026-06-12T08:00:00+07:00', amount:400000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},

  // ---- X005: dat Muc 2; tien ve 30 trieu chi bang 4,29% ----
  {transferId:'TR-X005-B007-01', sourceAccountId:'A-X005-01', destinationAccountId:'A-B007-01', eventTime:'2026-06-19T08:00:00+07:00', amount:700000000, directionClass:'INTERNAL', referenceText:'Giao dịch chuyển khoản'},
  {transferId:'TR-NORMAL-X005-01', sourceAccountId:'EXT-N-X005-01', destinationAccountId:'A-X005-01', eventTime:'2026-06-23T10:00:00+07:00', amount:30000000, directionClass:'EXTERNAL_IN', referenceText:'Thanh toán thông thường'},

  // ---- X002: chuyen cho 3 B, co thu no va giai ngan nhung B da du so du ----
  {transferId:'TR-X002-B008-01', sourceAccountId:'A-X002-01', destinationAccountId:'A-B008-01', eventTime:'2026-06-04T09:00:00+07:00', amount:200000000, directionClass:'INTERNAL', referenceText:'Thanh toán hàng hóa'},
  {transferId:'TR-X002-B009-01', sourceAccountId:'A-X002-01', destinationAccountId:'A-B009-01', eventTime:'2026-06-14T09:00:00+07:00', amount:250000000, directionClass:'INTERNAL', referenceText:'Thanh toán hàng hóa'},
  {transferId:'TR-X002-B010-01', sourceAccountId:'A-X002-01', destinationAccountId:'A-B010-01', eventTime:'2026-06-24T09:00:00+07:00', amount:300000000, directionClass:'INTERNAL', referenceText:'Thanh toán hàng hóa'},
  {transferId:'TR-NORMAL-X002-01', sourceAccountId:'EXT-N-X002-01', destinationAccountId:'A-X002-01', eventTime:'2026-06-06T10:00:00+07:00', amount:1200000000, directionClass:'EXTERNAL_IN', referenceText:'Doanh thu kinh doanh'},
  {transferId:'TR-NORMAL-X002-02', sourceAccountId:'EXT-N-X002-01', destinationAccountId:'A-X002-01', eventTime:'2026-06-18T10:00:00+07:00', amount:950000000, directionClass:'EXTERNAL_IN', referenceText:'Doanh thu kinh doanh'},
  {transferId:'TR-NORMAL-X002-03', sourceAccountId:'EXT-N-X002-01', destinationAccountId:'A-X002-01', eventTime:'2026-06-29T10:00:00+07:00', amount:1400000000, directionClass:'EXTERNAL_IN', referenceText:'Doanh thu kinh doanh'}
] AS row
MATCH (src:DRAccount {accountId:row.sourceAccountId})
MATCH (dst:DRAccount {accountId:row.destinationAccountId})
MERGE (t:DRTransfer {transferId:row.transferId})
SET t.eventTime = datetime(row.eventTime),
    t.amount = row.amount,
    t.currency = 'VND',
    t.directionClass = row.directionClass,
    t.referenceText = row.referenceText,
    t.observedByBankA = true,
    t.pocDataset = 'debt_rollover_liquidity_v1'
MERGE (src)-[:SENT]->(t)
MERGE (t)-[:RECEIVED_BY]->(dst);

// ----------------------------------------------------------------------------
// 10. VUNG KHONG QUAN SAT DUOC
// Quan he nay chi noi "co kha nang ton tai duong di" giua tai khoan nhan
// giai ngan va tai khoan chuyen ve. No KHONG phai giao dich quan sat duoc,
// KHONG mang so tien va KHONG duoc su dung trong query phat hien.
// ----------------------------------------------------------------------------
UNWIND [
  {fromAccountId:'EXT-D-B001-01', toAccountId:'EXT-R-B001-01', chainRef:'B001'},
  {fromAccountId:'EXT-D-B002-01', toAccountId:'EXT-R-B002-01', chainRef:'B002'},
  {fromAccountId:'EXT-D-B002-01', toAccountId:'EXT-R-B002-02', chainRef:'B002'},
  {fromAccountId:'EXT-D-B003-01', toAccountId:'EXT-R-B003-01', chainRef:'B003'},
  {fromAccountId:'EXT-D-B004-01', toAccountId:'EXT-R-B004-01', chainRef:'B004'},
  {fromAccountId:'EXT-D-B004-01', toAccountId:'EXT-R-B004-02', chainRef:'B004'},
  {fromAccountId:'EXT-D-B004-01', toAccountId:'EXT-R-B004-03', chainRef:'B004'},
  {fromAccountId:'EXT-D-B005-01', toAccountId:'EXT-R-B005-01', chainRef:'B005'}
] AS row
MATCH (a:DRAccount {accountId:row.fromAccountId})
MATCH (b:DRAccount {accountId:row.toAccountId})
MERGE (a)-[r:UNOBSERVED_PATH {chainRef:row.chainRef}]->(b)
SET r.inferred = true,
    r.observedByBankA = false,
    r.observation = 'NOT_OBSERVED',
    r.displayLabel = 'không quan sát được',
    r.confidence = 'HYPOTHESIS_ONLY',
    r.pocDataset = 'debt_rollover_liquidity_v1';

