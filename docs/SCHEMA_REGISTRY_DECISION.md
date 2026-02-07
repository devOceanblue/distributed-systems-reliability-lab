# ADR: Schema Registry on AWS

## Decision
Choose **Confluent Schema Registry on ECS/Fargate** for Phase 5 baseline.

## Why
- local and cloud operational model remain consistent
- existing Avro + subject compatibility workflow can be reused

## Tradeoffs
- additional service 운영 비용/복잡도
- _schemas topic and IAM policy 관리 필요

## Follow-up
- Glue Schema Registry PoC can be tracked as alternative path.
