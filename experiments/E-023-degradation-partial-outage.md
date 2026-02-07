# E-023 Partial outage degradation

## Run
```bash
./scripts/exp run E-023
./scripts/exp assert E-023
```

## Validation
- safe mode lowers error rate vs unsafe in Redis/Kafka/MySQL outage profiles
- outbox backlog recovery marker exists
