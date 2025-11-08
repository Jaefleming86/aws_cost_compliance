terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "budget_name" {
  type = string
}

variable "limit_amount" {
  type = number
}

variable "time_unit" {
  type    = string
  default = "MONTHLY"
}

variable "tag_key" {
  type    = string
  default = "App"
}

variable "tag_value" {
  type    = string
  default = "demo-app"
}

variable "notification_email" {
  type = string
}

resource "aws_budgets_budget" "by_tag" {
  name         = var.budget_name
  budget_type  = "COST"
  time_unit    = var.time_unit
  limit_amount = tostring(var.limit_amount)
  limit_unit   = "USD"

  # "TagKeyValue" expects "Key$Value", so build it safely with format()
  cost_filter {
    name   = "TagKeyValue"
    values = [format("%s$%s", var.tag_key, var.tag_value)]
  }

  notification {
    comparison_operator          = "GREATER_THAN"
    threshold                    = 80
    threshold_type               = "PERCENTAGE"
    notification_type            = "FORECASTED"
    subscriber_email_addresses   = [var.notification_email]
  }
}
