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

# Placeholder resources for Phase 5 template.
# Concrete IaC implementation should replace these with real module resources.
resource "null_resource" "network_contract" {
  triggers = {
    vpc_cidr = var.vpc_cidr
  }
}
