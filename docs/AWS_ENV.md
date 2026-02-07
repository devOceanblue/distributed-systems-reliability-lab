# AWS_ENV

## Terraform
```bash
cd infra/aws/terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Required Outputs
- `cluster_arn`
- `bootstrap_brokers_sasl_iam`
- `redis_primary_endpoint`
- `aurora_writer_endpoint`

## Runtime Mapping
- `KAFKA_BOOTSTRAP_SERVERS` <- `bootstrap_brokers_sasl_iam`
- `MYSQL_URL` <- `aurora_writer_endpoint`
- `REDIS_HOST` <- `redis_primary_endpoint`
