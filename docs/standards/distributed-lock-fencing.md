# Distributed Lock 운영 표준 (초안)

## 원칙
- Redis 락은 동시 진입을 줄이는 best-effort 도구다.
- 정확성(Exactly-Once business effect)은 DB gate(토큰/중복키)로 보장한다.

## 필수 패턴
1. lock: `SET lock:{rid} {owner} NX PX {ttlMs}`
2. token: `INCR fence:{rid}`
3. apply gate:
   - `last_fence_token < :token` 조건부 갱신
   - 동일 job/event 중복키(unique) 검증
4. safe unlock (Lua):
```lua
if redis.call('get', KEYS[1]) == ARGV[1] then
  return redis.call('del', KEYS[1])
else
  return 0
end
```

## 권장값(초안)
- `ttlMs`: p99 작업시간의 2~3배 + heartbeat 여유
- backoff: `50~500ms` 지수 백오프 + jitter(0~20%)
- retry 상한: 3~7회
- lock timeout 이후는 stale owner 가능성을 항상 가정

## 안티패턴
- owner 검증 없는 `DEL lockKey`
- 락 획득만으로 “정확히 1번” 가정
- timeout을 실패로 단정하고 원본 요청의 불확실성 무시
