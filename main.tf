
# INFRA - Lambda Ingestion 
resource "aws_iam_role" "ingestion_lambda_iam_role" {
  name = "vgangann-ingestion_lambda_iam_role"
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
  name = "vgangann-ingestion_lambda_iam_policy"
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

data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/"
  output_path = "${path.module}/lambda_code/lambda_function_payload.zip"
}

resource "aws_lambda_function" "ingestion_lambda" {
  function_name = var.lambda_ingestion_target
  runtime       = var.lambda_ingestion_target_runtime_env
  role          = aws_iam_role.ingestion_lambda_iam_role.arn
  filename      = "${path.module}/lambda_code/lambda_function_payload.zip"
  handler        = "main.lambda_handler"
}

# INFRA - Event Bridge Ingestion 
resource "aws_cloudwatch_event_rule" "ingestion_event_bridge" {
  name        = var.event_bridge_ingestion
  description = "Cron setup to trigger lambda"

  # Can use even -> rate(1 hour) / cron(0 * * * *)
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "ingestion_event_bridge_lambda" {
  rule      = aws_cloudwatch_event_rule.ingestion_event_bridge.name
  target_id = "Trigger-Ingestion-Lambda"
  arn       = aws_lambda_function.ingestion_lambda.arn
  input = jsonencode({
    "name": "Veeresh-sent-from-EB",
    "trigger_from_event_bridge": "true"
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.ingestion_event_bridge.arn
}


#INFRA S3 Source Bucket
resource "aws_s3_bucket" "vgangann-source-bucket" {
  bucket = var.source_bucket

  tags = {
    Name        = "Source S3"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "vgangann-landing-bucket" {
  bucket = var.landing_bucket

  tags = {
    Name        = "Landing S3"
    Environment = "Dev"
  }
}

