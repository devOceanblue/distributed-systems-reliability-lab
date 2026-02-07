# E-009 ISR/minISR/acks matrix simulation

## Setup
- Case A: `min.insync.replicas=2`, `acks=all`
- Case B: `min.insync.replicas=1`, `acks=all`

## Run
```bash
./scripts/exp run E-009
./scripts/exp assert E-009
```

## Automated Validation
- Case A with two broker failures returns `NotEnoughReplicas`
- Case B can produce with durability risk
