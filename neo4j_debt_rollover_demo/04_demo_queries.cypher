// ============================================================================
// DEMO PHAT HIEN KHACH HANG CUNG CAP THANH KHOAN DAO NO
// File 04 - Cac query trinh dien sau khi chay file 03
// Moi khoi Qxx la mot query doc lap; chay tung khoi trong Neo4j Browser.
// ============================================================================

// ----------------------------------------------------------------------------
// Q01. DANH SACH X DAT CANH BAO MUC 4
// Ket qua mong doi: chi co X001.
// ----------------------------------------------------------------------------
MATCH (alert:DRAlert)-[:ALERT_FOR]->(x:DRCustomer)
WHERE alert.pocDataset = 'debt_rollover_liquidity_v1'
  AND alert.analysisMonth = '2026-06'
  AND alert.alertLevel = 4
RETURN
  x.customerId AS customerX,
  x.name AS customerName,
  x.customerType AS customerType,
  alert.distinctBorrowerCount AS distinctBorrowers,
  alert.completeChainCount AS completeChains,
  round(alert.totalSupportAmount / 1000000000.0, 3)
    AS totalSupportBillionVND,
  round(alert.totalReturnAmount / 1000000000.0, 3)
    AS totalReturnBillionVND,
  alert.overallReturnRatioPct AS overallReturnRatioPct,
  alert.riskScore AS riskScore,
  alert.riskBand AS riskBand,
  alert.alertLevelLabel AS alertLevel
ORDER BY riskScore DESC;

// ----------------------------------------------------------------------------
// Q02. PHAN LOAI CAC KHACH HANG DOI CHUNG X001-X005
// Day la query nghiem thu co danh sach ID co dinh, KHONG phai query phat hien.
// X002 = 0/khong canh bao; X001=4; X003=3; X004=1; X005=2.
// ----------------------------------------------------------------------------
MATCH (x:DRCustomer)
WHERE x.pocDataset = 'debt_rollover_liquidity_v1'
  AND x.customerId IN ['X001','X002','X003','X004','X005']
OPTIONAL MATCH (alert:DRAlert)-[:ALERT_FOR]->(x)
WHERE alert.analysisMonth = '2026-06'
RETURN
  x.customerId AS customerId,
  x.name AS customerName,
  coalesce(alert.alertLevel, 0) AS alertLevel,
  coalesce(alert.alertLevelLabel, 'KHÔNG CẢNH BÁO - KHÔNG ĐẠT ĐIỀU KIỆN SỐ DƯ')
    AS classification,
  coalesce(alert.completeChainCount, 0) AS completeChains,
  coalesce(alert.distinctBorrowerCount, 0) AS distinctBorrowers,
  alert.riskScore AS riskScore
ORDER BY customerId;

// ----------------------------------------------------------------------------
// Q03. CHI TIET 100 DIEM CUA CAC X CO CHUOI HOAN CHINH
// X001 du kien 86 diem.
// ----------------------------------------------------------------------------
MATCH (alert:DRAlert)-[:ALERT_FOR]->(x:DRCustomer)
WHERE alert.pocDataset = 'debt_rollover_liquidity_v1'
  AND alert.completeChainCount > 0
RETURN
  x.customerId AS customerX,
  alert.scoreBorrowers AS borrowerScore,
  alert.scoreChains AS chainScore,
  alert.scoreRepaymentSpeed AS repaymentSpeedScore,
  alert.scoreSupportRatio AS supportRatioScore,
  alert.scoreDisbursementSpeed AS disbursementSpeedScore,
  alert.scoreReturnRatio AS returnRatioScore,
  alert.scoreBorrowerDiversity AS borrowerDiversityScore,
  alert.riskScore AS totalRiskScore,
  alert.riskBand AS riskBand
ORDER BY totalRiskScore DESC;

// ----------------------------------------------------------------------------
// Q04. BANG CHI TIET BON CHUOI HOAN CHINH CUA X001
// Doi 'X001' bang ma X chon tu danh sach Q01 khi drill-down.
// ----------------------------------------------------------------------------
WITH 'X001' AS selectedX
MATCH (chain:DRDetectedChain)-[:SOURCE_CUSTOMER]->(x:DRCustomer {
  customerId:selectedX
})
MATCH (chain)-[:BORROWER]->(b:DRCustomer)
WHERE chain.pocDataset = 'debt_rollover_liquidity_v1'
  AND chain.chainLevel = 3
