# Runbook — 실험 실행/장애 분석/복구 절차

## 0) 공통 운영 명령
### Infra up/down
```bash
docker compose up -d
docker compose ps
docker compose logs -f kafka-ui schema-registry mysql redis
docker compose down -v
```

Kafka 토픽 생성

```bash
./infra/kafka/create-topics.sh
```

DB 접속/검증

```bash
mysql -h 127.0.0.1 -P 13306 -u root -proot lab
```

Kafka UI

http://localhost:18090

---

1) 실험 실행 표준

모든 실험은 experiments/E-xxx-*.md에:

목적

준비

실행 단계(스크립트/토글)

기대 결과(정량)

복구/정리

관측 포인트(로그/SQL/lag) 를 포함한다.


실행 CLI (B-0320에서 구현)

```
./scripts/exp run E-001
./scripts/exp run E-003 --fast
./scripts/exp assert E-003
./scripts/exp cleanup E-003
```

---

## 실험 목록(확장)
- E-001 ✅ 정상(Outbox+Relay+processed_event+invalidation)
- E-002 ❌ 유실(direct-produce + crash)
- E-003 ❌ 중복(side effect 2회)
- E-004 ❌ at-most-once(오프셋 선커밋)
- E-005 ✅ DLQ/Replay
- E-006 ✅/❌ 스키마/배포 순서
- E-007 ✅/❌ LEO/HW/LSO + read_committed(트랜잭션 open/commit)
- E-008 ✅/❌ cache stampede → DB overload
- E-009 ✅/❌ ISR/minISR/acks
- E-010 ✅/❌ Redis Cluster Mode 슬롯/HashTag/Lua
- E-011 ✅/❌ Hot key/hot shard
- E-012 ✅ Tx abort 구간 skip-like(정상 동작) 재현/관측/해석
- E-013 ❌/✅ Redis Lua 원자 갱신 오남용 → DB/캐시 불일치 재현 + 올바른 invalidation 패턴
- E-014 ✅ processed_event retention(TTL/아카이브/파티션) 운영 비용/성능 비교
- E-015 ✅/❌ Schema Registry compatibility로 브레이킹 변경 사전 차단 + 우회(토픽 버저닝)

---

2) 장애 분석 포인트(공통)

(A) 중복 의심

processed_event 카운트와 ledger 카운트 비교

동일 dedup_key/tx_id가 2번 반영됐는지 확인


(B) 유실 의심

outbox_event에서 SENT인데 consumer projection에 반영 안 됐는지

direct-produce 모드에서는 “DB에는 반영, Kafka에는 없음” 케이스가 재현됨


(C) 캐시 stale 의심

Redis key/value 확인

invalidation 이벤트 소비 여부 확인

TTL/jitter 적용 여부 확인


(D) LEO/HW/LSO(트랜잭션 가시성)

read_committed 컨슈머가 멈춘 경우:

프로듀서 트랜잭션 commit 여부 확인

(가능하면) Kafka tool로 LSO 정체 확인(실험 로그 기반)

---

## Rebalance 폭탄(consumer) 체크리스트
- max.poll.interval.ms 위반 여부 (처리 시간이 poll 간격보다 긴가?)
- heartbeat/session timeout과의 관계
- 배치 크기(max.poll.records) 과다 여부
- 리밸런스 로그/카운트/lag 급증 확인
- processed_event로 중복 무해화가 되었는지 확인

## MySQL deadlock/락 경합 체크리스트
- 1213(Deadlock), 1205(Lock wait timeout) 발생 여부
- SHOW ENGINE INNODB STATUS로 deadlock trace 확인
- 트랜잭션에서 락 획득 순서가 일관적인지
- retry/backoff 정책이 deadlock을 transient로 분류하는지

---

## Backfill 운영 체크리스트
- dry-run(대상/범위/예상 시간) + 영향 분석(DB QPS, lag)
- 샤딩(account_id hash)로 범위 분할
- batch size / rate limit / backpressure 적용
- 체크포인트 저장(중단/재개 가능)
- canary backfill(소량) 후 확대
- 정합성 검증(샘플링 + projection checksum)
- (선택) 스냅샷 기반 부트스트랩 후 delta만 backfill

## Degradation 운영 체크리스트
- Redis 장애: cache-aside fallback + (선택) stale serve + singleflight로 DB 보호
- Kafka 장애: 커맨드(write) 차단 또는 outbox에만 적재 후 릴레이 복구 시 전송(백로그 관리)
- MySQL 장애: read-only 모드/쓰기 차단 + 큐잉 금지(폭발 방지)
- Circuit breaker + timeout + bulkhead로 연쇄 장애 차단

---

3) 복구 표준

DLQ 처리

1. DLQ 메시지 원인 분류(스키마/검증/일시 오류/버그)


2. 버그면 배포


3. replay-worker로 DLQ → main/retry로 통제 재발행


4. processed_event 덕분에 중복은 무해해야 함


replay-worker 안전장치

rate limit (초당 N건)

filter (event_type/account_id 범위)

audit table 기록

---

## 4) Observability 확인 방법
- Grafana: http://localhost:13000 (예시)
- Prometheus: http://localhost:19090

체크 포인트:
- Outbox backlog/oldest age가 증가하는가?
- Consumer lag이 증가하는가?
- DLQ rate가 증가하는가?
- Cache hit ratio 급락 + DB QPS 급증(스탬피드) 징후가 있는가?
- UnderReplicatedPartitions / ISR shrink 발생 여부

## 5) Redis Cluster Mode 운영 체크
- 멀티키/Lua 실패 시: 키 슬롯이 서로 다른지 확인
- HashTag 적용 여부 확인
- Hot shard 징후: 특정 노드 command latency 폭증/timeout

## 6) Tx Abort “건너뛴 듯” 현상 해석
- read_committed consumer는 abort된 레코드를 절대 전달하지 않음
- abort된 레코드가 차지하던 offset 구간을 “기록상 존재하지만 전달되지 않는 구간”으로 건너뛰고 다음 안정 구간으로 진행
- 관측: consumer position과 “수신된 레코드 offset”의 갭을 함께 본다
