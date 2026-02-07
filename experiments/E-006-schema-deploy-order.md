# E-006 Schema/Deploy Order (Consumer-First vs Producer-First)

## Setup
- failure variant simulates producer-first breaking change
- success variant simulates consumer-first dual-read
- Schema Registry 기준선:
```bash
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/set-compatibility.sh BACKWARD
SCHEMA_REGISTRY_URL=http://localhost:18091 ./infra/schema/register-core-schemas.sh
```

## Run
```bash
./scripts/exp run E-006
./scripts/exp assert E-006
```

## Automated Validation
- failure variant increases DLQ
- success variant keeps DLQ at zero and projection converges
