package com.reliabilitylab.outboxrelay.infra;

import com.reliabilitylab.outboxrelay.app.OutboxEventRow;
import com.reliabilitylab.outboxrelay.config.RelayProperties;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public class OutboxEventRepository {
    private static final RowMapper<OutboxEventRow> ROW_MAPPER = new OutboxRowMapper();

    private final JdbcTemplate jdbcTemplate;

    public OutboxEventRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public Optional<OutboxEventRow> lockAndMarkSending(RelayProperties.LockingMode lockingMode) {
        List<OutboxEventRow> rows = jdbcTemplate.query(selectQuery(lockingMode), ROW_MAPPER);
        if (rows.isEmpty()) {
            return Optional.empty();
        }

        OutboxEventRow row = rows.get(0);
        int updated = jdbcTemplate.update(
                """
                UPDATE outbox_event
                SET status = 'SENDING', updated_at = CURRENT_TIMESTAMP
                WHERE id = ? AND status = 'NEW'
                """,
                row.id()
        );

        if (updated == 0) {
            return Optional.empty();
        }

        return Optional.of(row);
    }

    public void markSent(long id) {
        jdbcTemplate.update(
                """
                UPDATE outbox_event
                SET status = 'SENT', updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                id
        );
    }

    public void reschedule(long id, int attempts, Instant nextAttemptAt, String lastError) {
        jdbcTemplate.update(
                """
                UPDATE outbox_event
                SET status = 'NEW',
                    attempts = ?,
                    next_attempt_at = ?,
                    last_error = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                attempts,
                Timestamp.from(nextAttemptAt),
                lastError,
                id
        );
    }

    public void markFailed(long id, int attempts, String lastError) {
        jdbcTemplate.update(
                """
                UPDATE outbox_event
                SET status = 'FAILED',
                    attempts = ?,
                    next_attempt_at = NULL,
                    last_error = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                attempts,
                lastError,
                id
        );
    }

    private String selectQuery(RelayProperties.LockingMode lockingMode) {
        String base = """
                SELECT id, event_id, dedup_key, event_type, payload_json, attempts
                FROM outbox_event
                WHERE status = 'NEW'
                  AND (next_attempt_at IS NULL OR next_attempt_at <= CURRENT_TIMESTAMP)
                ORDER BY id
                LIMIT 1
                """;
        if (lockingMode == RelayProperties.LockingMode.SKIP_LOCKED) {
            return base + " FOR UPDATE SKIP LOCKED";
        }
        return base;
    }

    private static final class OutboxRowMapper implements RowMapper<OutboxEventRow> {
        @Override
        public OutboxEventRow mapRow(ResultSet rs, int rowNum) throws SQLException {
            return new OutboxEventRow(
                    rs.getLong("id"),
                    rs.getString("event_id"),
                    rs.getString("dedup_key"),
                    rs.getString("event_type"),
                    rs.getString("payload_json"),
                    rs.getInt("attempts")
            );
        }
    }
}
