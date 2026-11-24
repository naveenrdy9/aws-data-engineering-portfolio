-- ============================================================================
-- LESSON 3 - Redshift Tuning (Performance Optimisation)
-- AAA Insurance, representative scenario - NOT a real client's production data
-- Run this ONLY after Lesson 2: Silver Parquet must already be in S3.
--   s3://aaa-insurance-silver-dev/policies/   (partitioned by state)
--   s3://aaa-insurance-silver-dev/claims/    (partitioned by status)
-- Replace <nee-bucket>, <nee-iam-role-arn> and <schema> with your own values.
-- Redshift Serverless workgroup lo run cheyochu - cluster manage cheyalsina
-- pani ledu. Workgroup pause/delete cheyadam marchipoku - cost vasthundi.
-- Ee file lo timings / numbers emi levu - before/after nuvve measure chesi
-- docs/10-lesson3-redshift-tuning.md lo unna benchmark table lo rayali.
-- ============================================================================

-- 0. SETUP - schema (dev lo matrame, prod lo kaadu)
CREATE SCHEMA IF NOT EXISTS aaa_dev;

-- ============================================================================
-- 1. BAD vs GOOD - same data, same query, different table design
-- BAD: no DISTKEY, no SORTKEY - Redshift data ni anni nodes ki move chesthundi
-- GOOD: join column = DISTKEY, filter column = SORTKEY - data move avvadhu,
--       unwanted blocks skip avuthayi
-- ============================================================================

