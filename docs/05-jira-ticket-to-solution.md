# Jira Ticket - Assign ayinaka Solution varaku - AAA Example
## Representative scenario

## Example Ticket
**DE-1245 | Claims Athena query slow - Texas claims report taking 12 mins**
Type: Bug / Task | Priority: High | Sprint: Sprint 24 | Assignee: You | Reporter: Business Analyst
Acceptance Criteria:
- Texas claims report < 2 mins
- Total claim amount must match Silver table exactly (no change in numbers)
- Cost per run < $0.50 scanned

## Step 1 - Ticket chaduvu (15 min)
- Description, Acceptance Criteria, attachments, comments chaduvu.
- Doubt unte ticket lo ne comment: "Source table silver_claims na, raw_claims na? Business date enti?"
- Do not start code before this is clear.

## Step 2 - Reproduce (30 min)
- Athena History lo slow query run ID teeskoni, Data Scanned chudu: e.g. 850 GB scanned.
- Query chudu: SELECT * FROM raw_claims_csv WHERE state='TX' - partition ledu, Parquet kadu.
- Evidence ticket lo pettu: screenshot / query ID / scanned GB.

## Step 3 - Design + Lead approval (15 min)
- Fix plan: CSV -> Parquet CTAS, partition by state, only needed columns.
- Lead ki cheppu: "Numbers maravu, format matrame maruthundi, DEV lo test chesthanu."
- Approval lekunda prod lo cheyaku.

## Step 4 - Branch + Code (DEV only)
```bash
git checkout main; git pull
git checkout -b fix/DE-1245-athena-texas-claims
# edit sql/athena_queries.sql + terraform for workgroup limit if needed
git add .; git commit -m "DE-1245: Convert claims to partitioned Parquet, add state filter"
git push origin fix/DE-1245-athena-texas-claims
```
## Step 5 - Test in DEV/QA
- Row count: raw 60 vs silver 60? Sum claim_amount same?
- Time: 12 min -> 1.5 min? Scanned: 850 GB -> 62 GB?
- Results ticket lo pettu.

## Step 6 - PR -> Review -> QA -> Prod
PR lo: What changed, Why, Test evidence, Rollback plan.
Reviewer comments fix cheyi. QA validates. UAT/Business approves if needed.
CI/CD deploys to PROD. You monitor first prod run in CloudWatch/Athena History.

## Step 7 - Close
Jira status: Done. Comment: Before/After time, cost, counts. Runbook update if needed.
Scrum lo cheppedi: "Yesterday DE-1245 reproduce chesanu, Today fix DEV lo test chesanu, Blocker ledu."

## Scrum lo ticket ela assign avuthundi?
Sprint Planning (2 weeks): Product Owner priority chepthadu, team estimate chesthundi (Story Points), Lead assign chesthadu.
Daily Standup: blocker unte akkada cheppali.
Backlog Refinement: next sprint tickets clarify chestharu.
