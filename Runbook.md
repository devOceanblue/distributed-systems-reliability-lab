# Runbook — 실행/검증/복구 절차

## 0) Phase 0 빠른 검증
```bash
./scripts/verify/phase0.sh
```

## 1) Local Infra 기동
```bash
docker compose up -d
docker compose ps
```

중지:
```bash
docker compose down
```

볼륨까지 삭제:
```bash
docker compose down -v
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

## 4) 현재 실험 실행 상태
- `scripts/exp`는 아직 placeholder입니다.
- 실험 `run/assert/cleanup` 표준은 `B-0320`에서 구현됩니다.

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
docker compose -p reliability-lab up -d
```
