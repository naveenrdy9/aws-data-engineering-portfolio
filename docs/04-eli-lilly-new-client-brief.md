# Eli Lilly - New Client Brief (for joining)
## Status: General pharma domain briefing + JD-based readiness. NOT Eli Lilly internal systems - those are unknown until KT.
## Do not claim any Eli Lilly source system, pipeline or incident as known fact.

## Your JD - confirmed as new company JD
Role: Senior AWS Data Engineer - Performance Optimisation
Core: Design/build/optimise reliable ETL/ELT pipelines on AWS, reusable Python/SQL/PySpark, automated testing, monitoring, exception handling, recovery, troubleshooting + RCA, data modelling, metadata, security/governance, docs/runbooks, collaborate with platform/ops/data owners/business.
Specialist: Diagnose bottlenecks across ingestion/transformation/storage/query, optimise SQL/Spark/PySpark, execution plans, resource use, skew, shuffle, memory, partitioning, file sizing, compression, join strategies, incremental processing, tune Glue/Redshift/Athena, benchmarking, concurrency/capacity, baselines, document runtime/throughput/cost improvements without losing data quality.

Tech in JD: S3, Glue, Redshift, Athena, Lambda, Python, PySpark, Spark, Airflow, Git, CI/CD, data lake/Lakehouse, dimensional modelling.
So priority order for 10-15 days: S3+Glue+Athena first, then Redshift, then Airflow, then Lambda. Databricks/Snowflake are in your master doc scope, but NOT in this JD - learn them only after AWS core is solid.

## Eli Lilly - Pharma domain in simple words
Eli Lilly makes medicines. Data work is not about policies or bank accounts. It is about:
- Research / Clinical Trials: patients in trials, visits, lab results, adverse events, drug efficacy. Data must be traceable, auditable.
- Manufacturing: batches, plants, quality checks, supply chain.
- Commercial: sales to hospitals/pharmacies, HCP (doctor) interactions, market data.
- Safety / Regulatory: adverse event reporting, FDA compliance. A wrong number here is not just a dashboard error - it is a regulatory risk.

Why Performance matters here: trial/manufacturing data is large, joins are heavy, and downstream teams (scientists, regulatory, commercial) need trusted, fast data. Your job is to make slow pipelines fast and cheap, without changing the numbers.

## What is DIFFERENT from AAA / BNY
- AAA: policy/claim - if a claim total is off, money/business impact.
- BNY: trade/NAV - if NAV is off by 1 paisa, money/regulatory impact.
- Eli Lilly: trial/safety data - if a record is missing or duplicated, patient safety / regulatory impact. So: validation, lineage, audit trail, PII/PHI handling are even stricter. Never copy patient data to personal laptop, never share in Slack.
- Source of Truth: you do NOT know it yet. In KT ask: "For trial patient data / batch data / sales data, which system is authoritative? Who is the Data Owner?"
- Representative example only: Trial subject -> visit -> lab result. Bronze: raw EDC export CSV/JSON. Silver: cleaned, typed, de-duplicated, standardised units. Gold: trial summary by study/site - enrolment, adverse events by severity.

## First 30 days at Eli Lilly - questions to ask in KT
1. Which pipelines am I owning? What is their SLA and business consumer?
2. Where is the repo, which branch is prod, how does CI/CD deploy Glue/Redshift/Airflow?
3. What is the data classification? What is PII/PHI here, how is it masked?
4. What are the current slow jobs? Is there a known performance backlog?
5. Who are Data Owners, Platform team, QA, Prod Support?
6. How are incidents raised? PagerDuty / ServiceNow? What is the change approval process?

## 15-day plan - revised for this JD
Day 1-3: S3, Parquet, partitioning, Athena cost ($5/TB) - AAA lab
Day 4-6: Glue PySpark Bronze/Silver/Gold, skew, shuffle, file sizing
Day 7-8: Redshift - distribution/sort keys, EXPLAIN, query tuning
Day 9-10: Airflow DAGs, monitoring CloudWatch, Glue Workflows
Day 11-12: Lambda + Step Functions basics, governance Lake Formation / IAM
Day 13-15: Eli Lilly domain + Day 1-30 KT script + slow-pipeline RCA practice with lab numbers
