output "cluster_arn" {
  value = var.enable_resource_creation ? aws_msk_cluster.main[0].arn : var.msk_cluster_arn
}

output "bootstrap_brokers_sasl_iam" {
  value = var.enable_resource_creation ? aws_msk_cluster.main[0].bootstrap_brokers_sasl_iam : var.bootstrap_brokers_sasl_iam
}

output "redis_primary_endpoint" {
  value = var.enable_resource_creation ? aws_elasticache_replication_group.main[0].primary_endpoint_address : var.redis_primary_endpoint
}

output "redis_reader_endpoint" {
  value = var.enable_resource_creation ? aws_elasticache_replication_group.main[0].reader_endpoint_address : var.redis_reader_endpoint
}

output "aurora_writer_endpoint" {
  value = var.enable_resource_creation ? aws_rds_cluster.main[0].endpoint : var.aurora_writer_endpoint
}

output "aurora_reader_endpoint" {
  value = var.enable_resource_creation ? aws_rds_cluster.main[0].reader_endpoint : var.aurora_reader_endpoint
}

output "vpc_id" {
  value = var.enable_resource_creation ? aws_vpc.main[0].id : var.vpc_id
}

output "private_app_subnet_ids" {
  value = var.enable_resource_creation ? aws_subnet.private_app[*].id : []
}

output "private_data_subnet_ids" {
  value = var.enable_resource_creation ? aws_subnet.private_data[*].id : []
}

output "app_sg_id" {
  value = var.enable_resource_creation ? aws_security_group.app[0].id : var.app_sg_id
}

output "msk_sg_id" {
  value = var.enable_resource_creation ? aws_security_group.msk[0].id : var.msk_sg_id
}

output "redis_sg_id" {
  value = var.enable_resource_creation ? aws_security_group.redis[0].id : var.redis_sg_id
}

output "aurora_sg_id" {
  value = var.enable_resource_creation ? aws_security_group.aurora[0].id : var.aurora_sg_id
}
