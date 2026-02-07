# AGENTS.md — Reliability Lab 작업 규율

## 목적
Kafka x MySQL x Redis를 올바르게/잘못 사용했을 때의 결과를 재현 가능한 실험으로 구현한다.

## 핵심 원칙
1) 실패 케이스는 결정론적으로 재현 가능해야 한다.
- Failpoint 또는 env toggle로 100% 재현 가능해야 한다.
- 수동 타이밍 의존 실험은 지양한다.

2) Kafka는 At-Least-Once를 기본 가정으로 둔다.
- 정확성은 애플리케이션 레이어(`processed_event` + `dedup_key`)로 보장한다.

3) 계약(스키마)과 배포 순서(Consumer-First)를 코드/문서로 강제한다.
- Schema Registry compatibility를 최소 1개 시나리오에 포함한다.
- Breaking change는 토픽 버전 분리 또는 upcaster 전략을 사용한다.

4) 캐시는 최신화 보장을 전제로 설계하지 않는다.
- TTL + invalidation(outbox) + stampede 방어(singleflight/soft TTL)를 실험으로 증명한다.

## 작업 방식
- 티켓 단위: `tasks/backlog/B-xxxx.md`
- 진행 상태 디렉토리:
- `tasks/doing/`
- `tasks/done/`
- 각 티켓 산출물 필수:
- 코드/설정
- 실험 문서(`experiments/E-xxx-*.md`) 생성/수정
- Runbook 업데이트
- 최소 1개 자동 검증(통합 테스트 또는 스크립트)

## 코드 규칙
- 목표 기준: Java 21, Spring Boot 3.x, Gradle 멀티모듈
- 현재 상태: 루트 Maven 스캐폴드 기반(Phase 0), Phase 1 이후 목표 구조로 수렴
- MySQL 마이그레이션은 Flyway만 사용
- 이벤트 envelope 필수 필드:
- `event_id`
- `dedup_key`
- `event_type`
- `schema_version`
- `occurred_at`
- `trace_id`
- failpoint는 공통 모듈에서 제공

## 리뷰 체크리스트
- [ ] 실패 케이스가 결정론적으로 재현되는가?
- [ ] 성공 케이스 결과가 항상 동일한가?
- [ ] 실험 결과를 자동 assert 할 수 있는가?
- [ ] Runbook에 로그/지표/SQL 분석 포인트가 있는가?

## Observability/Chaos 원칙
- 모든 실험은 메트릭으로 증명한다.
- 실패 케이스: lag/outbox age/dlq rate/db qps/latency 악화가 관측되어야 한다.
- 성공 케이스: 동일 부하에서 악화 폭이 유의미하게 줄어야 한다.
- Chaos 스크립트는 `scripts/chaos/*` 규칙으로 표준화한다.
