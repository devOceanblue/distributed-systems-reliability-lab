# MSK_IAM_POLICIES

## Templates
- `infra/aws/iam/policies/producer-minimal.json`
- `infra/aws/iam/policies/consumer-minimal.json`
- `infra/aws/iam/policies/admin-minimal.json`

## Failure Reproduction
- `consumer-missing-group.json`: group join/commit failure
- topic-scoped deny: write access denied
- `producer-missing-idempotent.json`: idempotent producer failure scenario

## Simulated IAM Experiments
- `E-IAM-001`: missing group permission
- `E-IAM-002`: write denied on unauthorized topic
- `E-IAM-003`: idempotent permission missing
