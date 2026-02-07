# Schema Registry Run Guide

## 1) Compatibility 설정
```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/set-compatibility.sh BACKWARD
```

subject 단위 설정:
```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/set-compatibility.sh FULL account.balance.v1-value
```

## 2) 스키마 등록(수동)
```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/register.sh event-envelope-value contracts/avro/event-envelope.avsc
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/register.sh account.balance.v1-value contracts/avro/account-balance-changed-v1.avsc
```

## 3) 스키마 등록(자동)
```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/register-core-schemas.sh
```

## 4) 확인
```bash
curl -s http://localhost:18091/subjects
curl -s http://localhost:18091/subjects/account.balance.v1-value/versions
```

## 5) B-0303 자동 검증
```bash
./scripts/verify/B-0303.sh
./gradlew :libs:event-core:test
```
