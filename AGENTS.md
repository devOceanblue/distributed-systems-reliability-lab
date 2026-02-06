# AGENTS.md — Reliability Lab (Codex 작업 규율)

## 목적
Kafka × MySQL × Redis를 “올바르게/잘못 사용했을 때”의 성공/실패를 **재현 가능한 실험**으로 구현한다.

## 핵심 원칙
1) 실험은 항상 "재현 가능"해야 한다.
- 모든 실패 케이스는 failpoint/env toggle로 100% 재현 가능해야 함.
- 수동으로 "타이밍 맞추기"를 최소화하고, 가능하면 코드 레벨 failpoint로 결정론 확보.

2) Kafka는 기본적으로 At-Least-Once로 가정한다.
- 정확성은 processed_event(dedup_key)로 애플리케이션이 보장한다.

3) 계약(스키마)과 배포 순서(Consumer-First)는 문서/코드로 강제한다.
- Schema Registry + Compatibility 모드를 실험에 포함한다(최소 1개 시나리오).
- Breaking change 시 토픽 버전 분리 또는 Upcaster 전략을 구현한다.

4) 캐시는 최신화 보장 불가능을 전제로 설계한다.
- TTL + invalidation(outbox) + stampede 방어(singleflight/soft TTL)를 실험으로 증명한다.

## 작업 방식
- 티켓 단위로 작업한다: `tasks/backlog/B-xxxx.md`
- 각 티켓은 다음 산출물을 반드시 만든다:
  - 코드/설정
  - 실험 문서(`experiments/E-xxx-*.md`) 또는 업데이트
  - Runbook 업데이트(실행/복구 절차)
  - 최소 1개 통합 테스트 또는 스크립트 기반 검증

## 코드 규칙
- Java 21, Spring Boot 3.x, Gradle 멀티모듈
- MySQL 마이그레이션은 Flyway로만 관리
- 모든 이벤트는 표준 envelope를 사용한다:
  - event_id, dedup_key, event_type, schema_version, occurred_at, trace_id
- failpoint는 공통 모듈로 제공한다:
  - `FAILPOINTS=after_db_commit,before_outbox_mark_sent,...`
  - 또는 `FAILPOINT_AFTER_DB_COMMIT=true` 형태

## 리뷰 체크리스트
- [ ] 실패 케이스가 결정론적으로 재현되는가?
- [ ] 성공 케이스에서 결과가 항상 동일한가?
- [ ] 실험이 자동 검증(assert) 가능한가?
- [ ] Runbook에 장애 분석 포인트(로그/지표/SQL)가 있는가?

## Observability/Chaos 추가 원칙
- 모든 실험은 “메트릭으로 증명”을 목표로 한다.
  - 실패 케이스: lag/outbox age/dlq rate/db qps/latency가 눈에 띄게 악화되어야 함
  - 성공 케이스: 동일 부하에서 악화 폭이 유의미하게 줄어야 함
- Chaos 스크립트(브로커 다운/지연/서비스 킬)는 `scripts/chaos/*`로 표준화한다.
