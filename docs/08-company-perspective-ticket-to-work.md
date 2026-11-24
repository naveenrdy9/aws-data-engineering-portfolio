# Company Perspective - Ticket vachaka nundi work chese varaku
## Representative example - real company lo ila untundi. Muse zip tho kalapakudadu.

## 1. Nuvvu company lo join ayyaka first nee daggara em untundi?
- Laptop: company ichina laptop, already VPN, SSO login untundi.
- Accounts: Email, Slack/Teams, Jira, Confluence, GitHub/GitLab, AWS SSO.
- Evvaru istharu? IT / HR onboarding lo istharu. Nee manager first day lo intro call lo chepthadu: "Nee buddy X, nee Lead Y."
- Nuvvu adagalsina first questions: "Naa team repo enti? Confluence page enti? AWS account enti - Dev/QA/Prod?"

## 2. Ticket ekkada nundi vasthundi? Files ekkada nundi vasthayi?
Ticket Jira lo untundi. Ticket lo usually untundi:
- Title, Description, Acceptance Criteria
- Repo link / Component name
- Example: Repository: eli-lilly-data-platform (representative name), Folder: pipelines/claims/
- Evvaru istharu? Scrum Master / Lead Sprint Planning lo assign chesthadu. Ticket lo repo peru lekapothe, Lead ni adugu: "Ee ticket ki repo enti, branch strategy enti?"
- Files ni evaru download chesi ivvaru. Files Git repo lo untayi. Nuvve clone cheskovali.

## 3. Repo ante enti? Simple ga
Repo ante code store chese place - GitHub lanti chota. Andulo anni files untayi: Python code, SQL, Terraform, README, tests.
Muse zip ante naa practice files. Company repo ante team motham kalisi vadey real code.

## 4. Step-by-step - Ticket vachaka
### Step A - Ticket chaduvu (Jira lo)
Jira open cheyi > Ticket DE-1245 open cheyi > Description, Comments, Attachments chaduvu.
Doubt unte ticket lo comment pettu, leka Lead ki Slack lo adugu. Code start cheyaku.

### Step B - Repo name / link teesko
- Ticket lo link unte dani click cheyi.
- Lekapothe Confluence lo "Team Repositories" page chudu.
- Lekapothe Lead ni adugu: "Repo URL ivvandi, nenu clone cheskunta."
- Example URL (representative): https://github.com/company/eli-lilly-data-platform.git

### Step C - Laptop lo clone cheyi (VS Code terminal lo)
```bash
# First time only
git clone https://github.com/company/eli-lilly-data-platform.git
cd eli-lilly-data-platform
git branch -a   # main, develop, feature branches chudu
git checkout main
git pull
```
Idhe "files download cheskovali" ante. Zip download kadu, git clone.

### Step D - VS Code lo open cheyi
```bash
code .
```
Left side lo folders kanipisthayi:
```
eli-lilly-data-platform/
  src/pipelines/claims/   <- PySpark code ikkada
  sql/athena/             <- SQL ikkada
  terraform/              <- Infra code ikkada
  tests/                  <- Tests ikkada
  README.md               <- Repo ela vadalo ikkada untundi - FIRST chaduvu
```

### Step E - Local setup - README lo unna steps follow cheyi
Typical steps:
```bash
python3 -m venv venv
source venv/bin/activate   # Windows lo: venv\Scripts\activate
pip install -r requirements.txt
```
AWS access: company lo `aws configure` tho key ivvaru. SSO tho login avtharu:
```bash
aws sso login --profile dev
```
Profile name, region, account - onboarding doc / Lead cheptharu. Nee personal AWS keys vadakudadu company work lo.

### Step F - Ticket kosam branch create cheyi
```bash
git checkout main
git pull
git checkout -b feature/DE-1245-texas-claims-slow
```
Branch peru lo ticket number undali - team rule idi.

### Step G - Code chesi, local lo test chesi, commit cheyi
- VS Code lo file edit cheyi
- Small test run cheyi DEV AWS account lo, prod lo kadu
- Test pass ayithe:
```bash
git status
git add src/pipelines/claims/claims_transform.py
git commit -m "DE-1245: Fix Texas claims Athena slowness - Parquet partition"
git push origin feature/DE-1245-texas-claims-slow
```

### Step H - PR petti, review, QA, Prod
GitHub lo Pull Request create cheyi > Lead/ Senior review chestharu > Comments fix cheyi > CI checks pass avvali > QA test chesthundi > Approve ayithe CI/CD prod ki deploy chesthundi.
Nuvvu prod lo direct ga code marchavu, deploy cheyavu.

## 5. Evvaru em istharu? - Clear table
- IT/HR: Laptop, SSO, VPN, email
- Manager: Team intro, buddy, first tickets
- Tech Lead: Repo URL, architecture, KT, design approval
- Platform/DevOps: AWS access, CI/CD, Terraform process
- Data Owner/BA: Business rule, source of truth, acceptance criteria
- QA: Test data, test cases

## 6. Nuvvu adagakunda unte em avuthundi?
Repo teliyadu, access radu, ticket lo em cheyalo ardham kadu. Andhuke Day 1 lo ne adugu:
1. Repo URL enti?
2. README / Confluence link enti?
3. Dev AWS account / profile enti?
4. Ee ticket ki Data Owner evaru?
5. PR process enti? Reviewer evaru?

## 7. Muse practice vs Company real - difference
- Muse: nenu zip ichanu, nuvvu download chesi, nee personal AWS lo practice chesthav. Idi nerchukovadaniki.
- Company: zip undadu. Git clone, company laptop, company AWS SSO, company Jira, PR process.
- Pattern okate: Ticket -> Repo -> Branch -> Code -> Test -> PR -> QA -> Prod. Pattern nerchukunte, company marana kuda same.
