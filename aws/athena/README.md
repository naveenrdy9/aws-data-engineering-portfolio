# Athena — one folder, full lesson
## What is Athena?
S3 lo unna file ni database laaga SQL tho query chesey serverless service. Server ledu.
Cost: $5 per TB scanned.

## Files in this folder
- `athena_queries.sql` — Good vs Bad queries, CTAS, Workgroup example
- Sample data: `../s3/sample-data/policies.csv`, `claims.json`

## AAA first, BNY second
- AAA: `SELECT state, SUM(claim_amount) FROM claims WHERE state='TX'`
- BNY: same pattern on transactions / NAV, partition by `business_date`

## 15-section pattern for this tool (see master doc)
Intro, Why, Business use case, Architecture, Source systems, Source of truth, UI walkthrough, Sample data, Implementation, Bronze/Silver/Gold, Repo/Git, QA, Production, Troubleshooting, Daily activities.
Next to add here: UI walkthrough screenshots (from your own lab), EXPLAIN output, Workgroup cost check.
