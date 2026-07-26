// ============================================================================
// QUERY DOC LAP, CHI DOC: TU TOAN BO THU NO -> TU TIM X DAT MUC 4
// Khong can chay file 03; khong tao DRDetectedChain/DRAlert.
// Khong APOC/GDS; khong input customerId; khong noi dung giao dich; khong CIF.
// ============================================================================

WITH
  datetime('2026-06-01T00:00:00+07:00') AS monthStart,
  datetime('2026-07-01T00:00:00+07:00') AS nextMonthStart
MATCH (b:DRCustomer)-[:MADE_REPAYMENT]->(repayment:DRRepayment)
WHERE repayment.pocDataset = 'debt_rollover_liquidity_v1'
  AND repayment.eventTime >= monthStart
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
  AND supportTx.observedByBankA = true
  AND supportTx.eventTime < repayment.eventTime
  AND duration.inSeconds(supportTx.eventTime, repayment.eventTime).seconds
      <= 72 * 60 * 60
WITH DISTINCT
  monthStart, nextMonthStart,
  x, b, repayment, supportTx
WITH
  monthStart, nextMonthStart,
  x, b, repayment,
  sum(supportTx.amount) AS supportAmount,
  min(supportTx.eventTime) AS firstSupportAt
WHERE supportAmount >= 100000000
  AND supportAmount >= 0.30 * repayment.amount

OPTIONAL MATCH (b)-[:HAS_BALANCE_SNAPSHOT]->(candidateSnapshot:DRBalanceSnapshot)
WHERE candidateSnapshot.asOf <= firstSupportAt
WITH
  monthStart, nextMonthStart,
  x, b, repayment, supportAmount, firstSupportAt,
  candidateSnapshot
ORDER BY candidateSnapshot.asOf DESC
WITH
  monthStart, nextMonthStart,
  x, b, repayment, supportAmount, firstSupportAt,
  head(collect(candidateSnapshot)) AS balanceSnapshot
WITH
  monthStart, nextMonthStart,
  x, b, repayment, supportAmount, firstSupportAt,
  balanceSnapshot,
  repayment.amount - balanceSnapshot.availableBalance AS shortfall,
  1.0 * supportAmount / repayment.amount AS supportRatio,
  duration.inSeconds(firstSupportAt, repayment.eventTime).seconds / 3600.0
    AS hoursToRepayment
WHERE balanceSnapshot IS NOT NULL
  AND shortfall > 0
  AND supportAmount >= 0.50 * shortfall

OPTIONAL MATCH (b)-[:RECEIVED_DISBURSEMENT]->
               (candidateDisbursement:DRDisbursement)
WHERE candidateDisbursement.eventTime > repayment.eventTime
  AND duration.inSeconds(
        repayment.eventTime,
        candidateDisbursement.eventTime
      ).seconds <= 7 * 24 * 60 * 60
  AND candidateDisbursement.amount >= 0.50 * repayment.amount
WITH
  monthStart, nextMonthStart,
  x, b, repayment, supportAmount, firstSupportAt,
  shortfall, supportRatio, hoursToRepayment,
  candidateDisbursement
ORDER BY candidateDisbursement.eventTime ASC
WITH
  monthStart, nextMonthStart,
  x, b, repayment, supportAmount, firstSupportAt,
  shortfall, supportRatio, hoursToRepayment,
  head(collect(candidateDisbursement)) AS disbursement
WHERE disbursement IS NOT NULL

OPTIONAL MATCH (x)-[:OWNS]->(:DRAccount)
      <-[:RECEIVED_BY]-(returnTx:DRTransfer)
      <-[:SENT]-(:DRAccount)
WHERE returnTx.observedByBankA = true
  AND returnTx.eventTime > disbursement.eventTime
  AND duration.inSeconds(disbursement.eventTime, returnTx.eventTime).seconds
      <= 7 * 24 * 60 * 60
WITH
  x, b, repayment, supportAmount, supportRatio, hoursToRepayment,
  disbursement,
  collect(DISTINCT returnTx) AS returnTxs
