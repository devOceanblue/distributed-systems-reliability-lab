# E-006 Schema/Deploy Order (Consumer-First vs Producer-First)

## Setup
- failure variant simulates producer-first breaking change
- success variant simulates consumer-first dual-read
- Schema Registry 기준선:
```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/set-compatibility.sh BACKWARD
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/register-core-schemas.sh
```
- 스키마 비교:
  - v1 (`tags:string`): `contracts/avro/schema-order/v1-balance-tags-string.avsc`
  - v2 (`tags:array<string>`): `contracts/avro/schema-order/v2-balance-tags-array.avsc`
- consumer mode:
  - failure(Producer-First): `SCHEMA_READ_MODE=V1_STRICT`
  - success(Consumer-First): `SCHEMA_READ_MODE=DUAL_READ`

## Run
```bash
./scripts/exp run E-006
./scripts/exp assert E-006
```

런타임 E2E 검증:
```bash
./gradlew :services:e2e-tests:test --tests com.reliabilitylab.e2e.SchemaDeployOrderE2ETest
```

## Automated Validation
- failure variant increases DLQ
- success variant keeps DLQ at zero and projection converges
