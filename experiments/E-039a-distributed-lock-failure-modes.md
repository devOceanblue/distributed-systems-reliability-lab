# E-039a Distributed Lock failure modes (Redis SET NX PX)

## Goal
Redis lock(`SET lock:{R1} <owner> NX PX`)만으로는 동일 job의 business effect를 정확히 1회로 보장할 수 없음을 결정론적으로 재현한다.

## Setup
- Resource: `R1`
- lock key: `lock:{R1}`
- lock TTL: `2s`
- work time: `5s`
- worker: `Worker-A`, `Worker-B`
- 관측 지표:
  - timeline: `./.lab/state/locklab/*.timeline.log`
  - business effect: `applied_count`

샘플 compose(실서비스 연결용): `experiments/e039/docker-compose.yml`

## Run
```bash
./scripts/exp run E-039A
./scripts/exp assert E-039A
```

테스트 코드 검증:
```bash
./gradlew :services:e2e-tests:test --tests "*DistributedLockSimulationTest.failure*"
```

## Scenarios
- S1 TTL expiry stale owner: TTL 만료 후 B 재획득 + A late commit -> 중복 적용
- S2 bad unlock: owner 검증 없는 DEL로 락 파손 -> 중복 적용
- S3 timeout retry ambiguity: 성공/실패 인지 불일치 + 재시도 -> 중복 시도/적용
- S4 crash/restart loop: crash + retry 경계에서 중복 적용

## Expected
- `S1~S4` 모두 `duplicate_applied=1`
- `S3`는 `duplicate_risk_events>=1`
- 결과 요약표: `./.lab/state/e039a/report.md`
