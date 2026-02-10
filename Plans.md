# Plans.md — Reliability Lab Roadmap

## Status Legend
- `DONE`: 산출물/구조 기준 완료
- `IN_PROGRESS`: 일부 구현 완료, acceptance 진행 중
- `TODO`: 미착수

## Phase 0 — Repo/Infra Bootstrap
- `B-0301` Repo scaffold + 기본 문서/폴더: `DONE`
- `B-0302` docker-compose + infra 스크립트: `DONE`
- `B-0303` Event envelope + Avro + Schema Registry + event-core codec/client: `DONE`

## Phase 1 — Core Pipeline
- `B-0310` ~ `B-0313`: `DONE`
- `B-0314`: `DONE`
- `B-0315`: `DONE`

## Phase 2 — Harness + Core Experiments
- `B-0320` ~ `B-0324`: `DONE`
- `B-0325`: `DONE`
- `B-0326`: `DONE`
- `B-0327`: `DONE`
- `B-0328`: `DONE`
- `B-0329`: `DONE`

## Phase 3 — Observability + Chaos
- `B-0330`: `DONE`
- `B-0331`: `DONE`
- `B-0332`: `DONE`

## Phase 4 — Advanced Experiments
- `B-0333`: `DONE`
- `B-0334`: `DONE`
- `B-0335`: `DONE`
- `B-0336`: `DONE`
- `B-0337`: `DONE`
- `B-0338`: `DONE`
- `B-0341`: `DONE`
- `B-0342`: `DONE`
- `B-0345`: `DONE`
- `B-0346`: `DONE`

## Phase 5 — AWS/IAM/Runtime Profiles
- `B-0350`: `DONE`
- `B-0351`: `DONE`
- `B-0352`: `DONE`
- `B-0353`: `DONE`
- `B-0354`: `DONE`
- `B-0355`: `DONE`
- `B-0356`: `DONE`

## Phase 6 — Coupon Concurrency Extension
- `B-0357`: `DONE`

## Runtime-Complete Track (Reopened)
Acceptance를 실제 런타임/운영 검증 기준으로 맞추기 위해 아래 티켓을 재오픈했다.

Priority 1 (core correctness)
- `(완료)`

Priority 2 (core experiments completeness)
- `(완료)`

Priority 3 (observability/advanced runtime)
- `(완료)`

Priority 4 (aws production completeness)
- `(완료)`

## Experiment Map
- `E-001` `B-0321`: baseline success
- `E-002` `B-0322`: direct-produce loss
- `E-003` `B-0323`: duplicate side-effect
- `E-004` `B-0324`: at-most-once loss
- `E-005` `B-0325`: Retry -> DLQ -> Replay
- `E-006` `B-0326`: Consumer-first schema rollout
- `E-007` `B-0327`: LEO/HW/LSO visibility
- `E-008` `B-0328`: cache stampede
- `E-009` `B-0329`: ISR/minISR/acks
- `E-010` `B-0333`: Redis cluster slot/hashtag
- `E-011` `B-0334`: hot key/hot shard
- `E-012` `B-0335`: tx abort skip-like
- `E-013` `B-0336`: Redis Lua consistency anti-pattern
- `E-014` `B-0337`: processed_event retention
- `E-015` `B-0338`: schema compatibility gate
- `E-018` `B-0341`: rebalance storm
- `E-019` `B-0342`: deadlock contention
- `E-022` `B-0345`: controlled backfill
- `E-023` `B-0346`: partial outage degradation
- `E-024` `B-0357`: coupon issuance concurrency (Redis vs MySQL)

- `E-039A` `B-0361`: distributed lock failure modes (TTL expiry / bad unlock / timeout retry / crash restart)
- `E-039B` `B-0361`: fencing token + safe unlock guard validation
- `E-044` `B-0362`: online resharding/rebalancing under load
- `E-045` `B-0363`: multi-az test-failover drill
- `E-046` `B-0364`: reconnect storm/backoff
- `E-047` `B-0365`: slowlog/log-delivery p99 diagnosis
- `E-048` `B-0366`: pubsub slow-consumer output-buffer pressure
- `E-049` `B-0367`: restricted commands compatibility gate
- `E-050` `B-0368`: serverless vs node-based semantics gap
