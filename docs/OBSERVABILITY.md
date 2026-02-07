# OBSERVABILITY (AWS)

Core signals for AWS runs:
- consumer lag
- outbox oldest age
- dlq rate
- aurora qps/deadlock
- redis hit/miss/evictions

Dashboard source:
- `dashboards/aws-reliability-overview.json`

Terraform scaffolding:
- `infra/aws/observability/main.tf`
- `infra/aws/observability/variables.tf`

Provisioning example:
```bash
cd infra/aws/observability
terraform init
terraform plan
# terraform apply -var='enable_resource_creation=true'
```

Alarm policy should gate degraded mode switch and operator response:
- outbox oldest age > 300s
- consumer lag > 1000
- dlq publish rate > 1/min
