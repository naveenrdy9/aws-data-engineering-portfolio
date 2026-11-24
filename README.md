# AWS Data Engineering — Real-Time Practice Portfolio

Learn how enterprise AWS data engineering actually works — from a Jira ticket to a production pipeline — with realistic sample data, not just definitions.

> **Important:** Examples here are **representative training scenarios** built around insurance and financial domains. They are not claims about any specific client's production system, tools, or incidents. Use them to learn the pattern, then apply it to your own company's repo.

## What you will learn here
- Bronze → Silver → Gold medallion architecture on S3
- AWS Glue (PySpark), Athena, S3, Terraform — Console **and** IaC
- Performance optimisation: partitioning, Parquet, file sizing, data skew, shuffle, cost ($5 / TB scanned in Athena)
- Git workflow: clone → branch → PR → QA → Prod
- Daily work: Scrum, Jira, KT, incident handling, governance, monitoring

## Domains used for examples
| Order | Domain | Example data |
|---|---|---|
| 1 | AAA Insurance (representative) | `policies.csv`, `claims.json` — policy, premium, claim |
| 2 | BNY Mellon Financial (representative) | transactions, accounts, NAV — see `docs/` |
| New client | Eli Lilly Pharma (readiness brief) | clinical / manufacturing / commercial — see `docs/04-eli-lilly-new-client-brief.md` |

## Architecture
```
Source (Policy / Claims system)
  ↓  SFTP / API / DMS
S3 Raw — Bronze (CSV / JSON as-is)
  ↓  Glue PySpark — clean, type, deduplicate, flatten nested JSON
S3 Silver — Parquet, partitioned by state
  ↓  Glue / Athena — join, aggregate, business rules
S3 Gold — Parquet, business-ready
  ↓
Athena / QuickSight / Tableau — dashboards & reports
```

## Repo structure - ONE AWS folder, ONE folder per tool
```
.
├── aws/                     # Main AWS folder
│   ├── s3/                  # S3: bucket, Terraform, sample-data, Lesson 1
│   ├── athena/              # Athena: queries, CTAS, Workgroup
│   ├── glue/                # Glue: Bronze -> Silver -> Gold PySpark
│   ├── redshift/            # Redshift: DISTKEY, SORTKEY, EXPLAIN
│   ├── lambda/              # Lambda: S3 trigger, small jobs
│   ├── airflow/             # Airflow / MWAA: DAGs, scheduling
│   ├── emr/                 # EMR: large Spark clusters
│   ├── iam-security/        # IAM, Lake Formation, KMS, governance
│   ├── monitoring/          # CloudWatch, alarms, incident flow
│   └── terraform-common/    # Shared Terraform
├── data/                    # Original sample data
├── docs/                    # Company, onboarding, Jira, incident playbooks
└── .gitignore
```
Each tool folder has its own README, code, sample data and docs. Search by tool name, open that folder only.

## Quick start — Lesson 1 (15 minutes)
1. Clone this repo, open it in VS Code.
2. Check tools: `aws --version`, `terraform --version`
3. Create the bucket with Terraform:
   ```bash
   cd aws/s3/terraform
   terraform init
   terraform fmt && terraform validate
   terraform plan -var env=dev
   terraform apply -var env=dev
   ```
4. Upload Bronze data:
   ```bash
   aws s3 cp ../sample-data/policies.csv s3://<your-bucket>/policies/year=2026/month=11/day=24/
   ```
5. In Athena, run the queries in `aws/athena/athena_queries.sql`.
   Full steps: `docs/06-lesson1-s3-parquet-athena.md`

## How work flows in a company
```
Jira Ticket → Read ticket → Clone repo → git checkout -b feature/DE-1234-xxx
→ Code in DEV → Test counts & totals → git push → Pull Request
→ Review → QA → CI/CD → Prod → Monitor → Close ticket with evidence
```
Full guide: `docs/05-jira-ticket-to-solution.md` and `docs/08-company-perspective-ticket-to-work.md`

## Performance checklist
- [ ] Parquet, not CSV, for analytics
- [ ] Partition by a column you filter on (e.g. `state`, `business_date`)
- [ ] Select only needed columns — no `SELECT *`
- [ ] File size ~128 MB, avoid 1000s of tiny files
- [ ] Broadcast small dimension tables, salt hot keys for skew
- [ ] Athena Workgroup limit to stop runaway queries

## Contributing
This is a learning repo. If you add a lesson, follow the 15-section pattern in the docs: simple explanation first, then business use case, architecture, sample data, code, Bronze/Silver/Gold, Git/QA/Prod, troubleshooting, and daily work. Label representative scenarios clearly.

## License
MIT — learn, use, and share with credit.
