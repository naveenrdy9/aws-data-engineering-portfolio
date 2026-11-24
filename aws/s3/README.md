# LESSON 1 - S3 + Parquet + Athena - AAA Insurance
## Use sample data you already have: policies.csv (100 rows), claims.json (60 rows)

## Goal in 1 line
Raw CSV ni S3 lo petti, Athena lo query chesthe slow + costly. Ade data ni Parquet + Partition cheste fast + cheap - idi nuvve chesi chudali.

## PART A - VS Code lo setup (5 min)
1. VS Code open chesi, nenu ichina folder `aws-data-engineering-portfolio` open cheyi.
2. Files chudu: data/raw/policies.csv, code/terraform/main.tf, code/athena/athena_queries.sql
   (folder peru `aws-data-engineering-portfolio` - zip lo ade peru untundi)
3. Terminal lo:
```bash
aws --version
terraform --version
python3 --version
```
Error vasthe screenshot pettu, nenu fix chepthanu.

## PART B - S3 Bucket - Terraform way (companies lo idi)
File: code/terraform/main.tf - bucket name comes from `var.env`, so do NOT edit
the file to rename the bucket. Run with `env=dev` first:
```bash
cd code/terraform
terraform init
terraform fmt; terraform validate
terraform plan -var env=dev
terraform apply -var env=dev
# Type yes when asked. Bucket create avuthundi.
```
If `apply` says `BucketAlreadyExists` for `aaa-insurance-raw-dev` (bucket names
are global), use a unique suffix instead - `terraform apply -var env=dev-<nee-peru>-2026`
- and use that same suffix in the `aws s3 cp` commands below and in
`code/glue/bronze_to_silver.py` (it hard-codes the `-dev` bucket names).
Console way (learning kosam): AWS Console > S3 > Create bucket > name > Block Public Access ON > Create.
Terraform lo chesthe Git lo proof untundi, Console lo chesthe undadu - ade difference.

## PART C - Upload Bronze
```bash
aws s3 cp ../../data/raw/policies.csv s3://<nee-bucket>/policies/year=2026/month=11/day=24/policies.csv
aws s3 cp ../../data/raw/claims.json s3://<nee-bucket>/claims/year=2026/month=11/day=24/claims.json
aws s3 ls s3://<nee-bucket>/policies/year=2026/month=11/day=24/ --recursive
```
Console way: S3 > bucket > Upload > policies.csv select > Upload.

## PART D - Athena - First query (slow way - chusi nerchuko)
Athena Console > Query Editor > Database create:
```sql
CREATE DATABASE IF NOT EXISTS aaa_insurance_dev;
```
External table on raw CSV:
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS aaa_insurance_dev.raw_policies_csv (
  policy_id string, customer_id string, product string, state string,
  premium double, start_date string, status string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION 's3://<nee-bucket>/policies/year=2026/month=11/day=24/'
TBLPROPERTIES ('skip.header.line.count'='1');
```
Run:
```sql
SELECT state, COUNT(*) c, SUM(premium) total FROM aaa_insurance_dev.raw_policies_csv GROUP BY state;
```
Athena result kindha chudu: Data scanned - chinna data kabatti KBs lo untundi, kani real lo GBs/TBs avuthundi. Cost = $5/TB.

## PART E - Fast way - CTAS to Parquet
```sql
CREATE TABLE aaa_insurance_dev.silver_policies_parquet
WITH (format='PARQUET', external_location='s3://<nee-bucket>/silver/policies/', partitioned_by=ARRAY['state'])
AS SELECT policy_id, customer_id, product, premium, start_date, status, state FROM aaa_insurance_dev.raw_policies_csv;
```
Ippudu ee query run cheyi:
```sql
SELECT state, SUM(premium) FROM aaa_insurance_dev.silver_policies_parquet WHERE state='TX' GROUP BY state;
```
Ee query lo Athena TX partition matrame chaduvuthundi. Interview / job lo cheppalsina point ide: Partition Pruning + Columnar = cost down.

## Your Homework - ee 3 answers naku pettu
1. Bucket name enti? Upload ayyinda - `aws s3 ls` output enti?
2. Athena slow query lo Data scanned entha? Fast query lo entha?
3. Edanna error vasthe exact error message + screenshot pettu.

Next Lesson: Glue Crawler + Glue Job Bronze->Silver with same data.
