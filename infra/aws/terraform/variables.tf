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

variable "enable_resource_creation" {
  type    = bool
  default = false
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs_app" {
  type    = list(string)
  default = ["10.30.0.0/20", "10.30.16.0/20", "10.30.32.0/20"]
}

variable "private_subnet_cidrs_data" {
  type    = list(string)
  default = ["10.30.64.0/20", "10.30.80.0/20", "10.30.96.0/20"]
}

variable "msk_kafka_version" {
  type    = string
  default = "3.6.0"
}

variable "msk_broker_instance_type" {
  type    = string
  default = "kafka.m7g.large"
}

variable "redis_node_type" {
  type    = string
  default = "cache.r7g.large"
}

variable "redis_parameter_group_name" {
  type    = string
  default = "default.redis7.cluster.on"
}

variable "aurora_engine_version" {
  type    = string
  default = "8.0.mysql_aurora.3.07.1"
}

variable "aurora_instance_class" {
  type    = string
  default = "db.r7g.large"
}

variable "aurora_database_name" {
  type    = string
  default = "lab"
}

variable "aurora_master_username" {
  type    = string
  default = "lab"
}

variable "aurora_master_password" {
  type      = string
  sensitive = true
  default   = "lab-password-change-me"
}

# Fallback outputs for plan-only mode(enable_resource_creation=false)
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
  default = "reliability-dev-primary.xxxxxx.use1.cache.amazonaws.com"
}

variable "redis_reader_endpoint" {
  type    = string
  default = "reliability-dev-reader.xxxxxx.use1.cache.amazonaws.com"
}

variable "aurora_writer_endpoint" {
  type    = string
  default = "reliability-dev.cluster-xxxxxx.us-east-1.rds.amazonaws.com"
}

variable "aurora_reader_endpoint" {
  type    = string
  default = "reliability-dev.cluster-ro-xxxxxx.us-east-1.rds.amazonaws.com"
}

variable "vpc_id" {
  type    = string
  default = "vpc-placeholder"
}

variable "app_sg_id" {
  type    = string
  default = "sg-app-placeholder"
}

variable "msk_sg_id" {
  type    = string
  default = "sg-msk-placeholder"
}

variable "redis_sg_id" {
  type    = string
  default = "sg-redis-placeholder"
}

variable "aurora_sg_id" {
  type    = string
  default = "sg-aurora-placeholder"
}
