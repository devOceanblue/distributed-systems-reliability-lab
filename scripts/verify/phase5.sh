#!/usr/bin/env bash
set -euo pipefail

required_files=(
  Makefile
  infra/aws/terraform/main.tf
  infra/aws/terraform/variables.tf
  infra/aws/terraform/outputs.tf
  infra/aws/terraform/terraform.tfvars.example
  infra/aws/iam/policies/producer-minimal.json
  infra/aws/iam/policies/consumer-minimal.json
  infra/aws/iam/policies/admin-minimal.json
  docs/AWS_ENV.md
  docs/MSK_IAM_CLIENT.md
  docs/LOCAL_VS_AWS.md
  docs/MSK_IAM_POLICIES.md
  docs/OBSERVABILITY.md
  docs/SCHEMA_REGISTRY_DECISION.md
  scripts/smoke/aws-kafka-produce.sh
  scripts/smoke/aws-kafka-consume.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

LAB_PROFILE=aws KAFKA_BOOTSTRAP_SERVERS='b-1.dev:9098,b-2.dev:9098,b-3.dev:9098' ./scripts/smoke/aws-kafka-produce.sh >/dev/null
./scripts/smoke/aws-kafka-consume.sh >/dev/null

./scripts/exp run E-IAM-001 >/dev/null
./scripts/exp assert E-IAM-001 >/dev/null
./scripts/exp run E-IAM-002 >/dev/null
./scripts/exp assert E-IAM-002 >/dev/null
./scripts/exp run E-IAM-003 >/dev/null
./scripts/exp assert E-IAM-003 >/dev/null

echo "[OK] phase5 aws/iac/policy assets and smoke checks passed"
