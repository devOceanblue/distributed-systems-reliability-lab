# ADR: Schema Registry on AWS

## Decision
Choose **Confluent Schema Registry on ECS/Fargate** for Phase 5 baseline.

## Why
- local and cloud operational model remain consistent
- existing Avro + subject compatibility workflow can be reused
- consumer-first deployment rule and compatibility gate를 동일하게 유지 가능

## Tradeoffs
- additional service 운영 비용/복잡도
- _schemas topic and IAM policy 관리 필요
- ECS task 운영(보안패치/스케일/로그) 책임이 팀에 있음

## Options Comparison
| Option | 장점 | 단점 | 선택 여부 |
|---|---|---|---|
| Confluent SR on ECS | 로컬/클라우드 운영모델 동일, 기존 스크립트 재사용 | 운영 부담 증가 | 선택 |
| AWS Glue SR | 완전 managed + IAM 자연 통합 | serde/클라이언트 변경 비용 | 추후 PoC |

## PoC Scope (완료 기준)
1. schema 등록(v1 -> additive v2) 성공
2. breaking v2 등록 차단(compatibility gate)
3. versioned subject/topic 우회 경로 문서화

Template assets:
- `infra/aws/ecs/schema-registry/task-definition.json`
- `infra/aws/ecs/schema-registry/README.md`

## Follow-up
- Glue Schema Registry PoC can be tracked as alternative path.
