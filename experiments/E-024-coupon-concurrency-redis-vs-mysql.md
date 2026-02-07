# E-024 Coupon Concurrency: Redis vs MySQL

## Goal
선착순 쿠폰 발급에서 MySQL 게이트와 Redis 게이트를 동일 부하로 비교해:
- 정확성(`quota exact`, `oversell=0`, `duplicate=0`)
- 성능(총 시간, p95/p99)
- 병목(락 대기 vs 메모리 원자 게이트)
를 수치로 검증한다.

## Load Matrix
- `30,000` quota
- `100,000` quota

요청 구성:
- unique 요청: `quota`
- duplicate 요청: `quota/10`
- oversubscribe 요청: `quota/5`

## Run
```bash
./scripts/exp run E-024
./scripts/exp assert E-024
```

## Deterministic Checks
- MySQL/Redis 모두 `success == quota`, `oversell == 0`
- `mysql_30k_duration_s == 11`
- `redis_30k_duration_s == 5`
- 100k에서 MySQL의 성능 저하 폭이 Redis보다 큼
- MySQL은 master-only 경로 지표(`*_mysql_master_only_required=1`)
- Redis 초기화 키 불일치 검출:
  - expected: `promo:{code}:issued_count`
  - wrong: `promo:{code}:count`
  - mismatch 시 false soldout 발생

## Notes
- Redis 게이트는 Lua 원자 스크립트 전제를 둔다.
- Redis Cluster에서는 `promo:{code}:issued_count`, `promo:{code}:users`처럼 동일 hash tag를 강제한다.
- 본 실험은 재현 가능한 결정론적 시뮬레이션이다.
