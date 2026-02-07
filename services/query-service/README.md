# query-service

Spring Boot query runtime for cache-aside balance reads.

## Toggles
- `APP_REDIS_ENABLED=true|false`
- `TTL_SECONDS=30`
- `TTL_JITTER_SECONDS=5`
- `STAMPEDE_PROTECTION=ON|OFF`
- `CACHE_INVALIDATION_MODE=DEL|VERSIONED|NONE`

## Usage
```bash
./gradlew :services:query-service:bootRun
curl -s 'http://localhost:8083/accounts/A-1/balance'
```
