// ============================================================================
// DEMO PHAT HIEN KHACH HANG CUNG CAP THANH KHOAN DAO NO
// File 03 - Phat hien tu du lieu goc va tao ket qua dan xuat
// Neo4j 5.x, khong yeu cau APOC/GDS
//
// Diem quan trong:
// - Query bat dau tu TOAN BO DRRepayment trong thang.
// - Khong nhap customerId cua X.
// - Khong dung referenceText/noi dung giao dich.
// - Khong dung quan he CIF.
// - Khong dung UNOBSERVED_PATH de phat hien.
// ============================================================================

// ----------------------------------------------------------------------------
// A. XOA KET QUA DAN XUAT CU, GIU NGUYEN DU LIEU NGHIEP VU GOC
// ----------------------------------------------------------------------------
MATCH (n)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
  AND (n:DRDetectedChain OR n:DRAlert)
DETACH DELETE n;

// ----------------------------------------------------------------------------
// B. PHAT HIEN VA VAT CHAT HOA CAC CHUOI TU MUC 1 DEN MUC 3
// ----------------------------------------------------------------------------
WITH
  datetime('2026-06-01T00:00:00+07:00') AS monthStart,
  datetime('2026-07-01T00:00:00+07:00') AS nextMonthStart

// Bat dau tu su kien thu no, khong bat dau tu X.
MATCH (b:DRCustomer)-[:MADE_REPAYMENT]->(repayment:DRRepayment)-[:REPAID]->(oldLoan:DRLoan)
WHERE repayment.pocDataset = 'debt_rollover_liquidity_v1'
  AND repayment.eventTime >= monthStart
  AND repayment.eventTime < nextMonthStart
  AND repayment.repaymentType IN [
    'PRINCIPAL_REPAYMENT',
    'FULL_SETTLEMENT',
    'LARGE_PRINCIPAL_REPAYMENT'
  ]

// Truy nguoc moi nguon tien truc tiep vao tai khoan cua B trong 72 gio.
MATCH (b)-[:OWNS]->(bAccount:DRAccount)
      <-[:RECEIVED_BY]-(supportTx:DRTransfer)
      <-[:SENT]-(xAccount:DRAccount)
      <-[:OWNS]-(x:DRCustomer)
WHERE x <> b
  AND supportTx.pocDataset = 'debt_rollover_liquidity_v1'
  AND supportTx.observedByBankA = true
  AND supportTx.eventTime < repayment.eventTime
  AND duration.inSeconds(supportTx.eventTime, repayment.eventTime).seconds
      <= 72 * 60 * 60

// DISTINCT theo node giao dich, sau do moi SUM de khong nhan ban so tien.
WITH DISTINCT
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan, supportTx
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  collect(supportTx) AS supportTxs,
  sum(supportTx.amount) AS supportAmount,
  min(supportTx.eventTime) AS firstSupportAt,
  max(supportTx.eventTime) AS lastSupportAt
WHERE supportAmount >= 100000000
  AND supportAmount >= 0.30 * repayment.amount

// Chon snapshot so du gan nhat, nhung khong sau giao dich ho tro dau tien.
OPTIONAL MATCH (b)-[:HAS_BALANCE_SNAPSHOT]->(candidateSnapshot:DRBalanceSnapshot)
WHERE candidateSnapshot.pocDataset = 'debt_rollover_liquidity_v1'
  AND candidateSnapshot.asOf <= firstSupportAt
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  candidateSnapshot
ORDER BY candidateSnapshot.asOf DESC
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  head(collect(candidateSnapshot)) AS balanceSnapshot
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  balanceSnapshot,
  repayment.amount - balanceSnapshot.availableBalance AS shortfall,
  1.0 * supportAmount / repayment.amount AS supportRatio,
  duration.inSeconds(firstSupportAt, repayment.eventTime).seconds / 3600.0
    AS hoursToRepayment
WHERE balanceSnapshot IS NOT NULL
  AND shortfall > 0
  AND supportAmount >= 0.50 * shortfall

// Tim lan giai ngan du dieu kien dau tien trong 7 ngay sau thu no.
OPTIONAL MATCH (b)-[:RECEIVED_DISBURSEMENT]->(candidateDisbursement:DRDisbursement)
WHERE candidateDisbursement.pocDataset = 'debt_rollover_liquidity_v1'
  AND candidateDisbursement.eventTime > repayment.eventTime
  AND duration.inSeconds(
        repayment.eventTime,
        candidateDisbursement.eventTime
      ).seconds <= 7 * 24 * 60 * 60
  AND candidateDisbursement.amount >= 0.50 * repayment.amount
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  balanceSnapshot, shortfall, supportRatio, hoursToRepayment,
  candidateDisbursement
