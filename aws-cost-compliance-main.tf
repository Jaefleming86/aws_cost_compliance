terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region"        { type = string  default = "us-east-1" }
variable "email"         { type = string  default = "email" }
variable "budget_name"   { type = string  default = "democost86" }
variable "budget_amount" { type = number  default = 50 }
variable "bucket_name"   { type = string  default = "demo-cost-bucket-CHANGE-ME" }
variable "vpc_id"        { type = string  default = "vpc-cost" }
variable "route_table_ids" { type = list(string) default = ["rtb-cost"] }

module "budgets" {
  source             = "../modules/budgets"
  budget_name        = var.budget_name
  limit_amount       = var.budget_amount
  notification_email = var.email
  tag_key            = "App"
  tag_value          = "demo-app"
}

module "s3_lifecycle" {
  source      = "../modules/s3_lifecycle"
  bucket_name = var.bucket_name
}

module "vpc_endpoints" {
  source          = "../modules/vpc_endpoints"
  vpc_id          = var.vpc_id
  route_table_ids = var.route_table_ids
}

module "security_hub" {
  source = "../modules/security_hub"
}

module "config_required_tags" {
  source          = "../modules/config_required_tags"
  required_tags   = ["Owner","App","Env"]
  lambda_zip_path = "${path.module}/../../lambdas/auto_remediate_required_tags/auto_remediate_required_tags.zip"
}