RETURN
  chain.chainId AS chainId,
  b.customerId AS borrowerId,
  b.name AS borrowerName,
  b.customerType AS borrowerType,
  chain.supportTransactionCount AS supportTransactionCount,
  round(chain.supportAmount / 1000000.0, 2) AS supportMillionVND,
  round(chain.balanceBeforeSupport / 1000000.0, 2)
    AS balanceBeforeMillionVND,
  round(chain.shortfall / 1000000.0, 2) AS shortfallMillionVND,
  chain.shortfallCoveragePct AS shortfallCoveragePct,
  round(chain.repaymentAmount / 1000000.0, 2) AS repaymentMillionVND,
  chain.supportRatioPct AS supportRatioPct,
  chain.hoursToRepayment AS hoursToRepayment,
  round(chain.disbursementAmount / 1000000.0, 2)
    AS disbursementMillionVND,
  round(chain.hoursToDisbursement / 24.0, 2) AS daysToDisbursement,
  chain.returnTransactionCount AS returnTransactionCount,
  round(chain.returnAmount / 1000000.0, 2) AS returnMillionVND,
  chain.returnRatioPct AS returnRatioPct,
  chain.chainLevelLabel AS chainLevel
ORDER BY chain.repaymentAt;

// ----------------------------------------------------------------------------
// Q05. GRAPH TONG THE X001 VA BON CHUOI B001-B004
// Tra ve node + relationship de Neo4j Browser hien tab Graph.
// Quan he UNOBSERVED_PATH chi la gia thuyet, khong duoc query phat hien su dung.
// ----------------------------------------------------------------------------
WITH 'X001' AS selectedX
MATCH (chain:DRDetectedChain)-[:SOURCE_CUSTOMER]->(x:DRCustomer {
  customerId:selectedX
})
MATCH (chain)-[:BORROWER]->(b:DRCustomer)
MATCH (chain)-[:USES_REPAYMENT]->(repayment:DRRepayment)
      -[repaid:REPAID]->(oldLoan:DRLoan)
MATCH (b)-[borrowedOld:BORROWER_OF]->(oldLoan)

MATCH (chain)-[:USES_SUPPORT_TRANSFER]->(supportTx:DRTransfer)
MATCH (x)-[ownsOut:OWNS]->(xOutAccount:DRAccount)
      -[sentSupport:SENT]->(supportTx)
      -[receivedSupport:RECEIVED_BY]->(bAccount:DRAccount)
MATCH (b)-[ownsB:OWNS]->(bAccount)

MATCH (chain)-[:USES_DISBURSEMENT]->(disbursement:DRDisbursement)
MATCH (newLoan:DRLoan)-[hasDisbursement:HAS_DISBURSEMENT]->(disbursement)
      -[paidTo:PAID_TO]->(disbursementAccount:DRAccount)
MATCH (b)-[borrowedNew:BORROWER_OF]->(newLoan)

MATCH (chain)-[:USES_RETURN_TRANSFER]->(returnTx:DRTransfer)
MATCH (returnSource:DRAccount)-[sentReturn:SENT]->(returnTx)
      -[receivedReturn:RECEIVED_BY]->(xReturnAccount:DRAccount)
MATCH (x)-[ownsReturn:OWNS]->(xReturnAccount)
OPTIONAL MATCH (disbursementAccount)-[unobserved:UNOBSERVED_PATH]->
               (returnSource)
RETURN
  x,
  ownsOut, xOutAccount,
  sentSupport, supportTx, receivedSupport,
  bAccount, ownsB, b,
  borrowedOld, oldLoan, repaid, repayment,
  borrowedNew, newLoan, hasDisbursement,
  disbursement, paidTo, disbursementAccount,
  unobserved, returnSource,
  sentReturn, returnTx, receivedReturn,
  xReturnAccount, ownsReturn;

// ----------------------------------------------------------------------------
// Q06. GRAPH TOM TAT: X O TRUNG TAM, CAC B VA CHUOI DAN XUAT XUNG QUANH
// Nhe hon Q05, phu hop man hinh trinh bay tong quan.
// ----------------------------------------------------------------------------
MATCH (alert:DRAlert {alertId:'ALT-2026-06-X001'})
      -[:ALERT_FOR]->(x:DRCustomer)
MATCH (alert)-[:INCLUDES_CHAIN]->(chain:DRDetectedChain)
      -[source:SOURCE_CUSTOMER]->(x)
MATCH (chain)-[borrowerRel:BORROWER]->(b:DRCustomer)
RETURN
  x, source, chain, borrowerRel, b;

