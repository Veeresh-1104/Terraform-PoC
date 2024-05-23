locals {
  dynamo_table_products            = "vgangann-products-table-wr6e8kdjc0"
  enrichment_event_bridge_rule     = "vgangann-enrichment-event-bridge-rule-jdoiwe76wed"
  enrichment_sns                   = "vgangann-test-topics"
  enrichment_glue_workflow         = "vgangan-Enrichment-Glue-Workflow"
  enrichment_glue_workflow_trigger = "vgangann-enrichment-trigger"
  enrichment_event_glue_role       = "Amazon_EventBridge_Invoke_Glue_647180090"
  enrichment_event_glue_policy     = "Amazon_EventBridge_Invoke_Glue_647180090"
}

#INFRA DynamoDB Products table
resource "aws_dynamodb_table" "products_table_007" {
  name           = local.dynamo_table_products
  hash_key       = "Product_ID"
  range_key      = "Trending_ID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "Product_ID"
    type = "N" # Numeric attribute type
  }

  attribute {
    name = "Trending_ID"
    type = "N"
  }
}


resource "aws_cloudwatch_event_rule" "enrichment_event_bridge" {
  name = local.enrichment_event_bridge_rule
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : {
        "name" : ["raw-bucket-arykulka23riancew"]
      },
      "object" : {
        "key" : [{
          "prefix" : "cleaned_data/"
        }]
      }
    }
  })
  description = "Triggered when we have the data in the RAW S3 Bucket"

}


resource "aws_sns_topic" "ingestion-updates" {
  display_name = "POC - Ingestion"
  name         = local.enrichment_sns
}

resource "aws_glue_workflow" "enrichment-workflow" {
  name                = local.enrichment_glue_workflow
  description         = "This workflow is used to trigger the enrichment glue job"
  max_concurrent_runs = 6
}

resource "aws_glue_trigger" "enrichment-glue-workflow-trigger" {
  name          = local.enrichment_glue_workflow_trigger
  workflow_name = aws_glue_workflow.enrichment-workflow.name
  type          = "EVENT"
  enabled       = false
  actions {
    job_name = local.glue_job_enrichment
  }
  event_batching_condition {
    batch_size   = 1
    batch_window = 900
  }
}

resource "aws_iam_role" "enrichment_event_glue_role" {
  name = local.enrichment_event_glue_role
  path = "/service-role/"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "enrichment_event_glue_policy" {
  name = local.enrichment_event_glue_policy
  path = "/service-role/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
          "glue:*"
        ],
        "Resource" : "arn:aws:glue:us-west-2:937000578452:workflow/*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "glue:*",
          "s3:*"
        ],
        "Resource" : "arn:aws:glue:us-west-2:937000578452:workflow/processing-workflow-glue-arykukla49cwe"
      }
    ]
  })
}