#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
main_tf="$ROOT_DIR/infra/aws/terraform/main.tf"
vars_tf="$ROOT_DIR/infra/aws/terraform/variables.tf"
outs_tf="$ROOT_DIR/infra/aws/terraform/outputs.tf"

for file in "$main_tf" "$vars_tf" "$outs_tf" "$ROOT_DIR/infra/aws/terraform/terraform.tfvars.example" "$ROOT_DIR/docs/AWS_ENV.md"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: ${file#$ROOT_DIR/}"; exit 1; }
done

for pattern in \
  'resource "aws_vpc" "main"' \
  'resource "aws_msk_cluster" "main"' \
  'resource "aws_elasticache_replication_group" "main"' \
  'resource "aws_rds_cluster" "main"' \
  'resource "aws_security_group" "app"' \
  'resource "aws_security_group" "msk"' \
  'resource "aws_security_group" "redis"' \
  'resource "aws_security_group" "aurora"'; do
  grep -q "$pattern" "$main_tf" || { echo "[FAIL] terraform resource missing: $pattern"; exit 1; }
done

for output_name in \
  'output "cluster_arn"' \
  'output "bootstrap_brokers_sasl_iam"' \
  'output "redis_primary_endpoint"' \
  'output "redis_reader_endpoint"' \
  'output "aurora_writer_endpoint"' \
  'output "aurora_reader_endpoint"' \
  'output "vpc_id"' \
  'output "app_sg_id"' \
  'output "msk_sg_id"' \
  'output "redis_sg_id"' \
  'output "aurora_sg_id"'; do
  grep -q "$output_name" "$outs_tf" || { echo "[FAIL] terraform output missing: $output_name"; exit 1; }
done

echo "[OK] B-0350 verification passed"