// ----------------------------------------------------------------------------
// Q07. DRILL-DOWN MOT CHUOI CUA X001 VA B002 DUOI DANG GRAPH
// Doi selectedB de xem B001/B002/B003/B004.
// ----------------------------------------------------------------------------
WITH 'X001' AS selectedX, 'B002' AS selectedB
MATCH (chain:DRDetectedChain)-[:SOURCE_CUSTOMER]->(x:DRCustomer {
  customerId:selectedX
})
MATCH (chain)-[:BORROWER]->(b:DRCustomer {customerId:selectedB})
MATCH (chain)-[usesBalance:USES_BALANCE_SNAPSHOT]->
      (balance:DRBalanceSnapshot)
MATCH (chain)-[usesRepayment:USES_REPAYMENT]->(repayment:DRRepayment)
      -[repaid:REPAID]->(oldLoan:DRLoan)

MATCH (chain)-[usesSupport:USES_SUPPORT_TRANSFER]->(supportTx:DRTransfer)
MATCH (x)-[ownsOut:OWNS]->(xOutAccount:DRAccount)
      -[sentSupport:SENT]->(supportTx)
      -[receivedSupport:RECEIVED_BY]->(bAccount:DRAccount)
MATCH (b)-[ownsB:OWNS]->(bAccount)

OPTIONAL MATCH (chain)-[usesDisbursement:USES_DISBURSEMENT]->
               (disbursement:DRDisbursement)
OPTIONAL MATCH (newLoan:DRLoan)-[hasDisbursement:HAS_DISBURSEMENT]->
               (disbursement)-[paidTo:PAID_TO]->
               (disbursementAccount:DRAccount)
OPTIONAL MATCH (chain)-[usesReturn:USES_RETURN_TRANSFER]->
               (returnTx:DRTransfer)
OPTIONAL MATCH (returnSource:DRAccount)-[sentReturn:SENT]->(returnTx)
               -[receivedReturn:RECEIVED_BY]->
               (xReturnAccount:DRAccount)
OPTIONAL MATCH (disbursementAccount)-[unobserved:UNOBSERVED_PATH]->
               (returnSource)
RETURN
  x, ownsOut, xOutAccount,
  sentSupport, supportTx, receivedSupport,
  bAccount, ownsB, b,
  usesBalance, balance,
  usesRepayment, repayment, repaid, oldLoan,
  usesDisbursement, disbursement,
  newLoan, hasDisbursement, paidTo, disbursementAccount,
  unobserved, returnSource, sentReturn,
  returnTx, receivedReturn, xReturnAccount;

// ----------------------------------------------------------------------------
// Q08. TIMELINE BANG CUA MOT CHUOI
// Thu tu: ho tro -> thu no -> giai ngan -> tien quay lai.
// ----------------------------------------------------------------------------
WITH 'X001' AS selectedX, 'B002' AS selectedB
MATCH (chain:DRDetectedChain)-[:SOURCE_CUSTOMER]->(x:DRCustomer {
  customerId:selectedX
})
MATCH (chain)-[:BORROWER]->(b:DRCustomer {customerId:selectedB})
MATCH (chain)-[:USES_SUPPORT_TRANSFER]->(supportTx:DRTransfer)
WITH chain, x, b,
  collect({
    eventTime:supportTx.eventTime,
    eventType:'1_SUPPORT_X_TO_B',
    eventId:supportTx.transferId,
    amount:supportTx.amount,
    observation:'OBSERVED_BY_BANK_A'
  }) AS supportEvents
MATCH (chain)-[:USES_REPAYMENT]->(repayment:DRRepayment)
WITH chain, x, b, supportEvents + [{
  eventTime:repayment.eventTime,
  eventType:'2_REPAYMENT',
  eventId:repayment.repaymentId,
  amount:repayment.amount,
  observation:'OBSERVED_BY_BANK_A'
}] AS events
OPTIONAL MATCH (chain)-[:USES_DISBURSEMENT]->(disbursement:DRDisbursement)
WITH chain, x, b,
  CASE WHEN disbursement IS NULL THEN events ELSE events + [{
    eventTime:disbursement.eventTime,
    eventType:'3_DISBURSEMENT',
    eventId:disbursement.disbursementId,
    amount:disbursement.amount,
    observation:'OBSERVED_BY_BANK_A'
  }] END AS events
OPTIONAL MATCH (chain)-[:USES_RETURN_TRANSFER]->(returnTx:DRTransfer)
WITH chain, x, b, events,
  collect(CASE WHEN returnTx IS NULL THEN null ELSE {
    eventTime:returnTx.eventTime,
    eventType:'4_RETURN_TO_X',
    eventId:returnTx.transferId,
    amount:returnTx.amount,
    observation:'OBSERVED_INCOMING_AT_BANK_A'
  } END) AS returnEvents
