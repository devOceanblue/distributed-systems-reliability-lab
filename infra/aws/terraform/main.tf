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
  name_prefix       = "${var.project_name}-${var.environment}"
  create            = var.enable_resource_creation
  broker_subnet_ids = local.create ? slice(concat(aws_subnet.private_data[*].id, aws_subnet.private_app[*].id), 0, 3) : []
}

resource "aws_vpc" "main" {
  count                = local.create ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "private_app" {
  count             = local.create ? length(var.private_subnet_cidrs_app) : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs_app[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-app-${count.index + 1}"
    Tier = "app"
  }
}

resource "aws_subnet" "private_data" {
  count             = local.create ? length(var.private_subnet_cidrs_data) : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs_data[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-data-${count.index + 1}"
    Tier = "data"
  }
}

resource "aws_security_group" "app" {
  count       = local.create ? 1 : 0
  name        = "${local.name_prefix}-app-sg"
  description = "application security group"
  vpc_id      = aws_vpc.main[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "msk" {
  count       = local.create ? 1 : 0
  name        = "${local.name_prefix}-msk-sg"
  description = "MSK SG allowing IAM port from app SG"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "MSK IAM broker port"
    from_port       = 9098
    to_port         = 9098
    protocol        = "tcp"
    security_groups = [aws_security_group.app[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis" {
  count       = local.create ? 1 : 0
  name        = "${local.name_prefix}-redis-sg"
  description = "ElastiCache Redis SG"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "Redis from app"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "aurora" {
  count       = local.create ? 1 : 0
  name        = "${local.name_prefix}-aurora-sg"
  description = "Aurora SG"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "MySQL from app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_msk_cluster" "main" {
  count                  = local.create ? 1 : 0
  cluster_name           = "${local.name_prefix}-msk"
  kafka_version          = var.msk_kafka_version
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = var.msk_broker_instance_type
    client_subnets  = local.broker_subnet_ids
    security_groups = [aws_security_group.msk[0].id]
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  tags = {
    Name = "${local.name_prefix}-msk"
  }
}

resource "aws_elasticache_subnet_group" "main" {
  count       = local.create ? 1 : 0
  name        = "${local.name_prefix}-redis-subnets"
  subnet_ids  = aws_subnet.private_data[*].id
  description = "Redis private subnet group"
}

resource "aws_elasticache_replication_group" "main" {
  count                        = local.create ? 1 : 0
  replication_group_id         = replace("${local.name_prefix}-redis", "_", "-")
  description                  = "${local.name_prefix} redis replication group"
  node_type                    = var.redis_node_type
  parameter_group_name         = var.redis_parameter_group_name
  automatic_failover_enabled   = true
  num_cache_clusters           = 2
  subnet_group_name            = aws_elasticache_subnet_group.main[0].name
  security_group_ids           = [aws_security_group.redis[0].id]
  port                         = 6379
  at_rest_encryption_enabled   = true
  transit_encryption_enabled   = true
  multi_az_enabled             = true

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "aws_db_subnet_group" "main" {
  count      = local.create ? 1 : 0
  name       = "${local.name_prefix}-aurora-subnets"
  subnet_ids = aws_subnet.private_data[*].id

  tags = {
    Name = "${local.name_prefix}-aurora-subnets"
  }
}

resource "aws_rds_cluster" "main" {
  count                     = local.create ? 1 : 0
  cluster_identifier        = "${local.name_prefix}-aurora"
  engine                    = "aurora-mysql"
  engine_version            = var.aurora_engine_version
  database_name             = var.aurora_database_name
  master_username           = var.aurora_master_username
  master_password           = var.aurora_master_password
  db_subnet_group_name      = aws_db_subnet_group.main[0].name
  vpc_security_group_ids    = [aws_security_group.aurora[0].id]
  backup_retention_period   = 7
  preferred_backup_window   = "03:00-04:00"
  storage_encrypted         = true
  skip_final_snapshot       = true
  apply_immediately         = true
}

resource "aws_rds_cluster_instance" "writer" {
  count                = local.create ? 1 : 0
  cluster_identifier   = aws_rds_cluster.main[0].id
  identifier           = "${local.name_prefix}-aurora-writer"
  instance_class       = var.aurora_instance_class
  engine               = aws_rds_cluster.main[0].engine
  engine_version       = aws_rds_cluster.main[0].engine_version
  publicly_accessible  = false
}

resource "aws_rds_cluster_instance" "reader" {
  count                = local.create ? 1 : 0
  cluster_identifier   = aws_rds_cluster.main[0].id
  identifier           = "${local.name_prefix}-aurora-reader"
  instance_class       = var.aurora_instance_class
  engine               = aws_rds_cluster.main[0].engine
  engine_version       = aws_rds_cluster.main[0].engine_version
  publicly_accessible  = false
}
