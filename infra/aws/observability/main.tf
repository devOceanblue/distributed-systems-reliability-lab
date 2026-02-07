terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_prometheus_workspace" "main" {
  count = var.enable_resource_creation ? 1 : 0
  alias = "${local.name_prefix}-amp"
  tags = {
    Name = "${local.name_prefix}-amp"
  }
}

resource "aws_grafana_workspace" "main" {
  count                     = var.enable_resource_creation ? 1 : 0
  name                      = "${local.name_prefix}-grafana"
  account_access_type       = "CURRENT_ACCOUNT"
  authentication_providers  = ["AWS_SSO"]
  permission_type           = "CUSTOMER_MANAGED"
  data_sources              = ["PROMETHEUS", "CLOUDWATCH"]
  notification_destinations = ["SNS"]

  tags = {
    Name = "${local.name_prefix}-grafana"
  }
}

resource "aws_cloudwatch_metric_alarm" "outbox_oldest_age" {
  count               = var.enable_resource_creation ? 1 : 0
  alarm_name          = "${local.name_prefix}-outbox-oldest-age-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "outbox_oldest_age_seconds"
  namespace           = "ReliabilityLab"
  period              = 60
  statistic           = "Maximum"
  threshold           = 300
}

resource "aws_cloudwatch_metric_alarm" "consumer_lag" {
  count               = var.enable_resource_creation ? 1 : 0
  alarm_name          = "${local.name_prefix}-consumer-lag-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 10
  metric_name         = "consumer_lag_records"
  namespace           = "ReliabilityLab"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1000
}

resource "aws_cloudwatch_metric_alarm" "dlq_rate" {
  count               = var.enable_resource_creation ? 1 : 0
  alarm_name          = "${local.name_prefix}-dlq-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "dlq_publish_rate"
  namespace           = "ReliabilityLab"
  period              = 60
  statistic           = "Average"
  threshold           = 1
}

output "amp_workspace_id" {
  value = var.enable_resource_creation ? aws_prometheus_workspace.main[0].workspace_id : "amp-workspace-placeholder"
}

output "grafana_workspace_id" {
  value = var.enable_resource_creation ? aws_grafana_workspace.main[0].id : "grafana-workspace-placeholder"
}
