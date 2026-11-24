# How to push this to YOUR GitHub — step by step

## Step 1 - GitHub lo repo create cheyi (nee account lo)
1. github.com open cheyi > + > New repository
2. Repository name: `aws-data-engineering-portfolio`
3. Description: `Real-time AWS Data Engineering practice - S3, Glue, Athena, Terraform, Bronze Silver Gold`
4. Public select cheyi (job search lo chupinchadaniki Public better)
5. Add README, .gitignore, License - anni UNCHECK cheyi (manam already files ready chesam)
6. Create repository click cheyi
7. Appudu vache URL copy chesko, example: https://github.com/<nee-username>/aws-data-engineering-portfolio.git
8. Aa URL ni naku ivvu - nenu aa link tho next commands isthanu. Password ivvaku.

## Step 2 - Nee laptop lo push cheyi
VS Code terminal lo, ee repo folder lo:
```bash
cd aws-data-engineering-portfolio
git init
git add .
git commit -m "Initial commit: AWS Data Engineering portfolio - S3, Glue, Athena, Bronze Silver Gold"
git branch -M main
git remote add origin https://github.com/<nee-username>/aws-data-engineering-portfolio.git
git push -u origin main
```
GitHub username/password adigithe, password place lo Personal Access Token vadali (GitHub > Settings > Developer settings > Tokens). Token ni naku ivvaku.

## Step 3 - Prathi lesson ki branch laaga work cheyi (company practice)
```bash
git checkout -b lesson/glue-bronze-silver
# files edit cheyi
git add .
git commit -m "Add Lesson 2: Glue Bronze to Silver"
git push origin lesson/glue-bronze-silver
# GitHub lo Pull Request create cheyi, merge cheyi
```

## Step 4 - Repo ni portfolio laaga marchu
- GitHub repo > About > Topics add cheyi: aws, glue, athena, pyspark, terraform, data-engineering, etl
- README lo unna Architecture diagram chaduvu - interview / job search lo link share cheyochu.
- Prathi topic ki oka folder / doc add chesthu vellu - search chese vallaki useful ga untundi.
