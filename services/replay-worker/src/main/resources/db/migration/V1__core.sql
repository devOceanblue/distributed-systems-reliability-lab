CREATE TABLE IF NOT EXISTS account (
  account_id VARCHAR(64) PRIMARY KEY,
  balance BIGINT NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ledger (
  tx_id VARCHAR(64) PRIMARY KEY,
  account_id VARCHAR(64) NOT NULL,
  amount BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ledger_account FOREIGN KEY (account_id) REFERENCES account(account_id)
);

CREATE TABLE IF NOT EXISTS outbox_event (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_id VARCHAR(64) NOT NULL,
  dedup_key VARCHAR(64) NOT NULL,
  event_type VARCHAR(128) NOT NULL,
  payload_json JSON NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'NEW',
  attempts INT NOT NULL DEFAULT 0,
  next_attempt_at TIMESTAMP NULL,
  last_error TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_outbox_dedup_key (dedup_key),
  KEY idx_outbox_status_next_id (status, next_attempt_at, id)
);

CREATE TABLE IF NOT EXISTS processed_event (
  consumer_group VARCHAR(128) NOT NULL,
  dedup_key VARCHAR(64) NOT NULL,
  processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  topic VARCHAR(255) NULL,
  partition_no INT NULL,
  offset_no BIGINT NULL,
  PRIMARY KEY (consumer_group, dedup_key)
);

CREATE TABLE IF NOT EXISTS account_projection (
  account_id VARCHAR(64) PRIMARY KEY,
  balance BIGINT NOT NULL,
  version BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS replay_audit (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  source VARCHAR(64) NOT NULL,
  dedup_key VARCHAR(64) NOT NULL,
  replayed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  operator_name VARCHAR(128) NULL,
  notes VARCHAR(255) NULL
);

INSERT INTO account (account_id, balance)
VALUES
  ('A-1', 0), ('A-2', 0), ('A-3', 0), ('A-4', 0), ('A-5', 0),
  ('A-6', 0), ('A-7', 0), ('A-8', 0), ('A-9', 0), ('A-10', 0)
ON DUPLICATE KEY UPDATE balance = VALUES(balance);

INSERT INTO account_projection (account_id, balance, version)
VALUES
  ('A-1', 0, 0), ('A-2', 0, 0), ('A-3', 0, 0), ('A-4', 0, 0), ('A-5', 0, 0),
  ('A-6', 0, 0), ('A-7', 0, 0), ('A-8', 0, 0), ('A-9', 0, 0), ('A-10', 0, 0)
ON DUPLICATE KEY UPDATE balance = VALUES(balance), version = VALUES(version);
