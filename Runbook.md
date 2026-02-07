# Runbook — 실행/검증/복구 절차

## 0) Phase 0 빠른 검증
```bash
./scripts/verify/phase0.sh
./scripts/verify/B-0303.sh
./gradlew :libs:event-core:test
```

## 0-1) Phase 1 코어 파이프라인 검증
```bash
./scripts/verify/B-0314.sh
./scripts/verify/B-0315.sh
./scripts/verify/phase1-runtime.sh
./scripts/verify/phase1.sh
./gradlew :services:query-service:test :services:consumer-service:test :services:replay-worker:test
```

## 0-2) Phase 2 실험 하네스 검증
```bash
./scripts/verify/B-0325.sh
./scripts/verify/B-0326.sh
./scripts/verify/B-0327.sh
./scripts/verify/B-0328.sh
./scripts/verify/B-0329.sh
./scripts/verify/phase2.sh
./gradlew :services:e2e-tests:test --tests com.reliabilitylab.e2e.RetryDlqReplayE2ETest
./gradlew :services:e2e-tests:test --tests com.reliabilitylab.e2e.SchemaDeployOrderE2ETest
LAB_PROFILE=local ./scripts/exp run E-007 && ./scripts/exp assert E-007
./scripts/exp run E-008 && ./scripts/exp assert E-008
./scripts/exp run E-009 && ./scripts/exp assert E-009
```

## 0-3) Phase 3 관측/chaos 자산 검증
```bash
./scripts/verify/B-0330.sh
./scripts/verify/B-0331.sh
./scripts/verify/phase3.sh
```

## 0-4) Phase 4 고급 실험 검증
```bash
./scripts/verify/B-0333.sh
./scripts/verify/B-0334.sh
./scripts/verify/B-0335.sh
./scripts/verify/B-0336.sh
./scripts/verify/B-0337.sh
./scripts/verify/B-0338.sh
./scripts/verify/B-0341.sh
./scripts/verify/B-0342.sh
./scripts/verify/B-0345.sh
./scripts/verify/B-0346.sh
./scripts/verify/phase4.sh
```

## 0-5) Phase 5 AWS/IAM 자산 검증
```bash
./scripts/verify/B-0350.sh
./scripts/verify/B-0351.sh
./scripts/verify/B-0352.sh
./scripts/verify/B-0353.sh
./scripts/verify/B-0354.sh
./scripts/verify/B-0355.sh
./scripts/verify/B-0356.sh
./scripts/verify/phase5.sh
```

## 1) Local Infra 기동
```bash
docker compose -f docker-compose.local.yml up -d
docker compose -f docker-compose.local.yml ps
```

중지:
```bash
docker compose -f docker-compose.local.yml down
```

볼륨까지 삭제:
```bash
docker compose -f docker-compose.local.yml down -v
```

## 2) 기본 헬스 확인
Kafka UI:
- `http://localhost:18090`

Schema Registry:
```bash
curl -s http://localhost:18091/subjects
```

MySQL:
```bash
mysql -h 127.0.0.1 -P 13306 -u root -proot -e 'SELECT 1;'
```

Redis:
```bash
redis-cli -h 127.0.0.1 -p 16379 ping
```

## 3) 토픽 생성
```bash
./infra/kafka/create-topics.sh
```

예상 토픽:
- `account.balance.v1`
- `account.balance.retry.5s`
- `account.balance.retry.1m`
- `account.balance.dlq`

Schema Registry 계약 등록:
```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/set-compatibility.sh BACKWARD
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/register-core-schemas.sh
curl -s http://localhost:18091/subjects
```

## 4) 실험 하네스 실행

실험 목록:
```bash
./scripts/exp list
```

실행/검증/정리:
```bash
./scripts/exp run E-001
./scripts/exp assert E-001
./scripts/exp cleanup E-001
```

코어 파이프라인 단일 명령 예시:
```bash
./scripts/sim/lab_sim.sh reset
./scripts/sim/lab_sim.sh seed 1
services/command-service/bin/command-service.sh deposit A-1 tx-1 100
services/outbox-relay/bin/outbox-relay.sh
services/consumer-service/bin/consumer-service.sh
services/query-service/bin/query-service.sh A-1
```

