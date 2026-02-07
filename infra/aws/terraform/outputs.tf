output "cluster_arn" {
  value = var.msk_cluster_arn
}

output "bootstrap_brokers_sasl_iam" {
  value = var.bootstrap_brokers_sasl_iam
}

output "redis_primary_endpoint" {
  value = var.redis_primary_endpoint
}

output "aurora_writer_endpoint" {
  value = var.aurora_writer_endpoint
}