ORDER BY candidateDisbursement.eventTime ASC
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  balanceSnapshot, shortfall, supportRatio, hoursToRepayment,
  head(collect(candidateDisbursement)) AS disbursement

// Tong hop moi giao dich tien vao X trong 7 ngay sau giai ngan.
// Query khong yeu cau nguoi chuyen ve phai la B.
OPTIONAL MATCH (x)-[:OWNS]->(xReturnAccount:DRAccount)
      <-[:RECEIVED_BY]-(returnTx:DRTransfer)
      <-[:SENT]-(returnSourceAccount:DRAccount)
WHERE disbursement IS NOT NULL
  AND returnTx.pocDataset = 'debt_rollover_liquidity_v1'
  AND returnTx.observedByBankA = true
  AND returnTx.eventTime > disbursement.eventTime
  AND duration.inSeconds(disbursement.eventTime, returnTx.eventTime).seconds
      <= 7 * 24 * 60 * 60
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  balanceSnapshot, shortfall, supportRatio, hoursToRepayment,
  disbursement,
  collect(DISTINCT returnTx) AS returnTxs
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  balanceSnapshot, shortfall, supportRatio, hoursToRepayment,
  disbursement, returnTxs,
  reduce(total = 0, t IN returnTxs | total + t.amount) AS returnAmount
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  balanceSnapshot, shortfall, supportRatio, hoursToRepayment,
  disbursement, returnTxs, returnAmount,
  1.0 * supportAmount / shortfall AS shortfallCoverageRatio,
  CASE
    WHEN supportAmount = 0 THEN 0.0
    ELSE 1.0 * returnAmount / supportAmount
  END AS returnRatio,
  CASE
    WHEN disbursement IS NULL THEN null
    ELSE duration.inSeconds(
           repayment.eventTime,
           disbursement.eventTime
         ).seconds / 3600.0
  END AS hoursToDisbursement
WITH
  monthStart, nextMonthStart,
  x, b, repayment, oldLoan,
  supportTxs, supportAmount, firstSupportAt, lastSupportAt,
  balanceSnapshot, shortfall, supportRatio, hoursToRepayment,
  disbursement, returnTxs, returnAmount,
  shortfallCoverageRatio, returnRatio, hoursToDisbursement,
  CASE
    WHEN disbursement IS NULL THEN 1
    WHEN returnRatio >= 0.50 AND returnRatio <= 1.50 THEN 3
    ELSE 2
  END AS chainLevel