## 5) 장애 분석 포인트(공통)
- 중복 의심:
- `processed_event` 중복 차단 여부
- `dedup_key` 기준 중복 처리 여부

- 유실 의심:
- outbox 상태 대비 projection 반영 여부
- direct-produce 모드 사용 여부

- 캐시 이상:
- invalidation 설정
- TTL/jitter 설정
- stampede 방어 설정

## 6) 운영/정리 주의사항
- `container_name`을 고정하지 않아 프로젝트 간 이름 충돌을 방지한다.
- 데이터 삭제가 필요 없으면 `docker compose down -v`는 사용하지 않는다.
- 여러 프로젝트를 동시에 쓰면 포트/프로젝트명을 명시적으로 분리한다.

예시:
```bash
docker compose -f docker-compose.local.yml -p reliability-lab up -d
```

## 7) Observability 스택 기동
```bash
docker compose -f docker-compose.local.yml --profile obs up -d prometheus grafana mysqld-exporter redis-exporter kafka-exporter
```

- Prometheus: `http://localhost:19090`
- Grafana: `http://localhost:13000` (default admin/admin)

## 8) Chaos Toolkit 사용 예시
브로커 정지/복구:
```bash
./scripts/chaos/broker-stop.sh 1
./scripts/chaos/broker-start.sh 1
```

네트워크 지연 주입/해제:
```bash
./scripts/chaos/netem-delay.sh kafka-1 300 5
./scripts/chaos/netem-clear.sh kafka-1
```

서비스 프로세스 강제종료/재시작:
```bash
./scripts/chaos/kill-service.sh consumer-service.sh
./scripts/chaos/restart-service.sh services/consumer-service/bin/consumer-service.sh
```

## 9) 고급 실험 실행 예시
Schema compatibility gate:
```bash
./scripts/exp run E-015
./scripts/exp assert E-015
```

Deadlock 정책 비교:
```bash
./scripts/exp run E-019
./scripts/exp assert E-019
```

Backfill 통제 비교:
```bash
./scripts/exp run E-022
./scripts/exp assert E-022
```

Partial outage degradation 비교:
```bash
./scripts/exp run E-023
./scripts/exp assert E-023
```

## 10) AWS 프로파일 스모크
```bash
make up-aws
LAB_PROFILE=aws KAFKA_BOOTSTRAP_SERVERS='b-1.dev:9098,b-2.dev:9098,b-3.dev:9098' ./scripts/smoke/aws-kafka-produce.sh
./scripts/smoke/aws-kafka-consume.sh
make down-aws
```

## 11) Phase 1 Runtime 서비스 기동
```bash
./gradlew :services:command-service:bootRun
./gradlew :services:outbox-relay:bootRun
./gradlew :services:consumer-service:bootRun
./gradlew :services:query-service:bootRun
./gradlew :services:replay-worker:bootRun
```


샘플 요청:
```bash
curl -X POST 'http://localhost:8080/accounts/A-1/deposit' \
  -H 'content-type: application/json' \
  -d '{"txId":"tx-runtime-1","amount":100,"traceId":"trace-runtime-1"}'
```

relay 1회 실행:
```bash
curl -X POST 'http://localhost:8081/internal/relay/run-once'
```

consumer 수동 처리 예시:
```bash
curl -X POST 'http://localhost:8082/internal/consumer/process' \
  -H 'content-type: application/json' \
  -d '{"eventId":"evt-1","dedupKey":"tx-1","eventType":"AccountBalanceChanged","accountId":"A-1","amount":100}'
```

query 조회 예시:
```bash
curl -s 'http://localhost:8083/accounts/A-1/balance'
curl -s 'http://localhost:8083/internal/query/metrics'
```

replay-worker 수동 실행 예시:
```bash
curl -X POST 'http://localhost:8084/internal/replay/run' \
  -H 'content-type: application/json' \
  -d '{"output":"MAIN","dryRun":false,"rateLimitPerSecond":10,"operatorName":"lab"}'
```

## 12) Command->Relay->Consumer E2E 테스트
```bash
./gradlew :services:e2e-tests:test
```
