# E-025 Frontend Request-ID Idempotency: duplicate payment 방지

## Goal
프론트엔드에서 동일 비즈니스 의도(같은 account/action/amount) 재시도 시 같은 `request-id`를 재사용하면,
백엔드의 `ledger.tx_id`/`outbox_event.dedup_key` 제약으로 중복 결제가 차단됨을 결정론적으로 증명한다.

## Setup
- `PRODUCE_MODE=outbox`
- `IDEMPOTENCY_MODE=processed_table`
- Frontend strategy: `STICKY`
- Frontend 전송 규칙:
  - `txId = request-id`
  - `Idempotency-Key = request-id`
  - `X-Request-Id = request-id`

## Run
```bash
./scripts/exp run E-025
./scripts/exp assert E-025
```

## Automated Validation
- 동일 `request-id` 2회 전송 시 두 번째 요청은 duplicate로 거부(exit code `2`)
- `ledger` row = `1`
- `outbox_event` row = `1`
- `processed_event` row = `1`
- `account(A-1).balance == 100`
- `account_projection(A-1).balance == 100`

## Operational Read Points
- 실패 케이스 관찰: 같은 intent에 매번 새 request-id를 발급하면 중복 결제 위험 증가
- 성공 케이스 관찰: sticky/manual request-id 재사용 시 duplicate가 DB 제약에서 즉시 차단
- 런타임 API 경로에서는 HTTP `409`(Data integrity violation)으로 dedup 신호를 관측할 수 있다.
