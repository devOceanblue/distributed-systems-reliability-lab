package com.reliabilitylab.replayworker.infra;

import com.reliabilitylab.replayworker.app.CapturedDlqEvent;
import com.reliabilitylab.replayworker.app.DlqEvent;
import com.reliabilitylab.replayworker.app.DlqEventStore;
import com.reliabilitylab.replayworker.app.ReplayRunCommand;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Repository
public class JdbcDlqEventStore implements DlqEventStore {
    private final JdbcTemplate jdbcTemplate;

    public JdbcDlqEventStore(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void insertCapturedEvent(CapturedDlqEvent event) {
        jdbcTemplate.update(
                """
                INSERT INTO dlq_event(event_id, dedup_key, event_type, account_id, amount, attempt, occurred_at, raw_payload, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'NEW')
                ON DUPLICATE KEY UPDATE
                  dedup_key = VALUES(dedup_key),
                  event_type = VALUES(event_type),
                  account_id = VALUES(account_id),
                  amount = VALUES(amount),
                  attempt = VALUES(attempt),
                  occurred_at = VALUES(occurred_at),
                  raw_payload = VALUES(raw_payload),
                  status = 'NEW',
                  skip_reason = NULL
                """,
                event.eventId(),
                event.dedupKey(),
                event.eventType(),
                event.accountId(),
                event.amount(),
                event.attempt(),
                Timestamp.from(event.occurredAt()),
                event.rawPayload()
        );
    }

    @Override
    public List<DlqEvent> findPending(ReplayRunCommand command) {
        StringBuilder sql = new StringBuilder("""
                SELECT id, event_id, dedup_key, event_type, account_id, amount, attempt, occurred_at, raw_payload
                FROM dlq_event
                WHERE status = 'NEW'
                """);
        List<Object> params = new ArrayList<>();

        if (command.accountIdFrom() != null && !command.accountIdFrom().isBlank()) {
            sql.append(" AND account_id >= ?");
            params.add(command.accountIdFrom());
        }
        if (command.accountIdTo() != null && !command.accountIdTo().isBlank()) {
            sql.append(" AND account_id <= ?");
            params.add(command.accountIdTo());
        }
        if (command.eventType() != null && !command.eventType().isBlank()) {
            sql.append(" AND event_type = ?");
            params.add(command.eventType());
        }
        if (command.fromEpochMillis() != null) {
            sql.append(" AND occurred_at >= ?");
            params.add(Timestamp.from(Instant.ofEpochMilli(command.fromEpochMillis())));
        }
        if (command.toEpochMillis() != null) {
            sql.append(" AND occurred_at <= ?");
            params.add(Timestamp.from(Instant.ofEpochMilli(command.toEpochMillis())));
        }

        sql.append(" ORDER BY id ASC LIMIT ?");
        params.add(command.batchSize());

        return jdbcTemplate.query(sql.toString(), this::mapRow, params.toArray());
    }

    @Override
    public void markReplayed(long id) {
        jdbcTemplate.update(
                """
                UPDATE dlq_event
                SET status = 'REPLAYED',
                    replayed_at = CURRENT_TIMESTAMP,
                    skip_reason = NULL
                WHERE id = ?
                """,
                id
        );
    }

    @Override
    public void markSkipped(long id, String reason) {
        jdbcTemplate.update(
                """
                UPDATE dlq_event
                SET status = 'SKIPPED',
                    skip_reason = ?,
                    replayed_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                reason,
                id
        );
    }

    @Override
    public void insertReplayAudit(String dedupKey, String operatorName, String notes) {
        jdbcTemplate.update(
                """
                INSERT INTO replay_audit(source, dedup_key, operator_name, notes)
                VALUES ('dlq', ?, ?, ?)
                """,
                dedupKey,
                operatorName,
                notes
        );
    }

    private DlqEvent mapRow(ResultSet rs, int rowNum) throws SQLException {
        Timestamp occurredAt = rs.getTimestamp("occurred_at");
        return new DlqEvent(
                rs.getLong("id"),
                rs.getString("event_id"),
                rs.getString("dedup_key"),
                rs.getString("event_type"),
                rs.getString("account_id"),
                rs.getLong("amount"),
                rs.getInt("attempt"),
                occurredAt == null ? Instant.EPOCH : occurredAt.toInstant(),
                rs.getString("raw_payload")
        );
    }
}
