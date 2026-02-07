# E-005 Success: Retry -> DLQ -> Replay

## Setup
- `FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3`
- replay filter: `REPLAY_ACCOUNT_ID=A-3`

## Run
```bash
./scripts/exp run E-005
./scripts/exp assert E-005
```

## Automated Validation
- replay audit records are written
- projection converges after replay
- dedup prevents side-effect duplication
