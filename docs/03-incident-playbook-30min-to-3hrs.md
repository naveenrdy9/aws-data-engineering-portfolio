# Incident Playbook - Pipeline 30 min -> 3 hours
## Representative scenario for training. Do not present as a specific client incident unless verified.

## First 10 minutes - Confirm, do not fix blindly
1. Which pipeline, business date, run ID, SLA? Who is impacted?
2. Is it still running or failed? Check Airflow / Glue Job Runs / Step Functions.
3. Tell Lead + Prod Support in writing: "Job X, business date Y, started HH:MM, still running at 3h vs normal 30m, SLA HH:MM."
4. Do NOT kill / rerun in prod without approval.

## Next 30 minutes - Compare with last good run
- Input volume: rows today vs yesterday? File count? Many small files?
  - Example: 10,000 files x 1 MB = slow. Fix later: coalesce to ~128 MB files.
- Schema change? New column? Partition missing? Check Glue Catalog / MSCK REPAIR.
- Upstream late? Source file arrived late?
- Check CloudWatch + Spark UI: which stage is stuck? Shuffle size? One task running 2h while others finish in 2 min = DATA SKEW.

## Data Skew - the Performance Optimisation answer
Example AAA: 80% claims are TX. GroupBy(state) puts TX on one executor.
Checks: Spark UI > Stages > Task time distribution, shuffle read/write.
Fixes (in DEV first, test with same data):
- Broadcast Join for small dimension: `broadcast(policies_df)` when policies < ~10 MB / 200 MB threshold in your env.
- Salting for hot key: add salt 0-9 to TX, group, then group again.
- Repartition: `df.repartition(200, "policy_id")` - not too many, not too few.
- Filter early, select only needed columns, partition pruning in Athena/Spark.
- Avoid `SELECT *`, avoid cross join, avoid UDF on large data if a native function exists.

## Other common causes
- Small files: use OPTIMIZE / VACUUM (Delta/Iceberg) or coalesce on write, or CTAS to Parquet.
- Shuffle: too many partitions, or too few executors. Check Glue DPUs / EMR cores, memory.
- Athena slow: no partition filter, CSV not Parquet, SELECT *, no workgroup limit. Fix: Parquet + partition + CTAS + result reuse.
- Snowflake slow (if used): Query Profile - check warehouse size, clustering, pruning, spilling.
- Databricks slow: Spark UI, Photon, OPTIMIZE, Z-order, caching - only after checking job run logs.

## Recovery - only with approval
1. Agree fix with Lead, test in DEV/QA with same business date.
2. Approved rerun / backfill: idempotent? Will it duplicate? Use overwrite for that partition/date only.
3. Validate: row counts, SUM(premium), SUM(claim_amount), duplicate check, Gold vs Silver reconciliation.
4. Communicate: fixed, validated, downstream dashboards OK.
5. Close ticket with: Root Cause, Evidence (run IDs, log links, before/after times), Fix, Prevention (alarm if job > 60 min, file-size check, skew monitor).

## Measurable result - how to state it truthfully for YOUR lab
Lab example format: "In my lab, Glue job went from X min to Y min after partitioning by state and converting CSV to Parquet, scanned data in Athena fell from A GB to B GB."
Do not invent prod numbers for AAA/BNY.

## Escalation
- 30 min over SLA: inform Lead
- Data wrong / money impact (BNY NAV, AAA claim totals): escalate immediately to Lead + Data Owner + Prod Support, stop downstream if told.
- Permission error: IAM / Security ticket with exact error, role, resource ARN, time. Do not share credentials.
