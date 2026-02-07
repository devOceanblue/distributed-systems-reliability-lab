# Reliability Lab
Kafka x MySQL x Redis 기반으로 분산 시스템 성공/실패 패턴을 재현 가능한 실험으로 검증하는 레포입니다.

## Current Status
이 저장소는 스캐폴드/시뮬레이션 기반 구현을 완료했고, 현재는 런타임 완결 기준으로 일부 티켓을 재오픈한 상태입니다.

- `B-0301`: 기본 문서/폴더 스캐폴드 완료
- `B-0302`: `docker-compose.local.yml`, `docker-compose.aws.override.yml`, `infra/*` 작성 완료
- `B-0303`: Avro 계약 + Schema Registry 등록 스크립트 + `event-core` codec/client 테스트 완료
- `B-0310`~`B-0315`: core schema/command/relay/consumer/query/replay 시뮬레이터 구현
- `B-0311`~`B-0313` 런타임 치환 1차: Gradle 멀티모듈 + Spring Boot command-service/outbox-relay/consumer-service + e2e 테스트
- `B-0314` 런타임 치환 2차: Spring Boot query-service + Redis cache-aside/stampede 방어 + consumer invalidation(DEL|VERSIONED|NONE)
- `B-0315` 런타임 치환 3차: Spring Boot replay-worker + DLQ 캡처/필터/rate-limit/재발행 + replay_audit 기록
- `B-0320`~`B-0329`: `scripts/exp` 하네스 + E-001~E-009 run/assert/cleanup 구현
- `B-0330`~`B-0332`: Prometheus/Grafana/alerts + `scripts/chaos/*` 구현
- `B-0333`~`B-0346`: E-010~E-023 고급 실험 문서/시나리오/assert 구현
- `B-0350`~`B-0356`: AWS Terraform/IAM 정책/프로파일 문서/스모크/IAM 실험 구현(템플릿 중심)

재오픈 상태:
- 진행중(`tasks/doing`): 없음
- 대기(`tasks/backlog`): `B-0325`~`B-0329`, `B-0330`, `B-0331`, `B-0333`~`B-0346`, `B-0350`~`B-0356`

주의:
- 일부 실험/티켓은 deterministic 시뮬레이션으로 acceptance를 대체하고 있으므로, 운영 수준 acceptance를 위해 재오픈된 티켓을 우선순위대로 치환 중입니다.

## What This Repo Proves
- Outbox 없이 쓰면 이벤트 유실이 난다.
- `processed_event` 없이 소비하면 중복 부작용이 난다.
- 캐시는 정답 저장소가 아니며 invalidation/TTL/stampede 방어가 필요하다.
- 스키마/배포 순서(Consumer-First)를 지키지 않으면 장애가 난다.

## Repo Layout
- `tasks/backlog/`: 티켓 정의 (`B-xxxx.md`)
- `tasks/doing/`, `tasks/done/`: 진행/완료 이동 경로
- `experiments/`: 실험 문서
- `scripts/`: 실험 실행/검증/chaos 스크립트
- `contracts/avro/`: 이벤트 계약
- `infra/`: compose 및 인프라 보조 스크립트
- `libs/event-core/`: 공통 이벤트/페일포인트 코드

## Phase Roadmap
- Phase 0: `B-0301` ~ `B-0303`
- Phase 1: `B-0310` ~ `B-0315`
- Phase 2: `B-0320` ~ `B-0329`
- Phase 3: `B-0330` ~ `B-0332`
- Phase 4: `B-0333` ~ `B-0346`
- Phase 5: `B-0350` ~ `B-0356`

## Commands
현재 즉시 실행 가능한 최소 명령:

```bash
./scripts/verify/phase0.sh
./scripts/verify/B-0303.sh
./scripts/verify/B-0314.sh
./scripts/verify/B-0315.sh
./gradlew :libs:event-core:test
./scripts/verify/phase1-runtime.sh
./scripts/verify/phase1.sh
./scripts/verify/phase2.sh
./scripts/verify/phase3.sh
./scripts/verify/phase4.sh
./scripts/verify/phase5.sh
```

인프라 검증(`B-0302`)용 명령:

```bash
docker compose -f docker-compose.local.yml up -d
./infra/kafka/create-topics.sh
docker compose -f docker-compose.local.yml --profile obs up -d prometheus grafana mysqld-exporter redis-exporter kafka-exporter
```

실험 하네스 명령:

```bash
./scripts/exp list
./scripts/exp run E-001
./scripts/exp assert E-001
./scripts/exp cleanup E-001
```

Schema Registry core contracts:

```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/set-compatibility.sh BACKWARD
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/register-core-schemas.sh
```

Phase 1 runtime services:

```bash
./gradlew :services:command-service:bootRun
./gradlew :services:outbox-relay:bootRun
./gradlew :services:consumer-service:bootRun
./gradlew :services:query-service:bootRun
./gradlew :services:replay-worker:bootRun
./gradlew :services:e2e-tests:test
```

## References
- 규율: `AGENTS.md`
- 설계: `ARCHITECTURE.md`
- 로드맵: `Plans.md`
- 운영 절차: `Runbook.md`
