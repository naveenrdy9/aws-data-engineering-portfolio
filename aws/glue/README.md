# LESSON 2 - Glue: Bronze -> Silver -> Gold (ready after Lesson 1)
## Do this only after Lesson 1 upload is done and Athena raw query works.

## What Glue does
Glue is the ETL service. You give it a Python/PySpark script, it runs Spark for you, no cluster to manage.
Your script is already in code/glue/bronze_to_silver.py

## Step 1 - Glue Crawler (Catalog)
Glue Console > Crawlers > Create crawler
- Name: aaa-policies-crawler-dev
- Data source: S3 path s3://<bucket>/policies/
- IAM role: create new / use existing with S3 read + Glue write (ask Platform if in company)
- Database: aaa_insurance_dev (create if missing)
- Run crawler. Check Tables: raw_policies_csv schema appears.

If a new date partition arrives: run MSCK REPAIR TABLE or re-run crawler.

## Step 2 - Glue Job
Glue Console > Jobs > Create job
- Type: Spark, Glue 4.0, Python 3
- Script: upload / paste bronze_to_silver.py, or S3 path to script
- Worker type: G.1X, Number of workers: 5 for this small lab (in prod, tune by data size)
- Job parameters: --JOB_NAME, --TempDir s3://<bucket>/temp/
- Run job. Watch: Run status, CloudWatch logs link.

## Step 3 - What the script does (read it line by line in VS Code)
1. Read Bronze CSV + JSON
2. Clean: trim, upper state, cast premium Decimal, to_date, filter premium>0, dropDuplicates
3. Flatten claims.json: incident.type -> incident_type
4. Write Silver Parquet partitioned by state / status
5. Gold: join + groupBy(state, incident_type), sum claim_amount, count claims

## Step 4 - Validate in Athena
```sql
SELECT COUNT(*) FROM silver_policies; -- expect 100 minus duplicates/nulls
SELECT state, COUNT(*) FROM silver_policies GROUP BY state;
SELECT * FROM gold_claims_by_state ORDER BY total_claim_amount DESC LIMIT 5;
```
If counts mismatch Bronze, check the filter step - that is your QA.

## Step 5 - If job is slow (preview of incident playbook)
Check Glue Job Run > Logs > Spark UI link. Look for one task taking much longer = skew.
For now, just note the run time. Lesson 3 will tune it.
