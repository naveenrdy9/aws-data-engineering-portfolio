# Live Lab - S3 -> Glue -> Athena - AAA Insurance sample data
## Technical demonstration - use your OWN basic AWS account, small sample data only. Watch cost.
Sample files already in workspace: data/raw/policies.csv (100 rows), data/raw/claims.json (60 rows, nested incident)

## Step 0 - Safety
Use a unique bucket name, us-east-1, delete data after lab. Never use prod bucket names.

## Step 1 - Terraform (preferred in companies) - file: code/terraform/main.tf
```bash
terraform init
terraform fmt; terraform validate
terraform plan -var env=dev
terraform apply -var env=dev   # creates S3 raw bucket, Glue DB, Athena Workgroup with 10GB cutoff
```
Console alternative (learning only): S3 > Create bucket > Block Public Access ON > Versioning ON > SSE-KMS.

## Step 2 - Upload Bronze
```bash
aws s3 cp data/raw/policies.csv s3://<your-bucket>-raw-dev/policies/year=2026/month=11/day=24/
aws s3 cp data/raw/claims.json  s3://<your-bucket>-raw-dev/claims/year=2026/month=11/day=24/
```
Bronze = raw as-is. No cleaning here.

## Step 3 - Glue Crawler -> Data Catalog
Glue > Crawlers > Create: database aaa_insurance_dev, S3 path .../policies/, IAM role with S3 read + Glue write.
Run crawler. Check Tables: schema inferred. If a new partition arrives, run `MSCK REPAIR TABLE silver_policies;` or re-run crawler.

## Step 4 - Glue Job: Bronze -> Silver (code/glue/bronze_to_silver.py)
What it does, in order:
1. Read CSV with header, read JSON (nested incident stays as struct)
2. Clean: trim policy_id, upper state, cast premium to Decimal(10,2), to_date(start_date), filter premium>0, dropDuplicates
3. Flatten claims: incident.type -> incident_type, incident.city -> incident_city
4. Write Parquet, partitionBy(state) for policies, partitionBy(status) for claims, Snappy
Why: Parquet is columnar. Athena then scans only needed columns/partitions.
Run in Glue Studio / Jobs, check CloudWatch logs, check row counts printed at end.

## Step 5 - Gold
Join claims_clean to policies_clean on policy_id, groupBy(state, incident_type), sum(claim_amount), count(claim_id).
Write to s3://...-gold-dev/claims_by_state/ as Parquet.

## Step 6 - Athena (code/athena/athena_queries.sql)
Workgroup: aaa-analytics-dev, output to s3://...-athena-results-dev/
Good query (partition pruning):
```sql
SELECT state, SUM(premium) AS total_premium, COUNT(*) AS policies
FROM silver_policies WHERE state='TX' GROUP BY state;
```
Bad query to avoid: SELECT * FROM raw CSV with no WHERE - scans everything, $5/TB.
CTAS to convert once:
```sql
CREATE TABLE silver_policies_parquet WITH (format='PARQUET', external_location='s3://.../', partitioned_by=ARRAY['state']) AS SELECT * FROM raw_policies_csv;
```

## Step 7 - Validate (QA in miniature)
- Row counts: Bronze 100 policies vs Silver ? (duplicates/nulls removed)
- Sum check: SUM(premium) Bronze vs Silver - explain any difference
- Null check: policy_id IS NULL = 0
- Re-run job: same output? Idempotent? Overwrite mode means yes for this demo.

## BNY Mellon - same lab, different tables
Replace policies->accounts, claims->transactions (see doc §9.3: TX1001, ACC001, DEPOSIT, 15000, USD, SETTLED).
Partition by business_date + fund/account, same Bronze/Silver/Gold steps.
