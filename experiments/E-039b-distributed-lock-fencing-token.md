# E-039b Distributed Lock success pattern (Fencing token + safe unlock)

## Goal
E-039a와 동일 실패 주입에서 **fencing token + safe unlock + job dedup gate**를 적용해 최종 business effect를 1회로 수렴시킨다.

## Safety pattern
1) 락 획득: `SET NX PX` (best-effort)
2) fencing token 발급: `INCR fence:{R1}`
3) DB gate: `last_fence_token < token` + 동일 job dedup
4) unlock: owner 검증 Lua(`GET==owner ? DEL : 0`)

자세한 운영 표준: `docs/standards/distributed-lock-fencing.md`

## Run
```bash
./scripts/exp run E-039B
./scripts/exp assert E-039B
```

테스트 코드 검증:
```bash
./gradlew :services:e2e-tests:test --tests "*DistributedLockSimulationTest.fencing*"
```

## Expected
- `S1~S4` 모두 `duplicate_applied=0`
- `S1~S4` 모두 `applied_count=1`
- stale owner/duplicate attempt는 `stale_rejected` 또는 `dedup_rejected`로 관측
- 결과 요약표: `./.lab/state/e039b/report.md`
