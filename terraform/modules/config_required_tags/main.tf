terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

variable "required_tags" {
  type    = list(string)
  default = ["Owner","App","Env"]
}

variable "lambda_zip_path" {
  type = string
}

variable "lambda_timeout" {
  type    = number
  default = 120
}

variable "lambda_memory" {
  type    = number
  default = 256
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda" {
  name = "auto-remediate-required-tags-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect="Allow", Principal={ Service="lambda.amazonaws.com" }, Action="sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect="Allow", Action=["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"], Resource="*" },
      { Effect="Allow", Action=["config:PutEvaluations"], Resource="*" },
      { Effect="Allow", Action=["tag:GetResources","tag:TagResources","resource-explorer-2:Search"], Resource="*" },
      { Effect="Allow", Action=["ec2:CreateTags","ec2:Describe*","s3:PutBucketTagging","s3:GetBucketTagging"], Resource="*" }
    ]
  })
}

resource "aws_lambda_function" "auto_remediate" {
  function_name = "auto-remediate-required-tags"
  role          = aws_iam_role.lambda.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.10"
  filename      = var.lambda_zip_path
  memory_size   = var.lambda_memory
  timeout       = var.lambda_timeout

  environment { variables = { REQUIRED_TAGS = join(",", var.required_tags) } }
}

resource "aws_config_config_rule" "required_tags" {
  name = "required-tags-demo"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.auto_remediate.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  maximum_execution_frequency = "One_Hour"
}

resource "aws_lambda_permission" "allow_config" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediate.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_iam_role" "config_role" {
  name = "aws-config-recorder-role"
  assume_role_policy = jsonencode({
    Version="2012-10-17",
    Statement=[{ Effect="Allow", Principal={ Service="config.amazonaws.com" }, Action="sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "config_policy" {
  role = aws_iam_role.config_role.id
  policy = jsonencode({
    Version="2012-10-17",
    Statement=[{
      Effect="Allow",
      Action=["config:*","s3:*","ec2:*","iam:Get*","iam:List*","rds:*","lambda:*","tag:*"],
      Resource="*"
    }]
  })
}

resource "aws_s3_bucket" "config_logs" {
  bucket = "config-logs-${data.aws_caller_identity.current.account_id}"
  lifecycle { prevent_destroy = false }
}

resource "aws_config_configuration_recorder" "this" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}
