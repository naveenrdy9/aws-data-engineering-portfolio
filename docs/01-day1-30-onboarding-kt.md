# Day 1-30 Onboarding + KT - Senior AWS Data Engineer (Performance Optimisation)
## Status: Representative scenario - NOT a claim about a specific client production system
Use this as a checklist to follow in a NEW company. Adapt names, tools and owners after KT.

## AAA Insurance first - Business in 2 minutes
A customer buys a policy, pays premium, files a claim after an incident.
Source of Truth: Policy Admin system for policy/premium, Claims system for claim amount/status.
Your Gold output answers: total premium by state, total claims by incident type, loss ratio = claims / premium.
BNY Mellon second - same pattern, different domain: a fund/account holds securities, trades settle, NAV is calculated daily.
Source of Truth: custody / fund-accounting system for holdings, trades and prices. Gold output: NAV by fund/date, reconciliation breaks.

## Day 1 - Access only, no prod changes
- [ ] Laptop, SSO, VPN, email, Slack/Teams, Jira, Confluence, GitHub/GitLab
- [ ] AWS: which account is DEV / QA / PROD? Who approves access? Read-only first.
- [ ] Ask for: architecture diagram, repo list, runbooks, on-call rota, data owners list
- [ ] Do NOT request prod write access on Day 1. Ask: "What is the access request process?"
- [ ] Note every login, URL and owner in your own KT notes.

## Day 2-5 - KT: Listen, map, do not change
KT questions to ask the outgoing engineer / Tech Lead:
1. What are the top 5 pipelines? Source -> Bronze -> Silver -> Gold -> consumer?
2. What is the schedule / SLA for each? Who is the business consumer if it is late?
3. Where is the code? Which branch is prod? How is it deployed?
4. Where are logs? CloudWatch? Glue history? Airflow? Databricks job runs?
5. What broke last month? What is the runbook for it?
Reverse KT: at end of Week 1, explain the flow back to your lead in your own words and get corrections. That is the test.

## Daily routine (representative)
09:30 Check overnight jobs / alerts / Slack
10:00 Stand-up: Yesterday / Today / Blocker - with Jira ID and evidence
10:30-13:00 Build / debug in DEV branch, unit tests
14:00 Calls: clarify source data / business rule with BA / Data Owner
15:00 PR, respond to review, support QA
17:00 Update Jira, handover notes, blockers in writing

## Scrum / Jira - words you must use correctly
Epic > Story > Task / Bug. Sprint, Backlog, Story Points, Acceptance Criteria, Definition of Done.
A ticket is DONE only when: code merged, tests pass, QA validates counts, docs/runbook updated, monitoring checked.

## Who to contact - and when
- Senior / Tech Lead: design, code logic, escalation
- Data Architect: modelling, platform pattern
- Source team: missing / late / wrong source file
- BA / Data Owner: what does this field MEAN? Who owns it?
- QA: test coverage, defect
- Platform / DevOps: infra, CI/CD, networking, capacity
- IAM / Security: access, encryption, PII
- Prod Support: incident coordination
Rule: read error + logs + runbook + past tickets FIRST, gather evidence, then ask the right owner with run ID, date, counts.

## Company culture / security - general enterprise rules
- Least privilege: ask only for what the ticket needs, for DEV first.
- No prod changes without PR + approval + change ticket.
- No PII in Slack, screenshots, or personal laptop. No downloading prod data.
- No sharing credentials, no hard-coding secrets - use Secrets Manager / Parameter Store.
- If unsure: ask in writing, do not guess in prod.
