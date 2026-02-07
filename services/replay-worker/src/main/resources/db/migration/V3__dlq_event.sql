CREATE TABLE IF NOT EXISTS dlq_event (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_id VARCHAR(64) NOT NULL,
  dedup_key VARCHAR(64) NULL,
  event_type VARCHAR(128) NULL,
  account_id VARCHAR(64) NULL,
  amount BIGINT NOT NULL DEFAULT 0,
  attempt INT NOT NULL DEFAULT 0,
  occurred_at TIMESTAMP NULL,
  raw_payload JSON NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'NEW',
  skip_reason VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  replayed_at TIMESTAMP NULL,
  UNIQUE KEY uk_dlq_event_event_id (event_id),
  KEY idx_dlq_event_status_id (status, id)
);
