# LESSON 3 - Redshift Tuning (JD focus: Performance Optimisation)
## Do this only after Lesson 2 - Silver Parquet S3 lo ready undali.
## Representative scenario - AAA sample data tho. Real client production kadu.

## Goal in 1 line
Athena ad-hoc queries kosam. Redshift repeated, fast warehouse queries + dashboards kosam.
Ade query, ade data - table design marchithe ela fast avuthundo nuvve measure chesi chudali.

## 1. Intro - Redshift ante enti? (simple ga)
Redshift ante columnar data warehouse. S3 lo unna Parquet ni COPY chesi, table laaga
store chesi, SQL tho fast ga query chesey service. Athena serverless, Redshift
cluster / Serverless workgroup tho run avuthundi. Dashboard prathi roju ade query
adigithe, Redshift lo pettadam better - result fast, cost predictable.

## 2. Enduku vadatharu? (business use case - AAA first)
AAA lo business vallu prathi roju adugutharu: "Texas lo Collision claims total entha?
Last month tho compare chesthe ekkuva ayyinda?" Ee query Athena lo prathi sari S3
scan chesthundi. Redshift Gold table lo pettithe, dashboard seconds lo answer isthundi.
BNY Mellon lo ade pattern, domain matrame maaruthundi: daily NAV table - fund_id,
valuation_date tho query chestharu. Rendu kalapakudadu - AAA data tho AAA example,
BNY data tho BNY example, separate ga.

## 3. Architecture
```
S3 Silver Parquet (Lesson 2 output)
  ↓  COPY (Parquet, no CSV re-scan)
Redshift staging/bad tables  →  Redshift good tables (DISTKEY/SORTKEY)
  ↓  Gold aggregate table
QuickSight / Tableau / Power BI → Business users
```

## 4. Source systems & Source of truth
Source of truth: Policy Admin / Claims system (AAA representative). Akkada nundi
Bronze (Lesson 1), Silver (Lesson 2) vachayi. Redshift lo kotha data create cheyaku -
Silver Parquet ne COPY cheyi. Numbers Silver tho match avvali, lekapothe tuning kadu,
load lo tappu.

## 5. Key concepts - simple Telugu-English lo
- **DISTKEY:** Join column ni DISTKEY ga pettina, join ayye rows ade node lo untayi.
  Data node-to-node move avvadhu. `policy_id` tho join chesthe, `policy_id` DISTKEY.
- **SORTKEY:** WHERE filter lo vade column ni SORTKEY ga pettina, Redshift unwanted
  blocks skip chesthundi. `claim_date >= '2026-11-01'` ante, `claim_date` SORTKEY.
- **DISTSTYLE ALL:** Chinna dimension table (states list lanti) anni nodes ki copy
  chesthundi - join ki move avasaram ledu. Pedda table ki vadakudadu.
- **EXPLAIN:** Query plan chudu. `DS_BCAST_INNER` / `DS_DIST_ALL_INNER` unte data
  move avuthundi (slow). `DS_DIST_NONE` unte move avvaledu (good).
- **SVL_QLOG:** Slow queries history. `elapsed` microseconds lo untundi.
- **VACUUM + ANALYZE:** DELETE tarvatha space clean cheyali (VACUUM), planner ki
  fresh statistics ivvali (ANALYZE). Lekapothe planner wrong plan isthundi.

## 6. UI walkthrough - Redshift Serverless (lab kosam)
1. AWS Console > Amazon Redshift > Serverless > Create workgroup (dev kosam chinna).
   Namespace lo admin user/password set cheyi - password ekkada share cheyaku.
2. Query Editor v2 open cheyi > workgroup connect avvu.
3. `code/redshift/redshift_tuning.sql` lo unna SQL ni section-by-section run cheyi -
   motham okesari run cheyaku, prathi step output chudu.
4. Lab ayyaka workgroup pause/delete cheyi - lekapothe cost vasthundi.

## 7. Sample data
Lesson 1-2 data ne vaduthunnam: `policies.csv` 100 rows, `claims.json` 60 rows,
Silver Parquet `state` tho partition ayyi untundi. Kotha data ledu.
Claims lo `claim_id, policy_id, claim_amount, claim_date, status, incident_type,
incident_city` - Silver lo nested `incident` flatten ayyindhi.

## 8. Implementation - step by step
File: `code/redshift/redshift_tuning.sql` - section numbers doc tho match avuthayi.
1. **Section 1 - Bad vs Good tables:** Ade columns, rendu versions. Bad lo keys levu,
   Good lo `DISTKEY(policy_id)`, `SORTKEY(claim_date/start_date)`.
2. **Section 2 - COPY:** Silver Parquet nundi load cheyi. IAM role ki S3 read
   permission undali - lekapothe Platform/IAM team ni adugu, role ARN nuvve
   create cheyaku company lo.
3. **Section 3 - QA first:** Bad vs Good counts/sums SAME undali. Mismatch unte
   aapu - tuning mundu load fix cheyi.
4. **Section 4 - Query + EXPLAIN:** Ade join query rendu tables meedha run cheyi.
   Plan lo difference chudu.
