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
- `B-0327` ~ `B-0329`: `TODO`

## Phase 3 — Observability + Chaos
- `B-0330` ~ `B-0331`: `TODO`
- `B-0332`: `DONE`

## Phase 4 — Advanced Experiments
- `B-0333` ~ `B-0346`: `TODO`

## Phase 5 — AWS/IAM/Runtime Profiles
- `B-0350` ~ `B-0356`: `TODO`

## Runtime-Complete Track (Reopened)
Acceptance를 실제 런타임/운영 검증 기준으로 맞추기 위해 아래 티켓을 재오픈했다.

Priority 1 (core correctness)
- `(완료)`

Priority 2 (core experiments completeness)
- `B-0327`, `B-0328`, `B-0329`

Priority 3 (observability/advanced runtime)
- `B-0330`, `B-0331`, `B-0333`, `B-0334`, `B-0335`, `B-0336`, `B-0337`, `B-0338`, `B-0341`, `B-0342`, `B-0345`, `B-0346`

Priority 4 (aws production completeness)
- `B-0350`, `B-0351`, `B-0352`, `B-0353`, `B-0354`, `B-0355`, `B-0356`

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
