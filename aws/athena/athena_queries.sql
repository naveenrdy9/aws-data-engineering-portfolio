-- AAA Insurance - Athena queries (use on Silver Parquet, NOT raw CSV)
-- Cost rule: Athena = $5 per TB scanned. Partition + column pruning = 90% saving.

-- 1. Fast: partition pruning + only 2 columns
SELECT state, SUM(premium) AS total_premium, COUNT(*) AS policies
FROM silver_policies
WHERE state = 'TX'            -- scans ONLY TX partition
GROUP BY state;

-- 2. Claims by incident type - Gold table, tiny scan
SELECT state, incident_type, total_claim_amount, claim_count
FROM gold_claims_by_state
ORDER BY total_claim_amount DESC LIMIT 10;

-- 3. SLOW / BAD (interview trap): SELECT * on raw CSV, no partition
-- SELECT * FROM raw_policies_csv WHERE premium > 1000;
-- Why bad: scans full file, all columns, no predicate pushdown.

-- 4. CTAS: convert CSV -> Parquet once, query Parquet forever
CREATE TABLE silver_policies_parquet
WITH (format='PARQUET', external_location='s3://aaa-insurance-silver-dev/policies-ctas/',
      partitioned_by=ARRAY['state'])
AS SELECT * FROM raw_policies_csv;

-- 5. BNY Mellon example - same pattern, different domain
-- Fund NAV: partition by valuation_date, fund_id
SELECT fund_id, valuation_date, SUM(nav_amount) AS total_nav
FROM bny_silver_nav
WHERE valuation_date = DATE '2026-11-24'
GROUP BY fund_id, valuation_date;
