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

## Phase 3 — Redis Cluster / Tx Abort / Observability 확장
- B-0330 Observability Stack (Prometheus+Grafana+Exporters) + Actuator/Micrometer
- B-0331 Dashboards & Alert Rules (outbox age, lag, DLQ rate, cache miss 폭증, DB conn)
- B-0332 Chaos/Failure Toolkit (broker stop/start, netem delay, service kill) 스크립트화

- B-0333 Experiment E-010: Redis Cluster Mode 슬롯/HashTag/Lua/멀티키 제약 실험
- B-0334 Experiment E-011: Hot Key/Hot Shard 실험 + 완화(키/샤딩/캐시)
- B-0335 Experiment E-012: Tx abort 구간 skip-like 동작(read_committed) 재현 + 해석/관측
- B-0336 Experiment E-013: Redis Lua 원자 갱신 오남용 → DB/캐시 불일치 재현
- B-0337 Experiment E-014: processed_event retention(TTL/아카이브/파티션) 운영 비용/성능 비교
- B-0338 Experiment E-015: Schema Registry compatibility로 브레이킹 변경 사전 차단
- B-0341 Experiment E-018: Rebalance 폭탄 실험 + 설정/처리 전략으로 완화
- B-0342 Experiment E-019: MySQL deadlock/lock contention 실험 + retry/DLQ 전략 검증
- B-0345 Experiment E-022: Backfill 대량 재처리 통제(샤딩/배치/체크포인트/스냅샷)
- B-0346 Experiment E-023: Partial Outage Degradation(서킷브레이커/스테일/쓰기 차단) 실험

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
- E-010 ✅/❌ Redis Cluster Mode 슬롯/HashTag/Lua
- E-011 ✅/❌ Hot key/hot shard
- E-012 ✅ Tx abort 구간 skip-like(정상 동작) 재현/관측/해석
- E-013 ❌/✅ Redis Lua 원자 갱신 오남용 → DB/캐시 불일치 재현 + 올바른 invalidation 패턴
- E-014 ✅ processed_event retention(TTL/아카이브/파티션) 운영 비용/성능 비교
- E-015 ✅/❌ Schema Registry compatibility로 브레이킹 변경 사전 차단 + 우회(토픽 버저닝)
- E-018 ❌/✅ Rebalance 폭탄 재현 + 튜닝 완화
- E-019 ❌/✅ MySQL deadlock/락 경합 재현 + retry/DLQ 정책 검증
- E-022 ✅/❌ Backfill(대량 리플레이) 통제: 샤딩/배치/체크포인트/스냅샷
- E-023 ✅/❌ Degradation(부분 장애) 실험: Redis/Kafka/MySQL 우아한 저하