MERGE (chain:DRDetectedChain {
  chainId: x.customerId + '|' + b.customerId + '|' + repayment.repaymentId
})
SET chain.analysisMonth = '2026-06',
    chain.chainLevel = chainLevel,
    chain.chainLevelLabel = CASE chainLevel
      WHEN 1 THEN 'MỨC 1 - NGUỒN TIỀN TRƯỚC THU NỢ'
      WHEN 2 THEN 'MỨC 2 - CÓ GIẢI NGÂN LẠI'
      ELSE 'MỨC 3 - CÓ TIỀN QUAY LẠI'
    END,
    chain.sourceCustomerId = x.customerId,
    chain.sourceCustomerType = x.customerType,
    chain.borrowerId = b.customerId,
    chain.borrowerType = b.customerType,
    chain.repaymentId = repayment.repaymentId,
    chain.oldLoanId = oldLoan.loanId,
    chain.repaymentAt = repayment.eventTime,
    chain.repaymentAmount = repayment.amount,
    chain.repaymentType = repayment.repaymentType,
    chain.balanceSnapshotId = balanceSnapshot.snapshotId,
    chain.balanceBeforeSupport = balanceSnapshot.availableBalance,
    chain.shortfall = shortfall,
    chain.supportAmount = supportAmount,
    chain.supportTransactionCount = size(supportTxs),
    chain.supportTransferIds = [t IN supportTxs | t.transferId],
    chain.firstSupportAt = firstSupportAt,
    chain.lastSupportAt = lastSupportAt,
    chain.hoursToRepayment = round(hoursToRepayment, 2),
    chain.supportRatio = supportRatio,
    chain.supportRatioPct = round(100.0 * supportRatio, 2),
    chain.shortfallCoverageRatio = shortfallCoverageRatio,
    chain.shortfallCoveragePct = round(100.0 * shortfallCoverageRatio, 2),
    chain.supportTimeBand = CASE
      WHEN hoursToRepayment <= 6 THEN 'VERY_HIGH_0_6H'
      WHEN hoursToRepayment <= 24 THEN 'HIGH_6_24H'
      ELSE 'MEDIUM_24_72H'
    END,
    chain.disbursementId = CASE
      WHEN disbursement IS NULL THEN null
      ELSE disbursement.disbursementId
    END,
    chain.disbursementAt = CASE
      WHEN disbursement IS NULL THEN null
      ELSE disbursement.eventTime
    END,
    chain.disbursementAmount = CASE
      WHEN disbursement IS NULL THEN null
      ELSE disbursement.amount
    END,
    chain.hoursToDisbursement = hoursToDisbursement,
    chain.returnAmount = returnAmount,
    chain.returnTransactionCount = size(returnTxs),
    chain.returnTransferIds = [t IN returnTxs | t.transferId],
    chain.returnRatio = returnRatio,
    chain.returnRatioPct = round(100.0 * returnRatio, 2),
    chain.returnStrength = CASE
      WHEN returnRatio >= 0.80 AND returnRatio <= 1.20 THEN 'VERY_STRONG_80_120'
      WHEN returnRatio >= 0.50 AND returnRatio < 0.80 THEN 'STRONG_50_80'
      WHEN returnRatio > 1.20 AND returnRatio <= 1.50 THEN 'REVIEW_120_150'
      ELSE 'INSUFFICIENT'
    END,
    chain.detectionBasis =
      'Giá trị + tỷ lệ + số dư + trình tự thời gian; không dùng nội dung/CIF',
    chain.pocDataset = 'debt_rollover_liquidity_v1',
    chain.detectedAt = datetime()
MERGE (chain)-[:SOURCE_CUSTOMER]->(x)
MERGE (chain)-[:BORROWER]->(b)
MERGE (chain)-[:USES_REPAYMENT]->(repayment)
MERGE (chain)-[:USES_OLD_LOAN]->(oldLoan)
MERGE (chain)-[:USES_BALANCE_SNAPSHOT]->(balanceSnapshot)
FOREACH (t IN supportTxs |
  MERGE (chain)-[:USES_SUPPORT_TRANSFER]->(t)
)
FOREACH (t IN returnTxs |
  MERGE (chain)-[:USES_RETURN_TRANSFER]->(t)
)
FOREACH (_ IN CASE WHEN disbursement IS NULL THEN [] ELSE [1] END |
  MERGE (chain)-[:USES_DISBURSEMENT]->(disbursement)
);

// ----------------------------------------------------------------------------
// C. TONG HOP THEO X, CHAM DIEM VA XAC DINH MUC 4
// ----------------------------------------------------------------------------
MATCH (chain:DRDetectedChain)-[:SOURCE_CUSTOMER]->(x:DRCustomer)
WHERE chain.pocDataset = 'debt_rollover_liquidity_v1'
  AND chain.analysisMonth = '2026-06'
OPTIONAL MATCH (chain)-[:BORROWER]->(b:DRCustomer)
WITH
  x,
  collect(DISTINCT chain) AS allChains,
  collect(DISTINCT CASE WHEN chain.chainLevel = 3 THEN b END)
    AS completeBorrowers
WITH
  x, allChains, completeBorrowers,
  [c IN allChains WHERE c.chainLevel = 3] AS completeChains
