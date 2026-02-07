# Schema Registry on ECS/Fargate (Template)

This template is the Phase5 baseline for `docs/SCHEMA_REGISTRY_DECISION.md` option A.

## Required runtime envs
- `SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS` (MSK bootstrap brokers, SASL_IAM)
- `SCHEMA_REGISTRY_KAFKASTORE_SECURITY_PROTOCOL=SASL_SSL`
- `SCHEMA_REGISTRY_KAFKASTORE_SASL_MECHANISM=AWS_MSK_IAM`
- IAM auth classes (`IAMLoginModule`, `IAMClientCallbackHandler`) in classpath

## PoC checklist
1. Deploy task in private subnets with SG egress to MSK 9098.
2. Register additive schema using `infra/schema/register.sh`.
3. Verify breaking schema registration is blocked in BACKWARD/FULL compatibility.