WITH
  x, b, repayment, supportAmount, supportRatio, hoursToRepayment,
  disbursement,
  reduce(total = 0, t IN returnTxs | total + t.amount) AS returnAmount
WITH
  x, b, repayment, supportAmount, supportRatio, hoursToRepayment,
  disbursement, returnAmount,
  1.0 * returnAmount / supportAmount AS returnRatio,
  duration.inSeconds(
    repayment.eventTime,
    disbursement.eventTime
  ).seconds / 3600.0 AS hoursToDisbursement
WHERE returnRatio >= 0.50
  AND returnRatio <= 1.50

WITH
  x,
  count(*) AS completeChainCount,
  count(DISTINCT b) AS distinctBorrowerCount,
  collect(DISTINCT b.customerType) AS borrowerTypes,
  sum(supportAmount) AS totalSupportAmount,
  sum(returnAmount) AS totalReturnAmount,
  avg(hoursToRepayment) AS avgHoursToRepayment,
  avg(supportRatio) AS avgSupportRatio,
  avg(hoursToDisbursement) AS avgHoursToDisbursement,
  avg(returnRatio) AS avgReturnRatio
WHERE completeChainCount >= 3
  AND distinctBorrowerCount >= 3
WITH
  x, completeChainCount, distinctBorrowerCount, borrowerTypes,
  totalSupportAmount, totalReturnAmount,
  avgHoursToRepayment, avgSupportRatio,
  avgHoursToDisbursement, avgReturnRatio,
  CASE
    WHEN distinctBorrowerCount >= 5 THEN 25
    WHEN distinctBorrowerCount = 4 THEN 20
    ELSE 15
  END AS borrowerScore,
  CASE
    WHEN completeChainCount >= 5 THEN 20
    WHEN completeChainCount = 4 THEN 16
    ELSE 12
  END AS chainScore,
  CASE
    WHEN avgHoursToRepayment < 6 THEN 15
    WHEN avgHoursToRepayment <= 24 THEN 12
    ELSE 8
  END AS repaymentSpeedScore,
  CASE
    WHEN avgSupportRatio >= 0.80 THEN 10
    WHEN avgSupportRatio >= 0.50 THEN 8
    ELSE 5
  END AS supportRatioScore,
  CASE
    WHEN avgHoursToDisbursement <= 24 THEN 10
    WHEN avgHoursToDisbursement <= 72 THEN 8
    ELSE 5
  END AS disbursementSpeedScore,
  CASE
    WHEN avgReturnRatio >= 0.80 AND avgReturnRatio <= 1.20 THEN 15
    WHEN avgReturnRatio >= 0.50 AND avgReturnRatio < 0.80 THEN 10
    WHEN avgReturnRatio > 1.20 AND avgReturnRatio <= 1.50 THEN 8
    ELSE 0
  END AS returnRatioScore,
  CASE
    WHEN 'INDIVIDUAL' IN borrowerTypes AND 'COMPANY' IN borrowerTypes THEN 5
    ELSE 3
  END AS diversityScore
WITH
  x, completeChainCount, distinctBorrowerCount,
  totalSupportAmount, totalReturnAmount,
  100.0 * totalReturnAmount / totalSupportAmount AS overallReturnRatioPct,
  borrowerScore + chainScore + repaymentSpeedScore
    + supportRatioScore + disbursementSpeedScore
    + returnRatioScore + diversityScore AS riskScore
RETURN
  x.customerId AS customerX,
  x.name AS customerName,
  x.customerType AS customerType,
  distinctBorrowerCount,
  completeChainCount,
  round(totalSupportAmount / 1000000000.0, 3)
    AS totalSupportBillionVND,
  round(totalReturnAmount / 1000000000.0, 3)
    AS totalReturnBillionVND,
  round(overallReturnRatioPct, 2) AS overallReturnRatioPct,
  riskScore,
  CASE
    WHEN riskScore >= 80 THEN 'HIGH'
    WHEN riskScore >= 60 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS riskBand,
  'MỨC 4 - DẤU HIỆU CHUYÊN CUNG CẤP TIỀN ĐẢO NỢ' AS alertLevel
ORDER BY riskScore DESC, customerX;

