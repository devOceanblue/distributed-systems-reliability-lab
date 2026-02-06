# Plans.md — Reliability Lab Roadmap

## Phase 0 — Repo/Infra Bootstrap
- B-0301 Repo scaffold + 기본 문서(README/ARCHITECTURE/Runbook/Plans/Agents)
- B-0302 docker-compose (Kafka 3 brokers + Schema Registry + UI + MySQL + Redis)
- B-0303 공통 이벤트 envelope + Avro 스키마(Registry 연동) + 코드 공통 모듈

## Phase 1 — 정상(운영 표준) 파이프라인 구현
- B-0310 MySQL 스키마(Flyway): domain, outbox_event, processed_event, projections
- B-0311 command-service: 도메인 변경 + outbox insert (정상) + direct-produce(실패모드)
- B-0312 outbox-relay: poll/lock/retry/backoff + failpoint(중복/유실 재현)
- B-0313 consumer-service: processed_event 멱등 + retry topics + DLQ publish + failpoint
- B-0314 query-service: cache-aside + TTL/jitter + invalidation(DEL/versioned) + stampede 방어
- B-0315 replay-worker: DLQ replay(통제: rate limit/filter/audit)

## Phase 2 — 실험 하네스/자동 검증
- B-0320 experiment-harness (scripts/exp) + 결과 검증(쿼리/카운트/지표)
- B-0321~B-0329 실험 시나리오 구현(성공/실패 케이스)

## Phase 3 — 관측/런북 강화(선택)
- B-0330 Kafka lag/outbox backlog/DLQ rate/cache hit/db qps 대시보드
- B-0331 장애 대응 Runbook 강화(Replay/Backfill/Schema 사고 대응)

---

## 실험 시나리오 맵
- E-001 ✅ 정상(Outbox+Relay+processed_event+invalidation)
- E-002 ❌ 유실(direct-produce + crash)
- E-003 ❌ 중복(side effect 2회)
- E-004 ❌ at-most-once(오프셋 선커밋)
- E-005 ✅ DLQ/Replay
- E-006 ✅/❌ 스키마/배포 순서
- E-007 ✅/❌ LEO/HW/LSO + read_committed
- E-008 ✅/❌ 캐시 stampede/DB overload
- E-009 ✅/❌ ISR/minISR/acks
