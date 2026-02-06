# Reliability Lab — Kafka × MySQL × Redis 실험장 (Success/Failure Repro)

이 레포는 Kafka 운영 표준(Outbox, processed_event 멱등 소비, Consumer-First 스키마 전략, DLQ/Replay, HW/LEO/LSO 가시성)
+ Redis 캐시 운영 원칙(TTL, Invalidation(outbox), stampede 방지, cluster mode 주의)
을 **“실험으로 재현”**하기 위한 랩 프로젝트입니다.

## 목표
- ✅ 올바른 사용(운영 표준)을 적용했을 때: 유실/중복/스테일/DB 과부하가 **어떻게 통제되는지** 보여준다.
- ❌ 잘못된 사용을 적용했을 때: 중복 처리, 유실, stale cache, DB overload 장애가 **어떻게 발생하는지** 재현한다.
- 실험은 모두 `experiments/`의 시나리오로 문서화하고, `scripts/`로 자동 실행/검증한다.

---

## 구성 요소
- Kafka cluster (3 brokers) + Schema Registry + Kafka UI
- MySQL 8 (+ Flyway)
- Redis (standalone; 선택적으로 cluster mode 실험 확장 가능)
- Spring Boot services
  - `command-service`: 도메인 변경 + outbox 기록 (또는 잘못된 direct-produce 모드)
  - `outbox-relay`: outbox poll → Kafka publish (중복/유실 failpoint 포함)
  - `consumer-service`: 멱등 소비(processed_event) + read model 반영 + retry/DLQ
  - `query-service`: cache-aside 조회 + TTL/jitter + invalidation(DEL/versioned) + stampede 방어(singleflight)
  - `replay-worker`: DLQ replay / offset-reset 보조(통제된 재처리)
- `experiment-harness`: 실험 실행/검증 스크립트 + 결과 리포트

---

## Quickstart (개발 완료 후)
```bash
# 1) infra up
docker compose up -d

# 2) build & run services
./gradlew :services:command-service:bootRun
./gradlew :services:outbox-relay:bootRun
./gradlew :services:consumer-service:bootRun
./gradlew :services:query-service:bootRun

# 3) run experiments
./scripts/exp run E-001   # 성공 케이스
./scripts/exp run E-003   # 중복 처리 실패 케이스 등
```

---

## 실험 시나리오

E-001: ✅ Outbox + Relay + processed_event + cache invalidation(DEL/version) 정상 동작

E-002: ❌ Outbox 없이 direct-produce → DB commit 이후 크래시 → 이벤트 유실

E-003: ❌ processed_event 없이 소비 → 중복 메시지로 side-effect 2번 발생

E-004: ❌ offset 먼저 commit(At-most-once) → 크래시 → 처리 유실

E-005: ✅ Retry → DLQ → Replay (dedup_key로 안전)

E-006: ❌ Producer-first + breaking schema → 컨슈머 장애/lag 폭증; ✅ Consumer-first로 해결

E-007: ✅/❌ Kafka Transaction: LSO로 인해 “메시지 존재하지만 read_committed에서 안 보임” 재현

E-008: ❌ 캐시 stampede로 DB 과부하 → ✅ singleflight/soft TTL로 완화

E-009: ISR/min.insync/acks 조합으로 producer 성공/실패 및 내구성 차이 재현

자세한 절차는 Runbook.md 참고.

---

## Ports (권장)

Kafka UI: 18090

Schema Registry: 18091

MySQL: 13306

Redis: 16379

command-service: 18080

query-service: 18081
