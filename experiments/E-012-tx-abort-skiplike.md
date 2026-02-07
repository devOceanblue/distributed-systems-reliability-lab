# E-012 Tx abort skip-like visibility (local)

`LAB_PROFILE=local` 전용 실험이다.

## Run
```bash
LAB_PROFILE=local ./scripts/exp run E-012
./scripts/exp assert E-012
```

## Validation
- abort된 구간은 `read_committed_after_abort=0`으로 미전달
- open tx 동안 `LSO < LEO`가 성립
- abort 후 `LSO == LEO`로 회복되지만 abort 레코드는 계속 미전달
- 이후 committed 트랜잭션은 정상 전달(`read_committed_after_commit=1`)
