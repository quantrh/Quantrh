// ============================================================================
// DEMO PHAT HIEN KHACH HANG CUNG CAP THANH KHOAN DAO NO
// File 06 - Kiem tra nghiem thu sau khi chay file 03
// Ket qua mong doi: moi dong co passed = true.
// ============================================================================

// T01 - Tu dong tim duy nhat X001 o Muc 4.
OPTIONAL MATCH (a:DRAlert)
WHERE a.pocDataset = 'debt_rollover_liquidity_v1'
  AND a.analysisMonth = '2026-06'
  AND a.alertLevel = 4
WITH collect(a.customerId) AS ids
RETURN
  'T01_AUTO_FIND_LEVEL4' AS testId,
  size(ids) = 1 AND head(ids) = 'X001' AS passed,
  'count=' + toString(size(ids))
    + '; first=' + coalesce(head(ids), 'null') AS actual,
  '[X001]' AS expected

UNION ALL

// T02 - X001 co 4 chuoi hoan chinh voi 4 B.
OPTIONAL MATCH (c:DRDetectedChain)-[:SOURCE_CUSTOMER]->
               (:DRCustomer {customerId:'X001'})
WHERE c.analysisMonth = '2026-06'
  AND c.chainLevel = 3
WITH collect(c) AS chains
RETURN
  'T02_FOUR_CHAINS_FOUR_BORROWERS' AS testId,
  size(chains) = 4
    AND size([id IN ['B001','B002','B003','B004']
              WHERE any(c IN chains WHERE c.borrowerId = id)]) = 4
    AS passed,
  'chains=' + toString(size(chains))
    + '; matchedBorrowers='
    + toString(size([id IN ['B001','B002','B003','B004']
                     WHERE any(c IN chains WHERE c.borrowerId = id)]))
    AS actual,
  'chains=4; borrowers=[B001,B002,B003,B004]' AS expected

UNION ALL

// T03 - So tien cua 4 chuoi X001 dung kich ban.
OPTIONAL MATCH (c:DRDetectedChain)-[:SOURCE_CUSTOMER]->
               (:DRCustomer {customerId:'X001'})
WHERE c.analysisMonth = '2026-06'
  AND c.chainLevel = 3
WITH collect(c) AS chains
RETURN
  'T03_X001_CHAIN_AMOUNTS' AS testId,
  size(chains) = 4
    AND all(c IN chains WHERE
      (c.borrowerId = 'B001'
        AND c.supportAmount = 800000000
        AND c.repaymentAmount = 900000000
        AND c.returnAmount = 820000000)
      OR
      (c.borrowerId = 'B002'
        AND c.supportAmount = 1200000000
        AND c.supportTransactionCount = 3
        AND c.repaymentAmount = 1400000000
        AND c.returnAmount = 1100000000)
      OR
      (c.borrowerId = 'B003'
        AND c.supportAmount = 600000000
        AND c.repaymentAmount = 1000000000
        AND c.returnAmount = 450000000)
      OR
      (c.borrowerId = 'B004'
        AND c.supportAmount = 2000000000
        AND c.repaymentAmount = 2300000000
        AND c.returnAmount = 2100000000)
    ) AS passed,
  'chainCount=' + toString(size(chains)) AS actual,
  'B001-B004 match the approved scenario' AS expected

UNION ALL

