CREATE TABLE IF NOT EXISTS processed_event_archive (
  consumer_group VARCHAR(128) NOT NULL,
  dedup_key VARCHAR(64) NOT NULL,
  processed_at TIMESTAMP NOT NULL,
  topic VARCHAR(255) NULL,
  partition_no INT NULL,
  offset_no BIGINT NULL,
  PRIMARY KEY (consumer_group, dedup_key)
);

CREATE TABLE IF NOT EXISTS backfill_job (
  job_id VARCHAR(64) PRIMARY KEY,
  operator_name VARCHAR(128) NOT NULL,
  mode VARCHAR(16) NOT NULL,
  filters_json JSON NOT NULL,
  shard_count INT NOT NULL,
  shard_index INT NOT NULL,
  rate_limit INT NOT NULL,
  batch_size INT NOT NULL,
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP NULL,
  status VARCHAR(16) NOT NULL,
  processed_count BIGINT NOT NULL DEFAULT 0,
  error_count BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS backfill_checkpoint (
  job_id VARCHAR(64) NOT NULL,
  shard_index INT NOT NULL,
  checkpoint_value VARCHAR(255) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (job_id, shard_index)
);
