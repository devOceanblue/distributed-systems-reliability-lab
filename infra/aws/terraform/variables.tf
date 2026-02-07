variable "project_name" {
  type    = string
  default = "reliability-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "msk_cluster_arn" {
  type    = string
  default = "arn:aws:kafka:us-east-1:111111111111:cluster/reliability-lab-dev/placeholder"
}

variable "bootstrap_brokers_sasl_iam" {
  type    = string
  default = "b-1.reliability.dev:9098,b-2.reliability.dev:9098,b-3.reliability.dev:9098"
}

variable "redis_primary_endpoint" {
  type    = string
  default = "reliability-dev.xxxxxx.use1.cache.amazonaws.com"
}

variable "aurora_writer_endpoint" {
  type    = string
  default = "reliability-dev.cluster-xxxxxx.us-east-1.rds.amazonaws.com"
}