// T04 - X001/X003/X004/X005 duoc phan loai 4/3/1/2.
OPTIONAL MATCH (a:DRAlert)-[:ALERT_FOR]->(x:DRCustomer)
WHERE x.customerId IN ['X001','X003','X004','X005']
WITH collect({id:x.customerId, level:a.alertLevel}) AS rows
RETURN
  'T04_CONTROL_CLASSIFICATIONS' AS testId,
  size(rows) = 4
    AND any(r IN rows WHERE r.id = 'X001' AND r.level = 4)
    AND any(r IN rows WHERE r.id = 'X003' AND r.level = 3)
    AND any(r IN rows WHERE r.id = 'X004' AND r.level = 1)
    AND any(r IN rows WHERE r.id = 'X005' AND r.level = 2)
    AS passed,
  'matched=' + toString(size(rows))
    + '; X001L4='
    + toString(size([r IN rows WHERE r.id = 'X001' AND r.level = 4]))
    + '; X003L3='
    + toString(size([r IN rows WHERE r.id = 'X003' AND r.level = 3]))
    + '; X004L1='
    + toString(size([r IN rows WHERE r.id = 'X004' AND r.level = 1]))
    + '; X005L2='
    + toString(size([r IN rows WHERE r.id = 'X005' AND r.level = 2]))
    AS actual,
  '[X001:4, X003:3, X004:1, X005:2]' AS expected

UNION ALL

// T05 - X002 bi loai vi B da du so du.
MATCH (x:DRCustomer {customerId:'X002'})
OPTIONAL MATCH (a:DRAlert)-[:ALERT_FOR]->(x)
WITH count(a) AS alertCount
RETURN
  'T05_X002_EXCLUDED' AS testId,
  alertCount = 0 AS passed,
  'alertCount=' + toString(alertCount) AS actual,
  'alertCount=0' AS expected

UNION ALL

// T06 - Diem X001 theo thang diem chot la 86.
OPTIONAL MATCH (a:DRAlert {alertId:'ALT-2026-06-X001'})
WITH head(collect(a)) AS alert
RETURN
  'T06_X001_SCORE' AS testId,
  alert.riskScore = 86
    AND alert.distinctBorrowerCount = 4
    AND alert.completeChainCount = 4 AS passed,
  'score=' + toString(alert.riskScore)
    + '; borrowers=' + toString(alert.distinctBorrowerCount)
    + '; chains=' + toString(alert.completeChainCount) AS actual,
  'score=86; borrowers=4; chains=4' AS expected

UNION ALL

// T07 - Khong su dung thu lai/phi/thu no nho trong chuoi.
OPTIONAL MATCH (c:DRDetectedChain)-[:USES_REPAYMENT]->(r:DRRepayment)
WHERE c.pocDataset = 'debt_rollover_liquidity_v1'
WITH collect(DISTINCT r.repaymentType) AS types
RETURN
  'T07_EXCLUDED_REPAYMENT_TYPES' AS testId,
  all(t IN types WHERE t IN [
    'PRINCIPAL_REPAYMENT',
    'FULL_SETTLEMENT',
    'LARGE_PRINCIPAL_REPAYMENT'
  ]) AS passed,
  'distinctAllowedTypeCount=' + toString(size(types)) AS actual,
  'Only principal/full/large-principal types' AS expected

UNION ALL

// T08 - Moi duong di ngoai Bank A deu duoc danh dau khong quan sat.
OPTIONAL MATCH ()-[r:UNOBSERVED_PATH]->()
WHERE r.pocDataset = 'debt_rollover_liquidity_v1'
WITH collect(r) AS rels
RETURN
  'T08_UNOBSERVED_PATHS' AS testId,
  size(rels) = 8
    AND all(r IN rels WHERE r.observedByBankA = false)
    AND all(r IN rels WHERE r.confidence = 'HYPOTHESIS_ONLY') AS passed,
  'count=' + toString(size(rels)) AS actual,
  'count=8; all observedByBankA=false' AS expected

UNION ALL

// T09 - Khong co quan he truc tiep/CIF giua X001 va B001-B004.
MATCH (x:DRCustomer {customerId:'X001'})
OPTIONAL MATCH (x)-[r]-(b:DRCustomer)
WHERE b.customerId IN ['B001','B002','B003','B004']
WITH count(r) AS directRelationshipCount
RETURN
  'T09_NO_CIF_DEPENDENCY' AS testId,
  directRelationshipCount = 0 AS passed,
  'directRelationshipCount=' + toString(directRelationshipCount) AS actual,
  'directRelationshipCount=0' AS expected;