WITH
  x, allChains, completeBorrowers, completeChains,
  size(completeChains) AS completeChainCount,
  size(completeBorrowers) AS completeBorrowerCount,
  reduce(total = 0, c IN completeChains | total + c.supportAmount)
    AS totalSupportAmount,
  reduce(total = 0, c IN completeChains | total + c.returnAmount)
    AS totalReturnAmount,
  CASE
    WHEN size(completeChains) = 0 THEN null
    ELSE reduce(total = 0.0, c IN completeChains |
           total + c.hoursToRepayment) / size(completeChains)
  END AS avgHoursToRepayment,
  CASE
    WHEN size(completeChains) = 0 THEN null
    ELSE reduce(total = 0.0, c IN completeChains |
           total + c.supportRatio) / size(completeChains)
  END AS avgSupportRatio,
  CASE
    WHEN size(completeChains) = 0 THEN null
    ELSE reduce(total = 0.0, c IN completeChains |
           total + c.hoursToDisbursement) / size(completeChains)
  END AS avgHoursToDisbursement,
  CASE
    WHEN size(completeChains) = 0 THEN null
    ELSE reduce(total = 0.0, c IN completeChains |
           total + c.returnRatio) / size(completeChains)
  END AS avgReturnRatio,
  CASE
    WHEN any(c IN completeChains WHERE c.borrowerType = 'INDIVIDUAL')
     AND any(c IN completeChains WHERE c.borrowerType = 'COMPANY')
    THEN true
    ELSE false
  END AS borrowerTypeDiversity
WITH
  x, allChains, completeBorrowers, completeChains,
  completeChainCount, completeBorrowerCount,
  totalSupportAmount, totalReturnAmount,
  avgHoursToRepayment, avgSupportRatio,
  avgHoursToDisbursement, avgReturnRatio,
  borrowerTypeDiversity,
  CASE
    WHEN completeBorrowerCount >= 5 THEN 25
    WHEN completeBorrowerCount = 4 THEN 20
    WHEN completeBorrowerCount = 3 THEN 15
    ELSE 0
  END AS borrowerScore,
  CASE
    WHEN completeChainCount >= 5 THEN 20
    WHEN completeChainCount = 4 THEN 16
    WHEN completeChainCount = 3 THEN 12
    ELSE 0
  END AS chainScore,
  CASE
    WHEN completeChainCount = 0 THEN 0
    WHEN avgHoursToRepayment < 6 THEN 15
    WHEN avgHoursToRepayment <= 24 THEN 12
    ELSE 8
  END AS repaymentSpeedScore,
  CASE
    WHEN completeChainCount = 0 THEN 0
    WHEN avgSupportRatio >= 0.80 THEN 10
    WHEN avgSupportRatio >= 0.50 THEN 8
    ELSE 5
  END AS supportRatioScore,
  CASE
    WHEN completeChainCount = 0 THEN 0
    WHEN avgHoursToDisbursement <= 24 THEN 10
    WHEN avgHoursToDisbursement <= 72 THEN 8
    ELSE 5
  END AS disbursementSpeedScore,
  CASE
    WHEN completeChainCount = 0 THEN 0
    WHEN avgReturnRatio >= 0.80 AND avgReturnRatio <= 1.20 THEN 15
    WHEN avgReturnRatio >= 0.50 AND avgReturnRatio < 0.80 THEN 10
    WHEN avgReturnRatio > 1.20 AND avgReturnRatio <= 1.50 THEN 8
    ELSE 0
  END AS returnRatioScore,
  CASE
    WHEN completeChainCount = 0 THEN 0
    WHEN borrowerTypeDiversity THEN 5
    ELSE 3
  END AS diversityScore
WITH
  x, allChains, completeBorrowers, completeChains,
  completeChainCount, completeBorrowerCount,
  totalSupportAmount, totalReturnAmount,
  avgHoursToRepayment, avgSupportRatio,
  avgHoursToDisbursement, avgReturnRatio,
  borrowerTypeDiversity,
  borrowerScore, chainScore, repaymentSpeedScore,
  supportRatioScore, disbursementSpeedScore,
  returnRatioScore, diversityScore,
  borrowerScore + chainScore + repaymentSpeedScore
    + supportRatioScore + disbursementSpeedScore
    + returnRatioScore + diversityScore AS riskScore,
  CASE
    WHEN completeChainCount >= 3 AND completeBorrowerCount >= 3 THEN 4
    ELSE reduce(maxLevel = 0, c IN allChains |
           CASE WHEN c.chainLevel > maxLevel THEN c.chainLevel ELSE maxLevel END)
  END AS alertLevel
