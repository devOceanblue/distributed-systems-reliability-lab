# Frontend Ops Console

백엔드 멱등 제약(`ledger.tx_id`, `outbox_event.dedup_key`)을 프론트 레이어에서 확실히 활용하기 위한 실험 UI입니다.

## 핵심 포인트
- 동일 비즈니스 의도 재시도 시 같은 `request-id`를 재사용합니다.
- `request-id`를 `txId` + `Idempotency-Key` + `X-Request-Id`로 동시에 전달합니다.
- 중복 발행 실험용으로 같은 `request-id`를 병렬 2회 보내는 버튼을 제공합니다.

## 실행
```bash
cd frontend
npm run dev
```

기본 URL:
- Frontend: `http://localhost:8088`
- Proxy -> Command Service: `http://localhost:8080`
- Proxy -> Query Service: `http://localhost:8083`

환경변수 오버라이드:
```bash
FRONTEND_PORT=18088 COMMAND_BASE_URL=http://localhost:8080 QUERY_BASE_URL=http://localhost:8083 npm run dev
```

## 테스트
```bash
cd frontend
npm test
```