-- BAD tables (baseline - measure this first)
CREATE TABLE IF NOT EXISTS aaa_dev.policies_bad (
  policy_id   VARCHAR(20),
  customer_id VARCHAR(20),
  product     VARCHAR(20),
  state       VARCHAR(2),
  premium     DECIMAL(10,2),
  start_date  DATE,
  status      VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS aaa_dev.claims_bad (
  claim_id      VARCHAR(20),
  policy_id     VARCHAR(20),
  claim_amount  DECIMAL(12,2),
  claim_date    DATE,
  status        VARCHAR(20),
  incident_type VARCHAR(30),
  incident_city VARCHAR(50)
);

-- GOOD tables (tuned - same columns, different storage layout)
CREATE TABLE IF NOT EXISTS aaa_dev.policies_good (
  policy_id   VARCHAR(20),
  customer_id VARCHAR(20),
  product     VARCHAR(20),
  state       VARCHAR(2),
  premium     DECIMAL(10,2),
  start_date  DATE,
  status      VARCHAR(20)
)
DISTSTYLE KEY
DISTKEY (policy_id)
SORTKEY (start_date);

CREATE TABLE IF NOT EXISTS aaa_dev.claims_good (
  claim_id      VARCHAR(20),
  policy_id     VARCHAR(20),
  claim_amount  DECIMAL(12,2),
  claim_date    DATE,
  status        VARCHAR(20),
  incident_type VARCHAR(30),
  incident_city VARCHAR(50)
)
DISTSTYLE KEY
DISTKEY (policy_id)
SORTKEY (claim_date);

-- ============================================================================
-- 2. LOAD - COPY from Silver Parquet (S3 -> Redshift, no CSV re-scan)
-- IAM role ki S3 read permission undali - lekapothe Platform/IAM team ni adugu.
-- Parquet lo column names table columns tho match avvali.
-- ============================================================================

COPY aaa_dev.policies_bad
FROM 's3://aaa-insurance-silver-dev/policies/'
IAM_ROLE '<nee-iam-role-arn>'
FORMAT AS PARQUET;

COPY aaa_dev.claims_bad
FROM 's3://aaa-insurance-silver-dev/claims/'
IAM_ROLE '<nee-iam-role-arn>'
FORMAT AS PARQUET;

COPY aaa_dev.policies_good
FROM 's3://aaa-insurance-silver-dev/policies/'
IAM_ROLE '<nee-iam-role-arn>'
FORMAT AS PARQUET;

COPY aaa_dev.claims_good
FROM 's3://aaa-insurance-silver-dev/claims/'
IAM_ROLE '<nee-iam-role-arn>'
FORMAT AS PARQUET;

-- COPY tarvatha statistics update cheyali - lekapothe planner wrong plan isthundi
ANALYZE aaa_dev.policies_bad;
ANALYZE aaa_dev.claims_bad;
ANALYZE aaa_dev.policies_good;
ANALYZE aaa_dev.claims_good;

-- ============================================================================
-- 3. QA FIRST - bad vs good lo counts / sums SAME undali (numbers marakudadu)
-- Okavela mismatch unte tuning kadu - load lo tappu, mundu adi fix cheyi.
-- ============================================================================

SELECT 'policies_bad'  AS tbl, COUNT(*) AS rows, SUM(premium) AS total_premium FROM aaa_dev.policies_bad
UNION ALL
SELECT 'policies_good', COUNT(*), SUM(premium) FROM aaa_dev.policies_good
UNION ALL
SELECT 'claims_bad',   COUNT(*), SUM(claim_amount) FROM aaa_dev.claims_bad
UNION ALL
SELECT 'claims_good',  COUNT(*), SUM(claim_amount) FROM aaa_dev.claims_good;

-- ============================================================================
-- 4. THE QUERY - Texas claims by state + incident type (DE-1245 pattern)
-- BAD version: SELECT * lanti waste ledu kani, table design valla slow.
-- ============================================================================

-- 4a. BAD - run cheyi, time note chesko (SVL_QLOG lo chudu, section 5)
SELECT p.state, c.incident_type,
       SUM(c.claim_amount) AS total_claim_amount,
       COUNT(*) AS claim_count
FROM aaa_dev.claims_bad c
JOIN aaa_dev.policies_bad p ON c.policy_id = p.policy_id
WHERE c.claim_date >= DATE '2026-11-01'
GROUP BY p.state, c.incident_type
ORDER BY total_claim_amount DESC;

-- 4b. EXPLAIN - plan chudu: DS_BCAST_INNER / DS_DIST_ALL_INNER unte data move avuthundi
EXPLAIN
SELECT p.state, c.incident_type,
       SUM(c.claim_amount) AS total_claim_amount,
       COUNT(*) AS claim_count
FROM aaa_dev.claims_bad c
JOIN aaa_dev.policies_bad p ON c.policy_id = p.policy_id
WHERE c.claim_date >= DATE '2026-11-01'
GROUP BY p.state, c.incident_type;

-- 4c. GOOD - ade query, tuned tables meedha
SELECT p.state, c.incident_type,
       SUM(c.claim_amount) AS total_claim_amount,
       COUNT(*) AS claim_count
FROM aaa_dev.claims_good c
JOIN aaa_dev.policies_good p ON c.policy_id = p.policy_id
WHERE c.claim_date >= DATE '2026-11-01'
GROUP BY p.state, c.incident_type
ORDER BY total_claim_amount DESC;

-- 4d. EXPLAIN good - DS_DIST_NONE vasthe join ki data move avvaledu ani ardham
EXPLAIN
SELECT p.state, c.incident_type,
       SUM(c.claim_amount) AS total_claim_amount,
       COUNT(*) AS claim_count
FROM aaa_dev.claims_good c
JOIN aaa_dev.policies_good p ON c.policy_id = p.policy_id
WHERE c.claim_date >= DATE '2026-11-01'
GROUP BY p.state, c.incident_type;

-- ============================================================================
-- 5. MEASURE - guess cheyaku, SVL_QLOG lo actual elapsed chudu
-- elapsed microseconds lo untundi - / 1000000.0 chesthe seconds vasthundi.
-- Query ni 3 sarlu run chesi middle value teesko (first run cache cold untundi).
-- ============================================================================

SELECT query,
       elapsed / 1000000.0 AS seconds,
       starttime
FROM SVL_QLOG
WHERE starttime >= CURRENT_DATE
ORDER BY elapsed DESC
LIMIT 10;

-- ============================================================================
-- 6. GOLD - business-ready aggregate (dashboard ki direct ga vade table)
-- DISTKEY(state): dashboard query state tho filter chesthundi kabatti.
-- SORTKEY(total_claim_amount): top states fast ga vasthayi.
-- ============================================================================

CREATE TABLE IF NOT EXISTS aaa_dev.gold_claims_by_state (
  state              VARCHAR(2),
  incident_type      VARCHAR(30),
  total_claim_amount DECIMAL(14,2),
  claim_count        BIGINT
)
DISTSTYLE KEY
DISTKEY (state)
SORTKEY (total_claim_amount);

-- Full refresh (chinna lab data kosam ok - prod lo section 7 incremental vadali)
TRUNCATE aaa_dev.gold_claims_by_state;

INSERT INTO aaa_dev.gold_claims_by_state
SELECT p.state, c.incident_type,
       SUM(c.claim_amount), COUNT(*)
FROM aaa_dev.claims_good c
JOIN aaa_dev.policies_good p ON c.policy_id = p.policy_id
GROUP BY p.state, c.incident_type;

SELECT * FROM aaa_dev.gold_claims_by_state
ORDER BY total_claim_amount DESC LIMIT 10;

-- ============================================================================
-- 7. INCREMENTAL - prod lo full reload cheyaku, kotha date matrame load cheyi
-- Pattern: staging table lo kotha batch -> delete old rows for that date ->
-- insert new rows. COPY + DELETE + INSERT - oka transaction lo cheyi.
-- (Lab lo idi run cheyalsina avasaram ledu - pattern nerchukovadaniki matrame.)
-- ============================================================================

-- CREATE TABLE aaa_dev.claims_staging (LIKE aaa_dev.claims_good);
-- COPY aaa_dev.claims_staging FROM 's3://aaa-insurance-silver-dev/claims/claim_date=2026-11-24/'
-- IAM_ROLE '<nee-iam-role-arn>' FORMAT AS PARQUET;
-- BEGIN;
-- DELETE FROM aaa_dev.claims_good WHERE claim_date = DATE '2026-11-24';
-- INSERT INTO aaa_dev.claims_good SELECT * FROM aaa_dev.claims_staging;
-- COMMIT;
-- VACUUM DELETE ONLY aaa_dev.claims_good;  -- deleted rows space clean cheyali
-- ANALYZE aaa_dev.claims_good;

-- ============================================================================
-- 8. CLEANUP (lab tarvatha) - cost aagadaniki
-- DROP TABLE aaa_dev.policies_bad;  DROP TABLE aaa_dev.claims_bad;
-- DROP TABLE aaa_dev.policies_good; DROP TABLE aaa_dev.claims_good;
-- DROP TABLE aaa_dev.gold_claims_by_state;
-- Redshift Serverless workgroup ni pause/delete cheyi.
-- ============================================================================
