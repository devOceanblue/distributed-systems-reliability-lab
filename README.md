# Reliability Lab
Kafka x MySQL x Redis 기반으로 분산 시스템 성공/실패 패턴을 재현 가능한 실험으로 검증하는 레포입니다.

## Current Status
이 저장소는 현재 Phase 1(코어 파이프라인)까지 구현된 상태입니다.

- `B-0301`: 기본 문서/폴더 스캐폴드 완료
- `B-0302`: `docker-compose.local.yml`, `docker-compose.aws.override.yml`, `infra/*` 작성 완료
- `B-0303`: Avro 계약 파일 + `libs/event-core` 스캐폴드 완료 + 검증 스크립트 추가
- `B-0310`~`B-0315`: core schema/command/relay/consumer/query/replay 시뮬레이터 구현

주의:
- `B-0302`, `B-0303`의 런타임 acceptance(실제 송수신, registry 등록 성공, 헬스체크)는 환경에서 별도 실행 검증이 필요합니다.

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
- Phase 5 placeholders: `B-0350` ~ `B-0356` (현재 빈 파일)

## Commands
현재 즉시 실행 가능한 최소 명령:

```bash
./scripts/verify/phase0.sh
./scripts/verify/phase1.sh
```

인프라 검증(`B-0302`)용 명령:

```bash
docker compose -f docker-compose.local.yml up -d
./infra/kafka/create-topics.sh
```

실험 하네스 명령은 `B-0320` 이후 본격 지원됩니다.

## References
- 규율: `AGENTS.md`
- 설계: `ARCHITECTURE.md`
- 로드맵: `Plans.md`
- 운영 절차: `Runbook.md`
