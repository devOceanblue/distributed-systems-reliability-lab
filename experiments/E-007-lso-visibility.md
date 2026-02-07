# E-007 HW/LEO/LSO visibility simulation

## Setup
- local-only transactional visibility simulation
- `LAB_PROFILE=local`
- open transaction 상태에서 `read_uncommitted`/`read_committed` 가시성 비교
- commit 후 LSO가 LEO까지 따라오는지 확인

## Run
```bash
./scripts/exp run E-007
./scripts/exp assert E-007
```

## Automated Validation
- open transaction 시 `read_uncommitted_open=1`
- open transaction 시 `read_committed_open=0`
- open transaction 시 `lso_open < leo_open`
- commit 후 `read_committed_after_resolve=1`
- commit 후 `lso_after_resolve == leo_open`
