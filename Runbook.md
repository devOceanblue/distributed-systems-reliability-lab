# Runbook — 실험 실행/장애 분석/복구 절차

## 0) 공통 운영 명령
### Infra up/down
```bash
docker compose up -d
docker compose ps
docker compose logs -f kafka-ui schema-registry mysql redis
docker compose down -v
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
