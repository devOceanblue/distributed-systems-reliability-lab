# AWS_ENV

## Terraform
```bash
cd infra/aws/terraform
terraform init
cp terraform.tfvars.example terraform.tfvars
# 템플릿 검증(리소스 생성 없이 계약만 검증)
terraform plan -var-file=terraform.tfvars

# 실제 생성 시
# terraform apply -var-file=terraform.tfvars -var='enable_resource_creation=true'
```

## Required Outputs
- `cluster_arn`
- `bootstrap_brokers_sasl_iam`
- `redis_primary_endpoint`
- `redis_reader_endpoint`
- `aurora_writer_endpoint`
- `aurora_reader_endpoint`
- `vpc_id`
- `app_sg_id`, `msk_sg_id`, `redis_sg_id`, `aurora_sg_id`

## Runtime Mapping
- `KAFKA_BOOTSTRAP_SERVERS` <- `bootstrap_brokers_sasl_iam`
- `MYSQL_URL` <- `aurora_writer_endpoint` (`jdbc:mysql://<writer>:3306/lab`)
- `REDIS_HOST` <- `redis_primary_endpoint`