5. **Section 5 - Measure:** `SVL_QLOG` lo elapsed chudu. Query ni 3 sarlu run
   chesi middle value teesko - first run cache cold untundi.
6. **Section 6 - Gold:** `gold_claims_by_state` aggregate table create chesi,
   dashboard ki ready cheyi.
7. **Section 7 - Incremental:** Prod pattern - staging -> DELETE that date ->
   INSERT -> VACUUM -> ANALYZE. Lab lo run cheyalsina avasaram ledu.

## 9. Benchmark table - nuvve fill cheyali (numbers invent cheyaku)
| Query | Table | Elapsed (sec) | Plan note |
|---|---|---|---|
| Texas claims join | claims_bad + policies_bad |  |  |
| Texas claims join | claims_good + policies_good |  |  |
| Gold top-10 | gold_claims_by_state |  |  |
Chinna lab data (100/60 rows) lo difference peddaga kanipinchakapovachu - adi normal.
Real data (lakhs/crores rows) lo ne difference kanipisthundi. Difference ledu ani
numbers invent cheyaku - "lab data too small to show a difference" ani rayadam honest.

## 10. Bronze / Silver / Gold - ee lesson lo
- Bronze: Lesson 1 raw CSV/JSON (touch cheyaku).
- Silver: Lesson 2 Parquet - Redshift ki COPY source ide.
- Gold: `gold_claims_by_state` Redshift table - business-ready aggregate.

## 11. Repo / Git - company workflow laaga
```bash
git checkout -b lesson/redshift-tuning
# code/redshift/redshift_tuning.sql + docs/10-lesson3-redshift-tuning.md add cheyi
git add code/redshift docs/10-lesson3-redshift-tuning.md
git commit -m "Add Lesson 3: Redshift tuning - DISTKEY/SORTKEY, EXPLAIN, SVL_QLOG"
git push origin lesson/redshift-tuning
# GitHub lo PR open cheyi, review tarvatha merge cheyi
```
Ee branch lo ne ee lesson undhi - direct master lo push cheyaledu.

## 12. QA checks (ticket close cheyadaniki evidence)
- [ ] Bad vs Good row counts equal (policies, claims)
- [ ] Bad vs Good SUM(premium) / SUM(claim_amount) equal
- [ ] EXPLAIN bad vs good - plan difference note chesava?
- [ ] SVL_QLOG elapsed 3 runs note chesava?
- [ ] Gold table top-10 Athena Gold tho match avuthunda?

## 13. Production - company lo ela untundi?
- Dev lo nuvve test chesthav. QA lo test data tho test avuthundi. Prod lo neeku
  direct write permission undadu - CI/CD ke untundi.
- Prod lo full reload cheyaku - Section 7 incremental pattern vadali.
- COPY ki IAM role, workgroup access - Platform team isthundi, nuvve create cheyaku.
- Eli Lilly (kotha client, pharma) lo: patient/trial data ni lab laaga laptop lo,
  Slack lo pettakudadu. Validation, lineage, audit trail strict - Day 1 lo Lead
  cheppina rules ne follow avvu.

## 14. Troubleshooting
- **COPY fails - S3 permission:** IAM role ARN correct na? Role ki S3 read unda?
  Platform team ni adugu.
- **COPY fails - column mismatch:** Parquet column names table columns tho match
  avuthunnaya chudu. Silver schema marchithe table kuda marchali.
- **Query slow ga ne undhi:** EXPLAIN chudu - DISTKEY join column na? SORTKEY
  filter column na? ANALYZE run chesava? Lab data chinna ayithe difference
  kanipinchadu - adi kuda oka finding ye.
- **Disk full / VACUUM:** DELETE chesaka VACUUM cheyaledu ante space clear avvadu.
  `VACUUM DELETE ONLY` + `ANALYZE` run cheyi.
- **Workgroup cost:** Lab ayyaka pause/delete cheyaledu ante bill vasthundi.
  Console lo workgroup status check cheyi.

## 15. Daily activities / Scrum
Standup lo ila cheppu: "Lesson 3 lo Redshift tuning practice chesthunnanu -
DISTKEY/SORTKEY tho bad vs good tables compare chesi, SVL_QLOG lo elapsed measure
chesanu. Lab data chinna kabatti difference X sec vachindi." Ticket unte
(DE-1245 pattern): ticket number, before/after elapsed, QA counts - anni ticket
comment lo petti close cheyi. Doubt vasthe mundu EXPLAIN + SVL_QLOG chudu,
tarvatha Lead ni adugu - "query slow" ani matrame cheppaku, plan + elapsed tho adugu.

## Homework - ee 3 answers naku pettu
1. Bad vs Good QA counts/sums - equal na? Screenshot/table pettu.
2. SVL_QLOG lo bad vs good elapsed entha? (3 runs middle value)
3. EXPLAIN lo bad plan lo em vachindi, good plan lo em marindhi?

Next Lesson: Airflow / MWAA orchestration - ee Redshift load ni daily DAG laaga ela
nadipistharo, fail ayithe ela alert vasthundo.
