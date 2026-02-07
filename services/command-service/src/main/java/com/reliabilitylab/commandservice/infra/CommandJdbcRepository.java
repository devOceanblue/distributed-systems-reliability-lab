package com.reliabilitylab.commandservice.infra;

import com.reliabilitylab.eventcore.EventEnvelope;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class CommandJdbcRepository {
    private final JdbcTemplate jdbcTemplate;

    public CommandJdbcRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public long applyDomainChange(String accountId, String txId, long amount) {
        jdbcTemplate.update(
                "INSERT INTO account(account_id, balance) VALUES (?, 0) ON DUPLICATE KEY UPDATE account_id = account_id",
                accountId
        );

        jdbcTemplate.update(
                "UPDATE account SET balance = balance + ? WHERE account_id = ?",
                amount,
                accountId
        );

        jdbcTemplate.update(
                "INSERT INTO ledger(tx_id, account_id, amount) VALUES (?, ?, ?)",
                txId,
                accountId,
                amount
        );

        Long balance = jdbcTemplate.queryForObject(
                "SELECT balance FROM account WHERE account_id = ?",
                Long.class,
                accountId
        );

        if (balance == null) {
            throw new IllegalStateException("account balance not found after update: " + accountId);
        }

        return balance;
    }

    public void insertOutbox(EventEnvelope envelope) {
        jdbcTemplate.update(
                """
                INSERT INTO outbox_event(event_id, dedup_key, event_type, payload_json, status, attempts)
                VALUES (?, ?, ?, CAST(? AS JSON), 'NEW', 0)
                """,
                envelope.eventId(),
                envelope.dedupKey(),
                envelope.eventType(),
                envelope.payloadJson()
        );
    }
}
