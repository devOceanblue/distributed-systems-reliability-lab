package com.reliabilitylab.replayworker.infra;

import com.reliabilitylab.replayworker.app.CapturedDlqEvent;
import com.reliabilitylab.replayworker.app.DlqEvent;
import com.reliabilitylab.replayworker.app.ReplayRunCommand;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

class JdbcDlqEventStoreTest {
    private JdbcTemplate jdbcTemplate;
    private JdbcDlqEventStore store;

    @BeforeEach
    void setUp() {
        jdbcTemplate = new JdbcTemplate(new DriverManagerDataSource(
                "jdbc:h2:mem:replay-" + UUID.randomUUID() + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=ACCOUNT;DB_CLOSE_DELAY=-1",
                "sa",
                ""
        ));
        createSchema();
        store = new JdbcDlqEventStore(jdbcTemplate);
    }

    @Test
    void shouldFilterByAccountEventTypeAndTimeWindow() {
        store.insertCapturedEvent(new CapturedDlqEvent(
                "evt-1", "tx-1", "AccountBalanceChanged", "A-1", 100, 1, Instant.ofEpochMilli(1000), "{}"));
        store.insertCapturedEvent(new CapturedDlqEvent(
                "evt-2", "tx-2", "AccountBalanceChanged", "A-5", 200, 1, Instant.ofEpochMilli(2000), "{}"));
        store.insertCapturedEvent(new CapturedDlqEvent(
                "evt-3", "tx-3", "AnotherEvent", "A-8", 300, 1, Instant.ofEpochMilli(3000), "{}"));

        ReplayRunCommand command = new ReplayRunCommand(
                "A-2",
                "A-7",
                "AccountBalanceChanged",
                1500L,
                2500L,
                100,
                10,
                false,
                "account.balance.v1",
                "tester",
                null
        );

        List<DlqEvent> found = store.findPending(command);
        assertEquals(1, found.size());
        assertEquals("tx-2", found.getFirst().dedupKey());
    }

    @Test
    void shouldMarkReplayAndInsertAudit() {
        store.insertCapturedEvent(new CapturedDlqEvent(
                "evt-10", "tx-10", "AccountBalanceChanged", "A-10", 10, 1, Instant.ofEpochMilli(1000), "{}"));
        long id = jdbcTemplate.queryForObject("SELECT id FROM dlq_event WHERE event_id = 'evt-10'", Long.class);

        store.markReplayed(id);
        store.insertReplayAudit("tx-10", "tester", "manual-run");

        String status = jdbcTemplate.queryForObject("SELECT status FROM dlq_event WHERE id = ?", String.class, id);
        Integer auditCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM replay_audit WHERE dedup_key = 'tx-10'", Integer.class);

        assertEquals("REPLAYED", status);
        assertEquals(1, auditCount);
    }

    private void createSchema() {
        jdbcTemplate.execute("""
                CREATE TABLE replay_audit (
                  id BIGINT AUTO_INCREMENT PRIMARY KEY,
                  source VARCHAR(64) NOT NULL,
                  dedup_key VARCHAR(64) NOT NULL,
                  replayed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  operator_name VARCHAR(128),
                  notes VARCHAR(255)
                )
                """);

        jdbcTemplate.execute("""
                CREATE TABLE dlq_event (
                  id BIGINT AUTO_INCREMENT PRIMARY KEY,
                  event_id VARCHAR(64) NOT NULL,
                  dedup_key VARCHAR(64),
                  event_type VARCHAR(128),
                  account_id VARCHAR(64),
                  amount BIGINT NOT NULL,
                  attempt INT NOT NULL,
                  occurred_at TIMESTAMP,
                  raw_payload VARCHAR(4096) NOT NULL,
                  status VARCHAR(16) NOT NULL,
                  skip_reason VARCHAR(255),
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  replayed_at TIMESTAMP,
                  CONSTRAINT uk_dlq_event_event_id UNIQUE(event_id)
                )
                """);
    }
}