UNWIND events + [e IN returnEvents WHERE e IS NOT NULL] AS event
RETURN
  x.customerId AS customerX,
  b.customerId AS borrower,
  event.eventTime AS eventTime,
  event.eventType AS eventType,
  event.eventId AS eventId,
  round(event.amount / 1000000.0, 2) AS amountMillionVND,
  event.observation AS observation
ORDER BY eventTime, eventType;

// ----------------------------------------------------------------------------
// Q09. CHAN DOAN CAC UNG VIEN NGUON TIEN TRUOC KHI AP DIEU KIEN SO DU
// Chung minh X002 khong bi loai do "ma ID", ma do B008-B010 da du so du.
// ----------------------------------------------------------------------------
WITH
  datetime('2026-06-01T00:00:00+07:00') AS monthStart,
  datetime('2026-07-01T00:00:00+07:00') AS nextMonthStart
MATCH (b:DRCustomer)-[:MADE_REPAYMENT]->(repayment:DRRepayment)
WHERE repayment.eventTime >= monthStart
  AND repayment.eventTime < nextMonthStart
  AND repayment.repaymentType IN [
    'PRINCIPAL_REPAYMENT',
    'FULL_SETTLEMENT',
    'LARGE_PRINCIPAL_REPAYMENT'
  ]
MATCH (b)-[:OWNS]->(:DRAccount)
      <-[:RECEIVED_BY]-(supportTx:DRTransfer)
      <-[:SENT]-(:DRAccount)
      <-[:OWNS]-(x:DRCustomer)
WHERE x <> b
  AND supportTx.eventTime < repayment.eventTime
  AND duration.inSeconds(supportTx.eventTime, repayment.eventTime).seconds
      <= 72 * 60 * 60
WITH DISTINCT x, b, repayment, supportTx
WITH
  x, b, repayment,
  sum(supportTx.amount) AS supportAmount,
  min(supportTx.eventTime) AS firstSupportAt
OPTIONAL MATCH (b)-[:HAS_BALANCE_SNAPSHOT]->(snapshot:DRBalanceSnapshot)
WHERE snapshot.asOf <= firstSupportAt
WITH x, b, repayment, supportAmount, firstSupportAt, snapshot
ORDER BY snapshot.asOf DESC
WITH
  x, b, repayment, supportAmount, firstSupportAt,
  head(collect(snapshot)) AS balanceSnapshot
WITH
  x, b, repayment, supportAmount, firstSupportAt, balanceSnapshot,
  repayment.amount - balanceSnapshot.availableBalance AS shortfall
RETURN
  x.customerId AS candidateX,
  b.customerId AS borrower,
  round(supportAmount / 1000000.0, 2) AS supportMillionVND,
  round(repayment.amount / 1000000.0, 2) AS repaymentMillionVND,
  round(balanceSnapshot.availableBalance / 1000000.0, 2)
    AS balanceBeforeMillionVND,
  round(shortfall / 1000000.0, 2) AS shortfallMillionVND,
  supportAmount >= 100000000 AS passMinAmount,
  supportAmount >= 0.30 * repayment.amount AS passSupportRatio,
  shortfall > 0 AS passHasShortfall,
  CASE
    WHEN shortfall <= 0 THEN false
    ELSE supportAmount >= 0.50 * shortfall
  END AS passShortfallCoverage
ORDER BY candidateX, borrower;

// ----------------------------------------------------------------------------
// Q10. DATA QUALITY / SO LUONG NODE THEO LABEL
// ----------------------------------------------------------------------------
MATCH (n:DRCustomer)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRCustomer' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRBank)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRBank' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRAccount)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRAccount' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRLoan)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRLoan' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRTransfer)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRTransfer' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRRepayment)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRRepayment' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRDisbursement)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRDisbursement' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRBalanceSnapshot)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRBalanceSnapshot' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRDetectedChain)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRDetectedChain' AS nodeLabel, count(n) AS nodeCount
UNION ALL
MATCH (n:DRAlert)
WHERE n.pocDataset = 'debt_rollover_liquidity_v1'
RETURN 'DRAlert' AS nodeLabel, count(n) AS nodeCount;

// ----------------------------------------------------------------------------
// Q11. CAC QUAN HE NGOAI BANK A PHAI DUOC GAN NOT_OBSERVED
// ----------------------------------------------------------------------------
MATCH (a:DRAccount)-[r:UNOBSERVED_PATH]->(b:DRAccount)
WHERE r.pocDataset = 'debt_rollover_liquidity_v1'
RETURN
  a.accountId AS disbursementDestination,
  'UNOBSERVED_PATH' AS relationshipType,
  r.displayLabel AS displayLabel,
  r.observedByBankA AS observedByBankA,
  r.confidence AS confidence,
  b.accountId AS observedReturnSource
ORDER BY r.chainRef, observedReturnSource;
