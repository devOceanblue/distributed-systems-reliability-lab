# E-015 Schema Registry compatibility gate

## Run
```bash
SCHEMA_REGISTRY_SIM=true ./infra/schema/set-compatibility.sh BACKWARD
./scripts/exp run E-015
./scripts/exp assert E-015
```

## Validation
- BACKWARD/FULL 모드에서 additive 등록은 성공
- BACKWARD/FULL 모드에서 breaking 등록은 차단
- breaking 변경은 versioned subject(`account.balance.v2.value`)로 우회 등록 가능
