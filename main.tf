
// Repeating -> Variables
//Local vars -> Same as resource file
locals {
  lambda_ingestion_iam_role           = "vgangann-ingestion_lambda_iam_role"
  lambda_ingestion_iam_policy         = "vgangann-ingestion_lambda_iam_policy"
  lambda_ingestion_target             = "vgangann-ingestion-lambda-target-fluwehdw32876423"
  lambda_ingestion_target_runtime_env = "python3.9"
  event_bridge_ingestion              = "vgangann-ingestion-event-bridge-tewgfj323wbfw"
  source_bucket                       = "vgangann-source-bucket-fewo342"
  landing_bucket                      = "vgangann-landing-bucket-fewo342"
  curated_bucket                      = "vgangann-curated-bucket-11fwe04fn"
  marketing_bucket                    = "vgangann-marketng-bucket-5d7we2"
  products_table                      = "vgangann-products-table-wr6e8kdjc"
  event_bridge_enrichment             = "vgangann-erichment-event-bridge-64reevatih"
  glue_job_enrichment                 = "vgangann-enrichment-glue-job-67fiu2ef723t"
  glue_job_iam_role_arn               = "arn:aws:iam::937000578452:role/glue-job-role"
  enrichment_sns                      = "vgangann-enrichment-topic"
  alerting_sns                      = "vgangann-altering-topic"
  

}


####### INGESTION STAGE ---------------------------------------------------
# INFRA - Lambda Ingestion 
resource "aws_iam_role" "ingestion_lambda_iam_role" {
  name = local.lambda_ingestion_iam_role
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ingestion_lambda_iam_policy" {
  name = local.lambda_ingestion_iam_policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "s3-object-lambda:*"
        ]
        Resource = "*"
    }, ]
  })
}

resource "aws_iam_policy_attachment" "ingestion-policy-attachment" {
  name       = "vgangann-ingestion-policy-attachment"
  roles      = [aws_iam_role.ingestion_lambda_iam_role.name]
  policy_arn = aws_iam_policy.ingestion_lambda_iam_policy.arn
}


resource "aws_lambda_function" "ingestion_lambda" {
  function_name = local.lambda_ingestion_target
  runtime       = local.lambda_ingestion_target_runtime_env
  role          = aws_iam_role.ingestion_lambda_iam_role.arn
  filename      = "${path.module}/lambda_code/lambda_function_payload.zip"
  handler       = "main.lambda_handler"
  layers = [
    "arn:aws:lambda:us-west-2:336392948345:layer:AWSSDKPandas-Python39:20",
  ]
  timeout = 120


  # lifecycle{
  #   ignore_changes = [layers]
  # }
}

# INFRA - Event Bridge Ingestion 
resource "aws_cloudwatch_event_rule" "ingestion_event_bridge" {
  name        = local.event_bridge_ingestion
  description = "Cron setup to trigger lambda"

  # Can use even -> rate(1 hour) / cron(0 * * * *)
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "ingestion_event_bridge_lambda" {
  rule      = aws_cloudwatch_event_rule.ingestion_event_bridge.name
  target_id = "Trigger-Ingestion-Lambda"
  arn       = aws_lambda_function.ingestion_lambda.arn
  input = jsonencode({
    "name" : "Veeresh-sent-from-EB",
    "trigger_from_event_bridge" : "true"
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ingestion_event_bridge.arn
}


#INFRA S3 Source Bucket
resource "aws_s3_bucket" "vgangann-source-bucket" {
  bucket = local.source_bucket

  tags = {
    Name        = "Source S3"
    Environment = "Dev"
  }
}

#INFRA S3 Landing Bucket
resource "aws_s3_bucket" "vgangann-landing-bucket" {
  bucket = local.landing_bucket

  tags = {
    Name        = "Landing S3"
    Environment = "Dev"
  }
}


####### ENRICHMENT STAGE ---------------------------------------------------
# INFRA - Enrichment Glue Job
resource "aws_glue_job" "enrichment-glue-job" {
  name              = local.glue_job_enrichment
  role_arn          = local.glue_job_iam_role_arn
  description       = "Glue job for running the enrichment logic."
  execution_class   = "STANDARD"
  number_of_workers = 10
  worker_type       = "G.4X"
  default_arguments = {
    "--enable-job-insights" = "true"
    "--job-language"        = "python"
  }

  command {
    script_location = "s3://${aws_s3_bucket.vgangann-landing-bucket.bucket}/glue-enrichment.py"
  }
}

# INFRA - S3 Curated Bucket
resource "aws_s3_bucket" "vgangann-curated-bucket" {
  bucket = local.curated_bucket

  tags = {
    Name        = "Curated S3"
    Environment = "Dev"
  }
  tags_all = {
    "Environment" = "Dev"
    "Name"        = "Curated S3"
  }
}

# INFRA - SNS Enrichment
resource "aws_sns_topic" "enrichment-updates" {
  display_name = "POC - Enrichment ✅"
  name         = local.enrichment_sns
}

resource "aws_sns_topic_subscription" "enrichment-email-subscription" {
  topic_arn                       = aws_sns_topic.enrichment-updates.arn
  protocol                        = "email"
  endpoint                        = var.sns_endpoint
  confirmation_timeout_in_minutes = 1
  endpoint_auto_confirms          = false
}

# INFRA - Curated Bucket Versioning
resource "aws_s3_bucket_versioning" "versioning-curated-bucket" {
  bucket = local.curated_bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# INFRA - Marketing Bucket Versioning
resource "aws_s3_bucket_versioning" "versioning-marketing-bucket" {
  bucket = aws_s3_bucket.marketing-bucket.id
  versioning_configuration {
    status = "Enabled"
  }

}

# INFRA - Marketing Bucket
resource "aws_s3_bucket" "marketing-bucket" {
  bucket = local.marketing_bucket
}


resource "aws_s3_bucket_replication_configuration" "replication" {

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.versioning-curated-bucket]

  role   = "arn:aws:iam::937000578452:role/tf-iam-role-replication-arykulka2x210f"
  bucket = local.curated_bucket

  rule {
    
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.marketing-bucket.arn
      storage_class = "STANDARD"
    }
  }
}


#INFRA SNS - Alerting and Notification
resource "aws_sns_topic" "alerting-updates" {
  display_name = "POC - Data Enriched ✅"
  name         = local.alerting_sns
}

resource "aws_sns_topic_subscription" "alerting-notifying-subscription" {
  topic_arn                       = aws_sns_topic.alerting-updates.arn
  protocol                        = "email"
  endpoint                        = var.sns_endpoint
  confirmation_timeout_in_minutes = 1
  endpoint_auto_confirms          = false
}

