# Terraform - HOW companies REALLY do it (not Console clicks)
# Console = learning / debugging only. Prod = Git + Terraform + CI/CD + PR approval.
# Flow: VS Code -> git push -> PR -> CodeBuild/GitHub Actions -> terraform plan -> approve -> terraform apply -> QA -> Prod
#
# FIXED 2026-11-24: the first version of this file could not run `terraform plan`
# at all - `var.env` was commented out but used everywhere, and the Glue
# crawler referred to `aws_iam_role.glue`, which did not exist. Both are
# fixed below. The Athena results bucket (referenced by the workgroup) and
# the Silver/Gold buckets (used by code/glue/bronze_to_silver.py) are now
# created here too, so the names match when env=dev.

terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

provider "aws" { region = "us-east-1" }

variable "env" { default = "dev" } # dev / qa / prod - same code, different tfvars

# S3 buckets - versioning + encryption + lifecycle (no public access)
resource "aws_s3_bucket" "raw" {
  bucket = "aaa-insurance-raw-${var.env}"
  tags = { Environment = var.env, Owner = "data-engineering", PII = "yes" }
}
resource "aws_s3_bucket" "silver" {
  bucket = "aaa-insurance-silver-${var.env}"
  tags = { Environment = var.env, Owner = "data-engineering" }
}
resource "aws_s3_bucket" "gold" {
  bucket = "aaa-insurance-gold-${var.env}"
  tags = { Environment = var.env, Owner = "data-engineering" }
}
resource "aws_s3_bucket" "athena_results" {
  bucket = "aaa-athena-results-${var.env}"
  tags = { Environment = var.env, Owner = "data-engineering" }
}
resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" } }
}

# Glue service role - the crawler needs this to exist. Without it,
# `terraform plan` fails with "Reference to undeclared resource".
resource "aws_iam_role" "glue" {
  name = "aaa-glue-service-role-${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
resource "aws_iam_role_policy" "glue_s3" {
  name = "aaa-glue-s3-${var.env}"
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.raw.arn, "${aws_s3_bucket.raw.arn}/*",
        aws_s3_bucket.silver.arn, "${aws_s3_bucket.silver.arn}/*",
        aws_s3_bucket.gold.arn, "${aws_s3_bucket.gold.arn}/*",
      ]
    }]
  })
}

# Glue Database + Crawler (catalog = Source of Truth for Athena)
resource "aws_glue_catalog_database" "insurance" { name = "aaa_insurance_${var.env}" }

resource "aws_glue_crawler" "policies" {
  name          = "aaa-policies-crawler-${var.env}"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.insurance.name
  s3_target { path = "s3://${aws_s3_bucket.raw.bucket}/policies/" }
}

# Athena Workgroup - COST CONTROL (the Performance Optimisation answer)
resource "aws_athena_workgroup" "main" {
  name = "aaa-analytics-${var.env}"
  configuration {
    result_configuration { output_location = "s3://${aws_s3_bucket.athena_results.bucket}/" }
    # Stop runaway queries: max 10 GB scanned per query in Dev
    bytes_scanned_cutoff_per_query = 10737418240
  }
}