MERGE (alert:DRAlert {alertId:'ALT-2026-06-' + x.customerId})
SET alert.analysisMonth = '2026-06',
    alert.alertLevel = alertLevel,
    alert.alertLevelLabel = CASE alertLevel
      WHEN 1 THEN 'MỨC 1 - NGUỒN TIỀN TRƯỚC THU NỢ'
      WHEN 2 THEN 'MỨC 2 - CÓ GIẢI NGÂN LẠI'
      WHEN 3 THEN 'MỨC 3 - CÓ TIỀN QUAY LẠI'
      WHEN 4 THEN 'MỨC 4 - DẤU HIỆU CHUYÊN CUNG CẤP TIỀN ĐẢO NỢ'
      ELSE 'KHÔNG CẢNH BÁO'
    END,
    alert.customerId = x.customerId,
    alert.customerType = x.customerType,
    alert.detectedChainCount = size(allChains),
    alert.completeChainCount = completeChainCount,
    alert.distinctBorrowerCount = completeBorrowerCount,
    alert.borrowerIds = [b IN completeBorrowers | b.customerId],
    alert.totalSupportAmount = totalSupportAmount,
    alert.totalReturnAmount = totalReturnAmount,
    alert.overallReturnRatio = CASE
      WHEN totalSupportAmount = 0 THEN null
      ELSE 1.0 * totalReturnAmount / totalSupportAmount
    END,
    alert.overallReturnRatioPct = CASE
      WHEN totalSupportAmount = 0 THEN null
      ELSE round(100.0 * totalReturnAmount / totalSupportAmount, 2)
    END,
    alert.avgHoursToRepayment = CASE
      WHEN avgHoursToRepayment IS NULL THEN null
      ELSE round(avgHoursToRepayment, 2)
    END,
    alert.avgSupportRatioPct = CASE
      WHEN avgSupportRatio IS NULL THEN null
      ELSE round(100.0 * avgSupportRatio, 2)
    END,
    alert.avgHoursToDisbursement = CASE
      WHEN avgHoursToDisbursement IS NULL THEN null
      ELSE round(avgHoursToDisbursement, 2)
    END,
    alert.avgReturnRatioPct = CASE
      WHEN avgReturnRatio IS NULL THEN null
      ELSE round(100.0 * avgReturnRatio, 2)
    END,
    alert.hasBorrowerTypeDiversity = borrowerTypeDiversity,
    alert.riskScore = riskScore,
    alert.riskBand = CASE
      WHEN completeChainCount = 0 THEN 'NOT_SCORED_PARTIAL_CHAIN'
      WHEN riskScore >= 80 THEN 'HIGH'
      WHEN riskScore >= 60 THEN 'MEDIUM'
      ELSE 'LOW'
    END,
    alert.scoreBorrowers = borrowerScore,
    alert.scoreChains = chainScore,
    alert.scoreRepaymentSpeed = repaymentSpeedScore,
    alert.scoreSupportRatio = supportRatioScore,
    alert.scoreDisbursementSpeed = disbursementSpeedScore,
    alert.scoreReturnRatio = returnRatioScore,
    alert.scoreBorrowerDiversity = diversityScore,
    alert.conclusion = CASE
      WHEN alertLevel = 4 THEN
        'Có dấu hiệu lặp lại cung cấp thanh khoản ngắn hạn cho nhiều khách hàng vay trước thu nợ và nhận lượng tiền tương đồng sau giải ngân; cần kiểm tra bản chất kinh tế.'
      WHEN alertLevel = 3 THEN
        'Có một hoặc nhiều chuỗi hoàn chỉnh nhưng chưa đủ số khách hàng vay khác nhau để xác định Mức 4.'
      WHEN alertLevel = 2 THEN
        'Có nguồn tiền trước thu nợ và giải ngân lại nhưng chưa có tiền quay lại đạt ngưỡng.'
      ELSE
        'Có nguồn tiền đáng kể trước thu nợ nhưng chưa có giải ngân lại đạt điều kiện.'
    END,
    alert.pocDataset = 'debt_rollover_liquidity_v1',
    alert.detectedAt = datetime()
MERGE (alert)-[:ALERT_FOR]->(x)
FOREACH (c IN allChains |
  MERGE (alert)-[:INCLUDES_CHAIN]->(c)
  SET c.customerAlertLevel = alertLevel
);

// Ket qua nhanh sau khi vat chat hoa.
MATCH (a:DRAlert)-[:ALERT_FOR]->(x:DRCustomer)
WHERE a.pocDataset = 'debt_rollover_liquidity_v1'
RETURN
  x.customerId AS customerId,
  x.name AS customerName,
  a.alertLevel AS alertLevel,
  a.completeChainCount AS completeChains,
  a.distinctBorrowerCount AS distinctBorrowers,
  a.riskScore AS riskScore,
  a.riskBand AS riskBand
ORDER BY alertLevel DESC, riskScore DESC, customerId;

