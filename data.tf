
data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/"
  output_path = "${path.module}/lambda_code/lambda_function_payload.zip"
}