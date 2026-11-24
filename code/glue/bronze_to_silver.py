# AAA Insurance - Bronze -> Silver - Glue PySpark
# Bronze: raw CSV/JSON as-is from S3. Silver: cleaned, typed, partitioned Parquet
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, upper, trim, when
from pyspark.sql.types import DecimalType

spark = SparkSession.builder.appName("aaa-bronze-to-silver").getOrCreate()

# 1. READ BRONZE - policies CSV (raw, no cleaning yet)
policies = spark.read.option("header", True).csv(
    "s3://aaa-insurance-raw-dev/policies/year=2026/month=11/day=24/"
)
claims = spark.read.json(
    "s3://aaa-insurance-raw-dev/claims/year=2026/month=11/day=24/"
)

# 2. CLEAN + TYPE - Silver rules: trim, null check, premium > 0, valid date
policies_clean = (policies
    .withColumn("policy_id", trim(col("policy_id")))
    .withColumn("state", upper(trim(col("state"))))
    .withColumn("premium", col("premium").cast(DecimalType(10,2)))
    .withColumn("start_date", to_date(col("start_date")))
    .filter(col("policy_id").isNotNull() & (col("premium") > 0))
    .dropDuplicates(["policy_id"])
)

# Claims: flatten nested incident struct - this is the classic interview example
claims_clean = (claims
    .withColumn("incident_type", col("incident.type"))
    .withColumn("incident_city", col("incident.city"))
    .drop("incident")
    .withColumn("claim_amount", col("claim_amount").cast(DecimalType(12,2)))
    .filter(col("claim_amount") > 0)
)

# 3. WRITE SILVER - Parquet, partitioned by state, ~128MB files, Snappy
# WHY Parquet + partition? Athena scans only needed columns/partitions.
# 1 TB CSV scan = $5. Same data in Parquet, 1 column = ~$0.15-0.50
policies_clean.write.mode("overwrite").partitionBy("state").parquet(
    "s3://aaa-insurance-silver-dev/policies/"
)
claims_clean.write.mode("overwrite").partitionBy("status").parquet(
    "s3://aaa-insurance-silver-dev/claims/"
)

# 4. GOLD - Business-ready aggregate for BI (QuickSight/Tableau)
gold = claims_clean.join(policies_clean, "policy_id", "left") \
    .groupBy("state", "incident_type") \
    .agg({"claim_amount": "sum", "claim_id": "count"}) \
    .withColumnRenamed("sum(claim_amount)", "total_claim_amount") \
    .withColumnRenamed("count(claim_id)", "claim_count")
gold.write.mode("overwrite").parquet("s3://aaa-insurance-gold-dev/claims_by_state/")
print(f"Policies silver: {policies_clean.count()}, Claims silver: {claims_clean.count()}")
