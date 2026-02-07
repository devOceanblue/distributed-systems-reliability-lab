# MSK_IAM_POLICIES

## Templates
- `infra/aws/iam/policies/producer-minimal.json`
- `infra/aws/iam/policies/consumer-minimal.json`
- `infra/aws/iam/policies/admin-minimal.json`

핵심 포인트:
- producer 최소권한에는 `WriteDataIdempotently` + `transactional-id` 리소스가 포함되어야 한다.
- consumer 최소권한에는 `AlterGroup`/`DescribeGroup`이 반드시 포함되어야 한다.

## Failure Reproduction
- `consumer-missing-group.json`: group join/commit failure
- `producer-topic-restricted.json` + unauthorized topic: write access denied
- `producer-missing-idempotent.json`: idempotent producer failure scenario

## Simulated IAM Experiments
- `E-IAM-001`: missing group permission
- `E-IAM-002`: write denied on unauthorized topic
- `E-IAM-003`: idempotent permission missing
