package com.reliabilitylab.consumerservice.infra;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ConsumerJdbcRepository {
    private final JdbcTemplate jdbcTemplate;

    public ConsumerJdbcRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public boolean tryInsertProcessed(String consumerGroup, String dedupKey, String topic, int partition, long offset) {
        int inserted = jdbcTemplate.update(
                """
                INSERT IGNORE INTO processed_event(consumer_group, dedup_key, topic, partition_no, offset_no)
                VALUES (?, ?, ?, ?, ?)
                """,
                consumerGroup,
                dedupKey,
                topic,
                partition,
                offset
        );
        return inserted > 0;
    }

    public void applyProjectionDelta(String accountId, long amount) {
        jdbcTemplate.update(
                """
                INSERT INTO account_projection(account_id, balance, version)
                VALUES (?, 0, 0)
                ON DUPLICATE KEY UPDATE account_id = account_id
                """,
                accountId
        );

        jdbcTemplate.update(
                """
                UPDATE account_projection
                SET balance = balance + ?, version = version + 1, updated_at = CURRENT_TIMESTAMP
                WHERE account_id = ?
                """,
                amount,
                accountId
        );
    }
}
