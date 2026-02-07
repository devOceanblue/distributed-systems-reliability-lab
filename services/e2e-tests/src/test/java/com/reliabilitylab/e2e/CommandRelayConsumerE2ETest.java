package com.reliabilitylab.e2e;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.commandservice.app.CommandApplicationService;
import com.reliabilitylab.commandservice.app.CommandTxHandler;
import com.reliabilitylab.commandservice.app.FailpointGuard;
import com.reliabilitylab.commandservice.config.CommandServiceProperties;
import com.reliabilitylab.commandservice.infra.BalanceEventPublisher;
import com.reliabilitylab.commandservice.infra.CommandJdbcRepository;
import com.reliabilitylab.consumerservice.app.ConsumerFailpointGuard;
import com.reliabilitylab.consumerservice.app.ConsumerProcessingService;
import com.reliabilitylab.consumerservice.app.ConsumerTxHandler;
import com.reliabilitylab.consumerservice.app.DlqPublisher;
import com.reliabilitylab.consumerservice.app.ProcessOutcome;
import com.reliabilitylab.consumerservice.app.ProcessingInput;
import com.reliabilitylab.consumerservice.app.ProjectionCacheInvalidator;
import com.reliabilitylab.consumerservice.app.RetryPublisher;
import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import com.reliabilitylab.consumerservice.infra.ConsumerJdbcRepository;
import com.reliabilitylab.eventcore.EventEnvelopeBuilder;
import com.reliabilitylab.outboxrelay.app.OutboxEventRow;
import com.reliabilitylab.outboxrelay.app.OutboxRelayService;
import com.reliabilitylab.outboxrelay.app.RelayFailpointGuard;
import com.reliabilitylab.outboxrelay.app.RelayPublisher;
import com.reliabilitylab.outboxrelay.config.RelayProperties;
import com.reliabilitylab.outboxrelay.infra.OutboxEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CommandRelayConsumerE2ETest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    private JdbcTemplate jdbcTemplate;
    private CommandApplicationService commandApplicationService;
    private OutboxRelayService outboxRelayService;
    private ConsumerProcessingService consumerProcessingService;
    private CapturingRelayPublisher capturingRelayPublisher;
    private ToggleFailpointGuard toggleFailpointGuard;

    @BeforeEach
    void setUp() {
        DataSource dataSource = new DriverManagerDataSource(
                "jdbc:h2:mem:e2e-" + UUID.randomUUID() + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=ACCOUNT;DB_CLOSE_DELAY=-1",
                "sa",
                ""
        );

        jdbcTemplate = new JdbcTemplate(dataSource);
        createSchema(jdbcTemplate);

        CommandJdbcRepository commandJdbcRepository = new CommandJdbcRepository(jdbcTemplate);
        CommandTxHandler commandTxHandler = new CommandTxHandler(
                commandJdbcRepository,
                new EventEnvelopeBuilder(Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC)),
                objectMapper
        );

        CommandServiceProperties commandProperties = new CommandServiceProperties();
        commandProperties.setProduceMode(CommandServiceProperties.ProduceMode.OUTBOX);

        commandApplicationService = new CommandApplicationService(
                commandTxHandler,
                new NoopBalanceEventPublisher(),
                commandProperties,
                new NoopCommandFailpointGuard()
        );

        RelayProperties relayProperties = new RelayProperties();
        relayProperties.setLockingMode(RelayProperties.LockingMode.SIMPLE);
        relayProperties.setBackoffSeconds(List.of(0L));
        relayProperties.setMaxAttempts(5);

        capturingRelayPublisher = new CapturingRelayPublisher();
        toggleFailpointGuard = new ToggleFailpointGuard();
        outboxRelayService = new OutboxRelayService(
                new OutboxEventRepository(jdbcTemplate),
                capturingRelayPublisher,
                toggleFailpointGuard,
                relayProperties,
                Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC)
        );

        ConsumerServiceProperties consumerProperties = new ConsumerServiceProperties();
        consumerProperties.setConsumerGroup("consumer-service");
        consumerProperties.setIdempotencyMode(ConsumerServiceProperties.IdempotencyMode.PROCESSED_TABLE);
        consumerProperties.setOffsetCommitMode(ConsumerServiceProperties.OffsetCommitMode.AFTER_DB);

        consumerProcessingService = new ConsumerProcessingService(
                consumerProperties,
                new ConsumerTxHandler(new ConsumerJdbcRepository(jdbcTemplate), new NoopProjectionCacheInvalidator()),
                new NoopConsumerFailpointGuard(),
                new NoopDlqPublisher(),
                new NoopRetryPublisher()
        );
    }

    @Test
    void shouldFlowFromCommandToRelayToConsumer() throws Exception {
        commandApplicationService.deposit("A-1", "tx-e2e-1", 100, "trace-e2e-1");

        assertEquals(1, count("SELECT COUNT(*) FROM outbox_event WHERE status = 'NEW'"));

        outboxRelayService.runOnce();

        assertEquals(1, count("SELECT COUNT(*) FROM outbox_event WHERE status = 'SENT'"));
        assertEquals(1, capturingRelayPublisher.rows.size());

        ProcessingInput input = toProcessingInput(capturingRelayPublisher.rows.get(0));
        assertEquals("A-1", input.accountId());
        ProcessOutcome outcome = consumerProcessingService.consume(input, () -> {
        });

        assertEquals(ProcessOutcome.PROCESSED, outcome);
        assertEquals(100L, queryProjectionBalance("A-1"));
        assertEquals(1, count("SELECT COUNT(*) FROM processed_event"));
    }

    @Test
    void shouldAbsorbDuplicateWhenRelayRepublishesAfterFailpoint() throws Exception {
        commandApplicationService.deposit("A-2", "tx-e2e-dup", 100, "trace-e2e-dup");

        toggleFailpointGuard.throwAfterSendOnce = true;
        assertThrows(RuntimeException.class, () -> outboxRelayService.runOnce());

        assertEquals(1, count("SELECT COUNT(*) FROM outbox_event WHERE status = 'NEW'"));

        outboxRelayService.runOnce();

        assertEquals(2, capturingRelayPublisher.rows.size());

        for (OutboxEventRow row : capturingRelayPublisher.rows) {
            ProcessOutcome outcome = consumerProcessingService.consume(toProcessingInput(row), () -> {
            });
            if (row == capturingRelayPublisher.rows.get(0)) {
                assertEquals(ProcessOutcome.PROCESSED, outcome);
            } else {
                assertEquals(ProcessOutcome.DUPLICATE_SKIPPED, outcome);
            }
        }

        assertEquals(100L, queryProjectionBalance("A-2"));
        assertEquals(1, count("SELECT COUNT(*) FROM processed_event WHERE dedup_key = 'tx-e2e-dup'"));
    }

    private ProcessingInput toProcessingInput(OutboxEventRow row) throws Exception {
        JsonNode payload = objectMapper.readTree(row.payloadJson());
        if (payload.isTextual()) {
            payload = objectMapper.readTree(payload.asText());
        }
        return new ProcessingInput(
                row.eventId(),
                row.dedupKey(),
                row.eventType(),
                payload.path("accountId").asText(),
                payload.path("amount").asLong(),
                row.payloadJson(),
                "account.balance.v1",
                0,
                0,
                0
        );
    }

    private long queryProjectionBalance(String accountId) {
        Long value = jdbcTemplate.queryForObject(
                "SELECT balance FROM account_projection WHERE account_id = ?",
                Long.class,
                accountId
        );
        return value == null ? 0L : value;
    }

    private int count(String sql) {
        Integer value = jdbcTemplate.queryForObject(sql, Integer.class);
        return value == null ? 0 : value;
    }

    private static void createSchema(JdbcTemplate jdbcTemplate) {
        jdbcTemplate.execute("""
                CREATE TABLE account (
                  account_id VARCHAR(64) PRIMARY KEY,
                  balance BIGINT NOT NULL,
                  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """);

        jdbcTemplate.execute("""
                CREATE TABLE ledger (
                  tx_id VARCHAR(64) PRIMARY KEY,
                  account_id VARCHAR(64) NOT NULL,
                  amount BIGINT NOT NULL,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """);

        jdbcTemplate.execute("""
                CREATE TABLE outbox_event (
                  id BIGINT AUTO_INCREMENT PRIMARY KEY,
                  event_id VARCHAR(64) NOT NULL,
                  dedup_key VARCHAR(64) NOT NULL,
                  event_type VARCHAR(128) NOT NULL,
                  payload_json VARCHAR(4096) NOT NULL,
                  status VARCHAR(16) NOT NULL,
                  attempts INT NOT NULL,
                  next_attempt_at TIMESTAMP NULL,
                  last_error VARCHAR(1024) NULL,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  CONSTRAINT uk_outbox_dedup UNIQUE(dedup_key)
                )
                """);

        jdbcTemplate.execute("""
                CREATE TABLE processed_event (
                  consumer_group VARCHAR(128) NOT NULL,
                  dedup_key VARCHAR(64) NOT NULL,
                  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  topic VARCHAR(255),
                  partition_no INT,
                  offset_no BIGINT,
                  PRIMARY KEY (consumer_group, dedup_key)
                )
                """);

        jdbcTemplate.execute("""
                CREATE TABLE account_projection (
                  account_id VARCHAR(64) PRIMARY KEY,
                  balance BIGINT NOT NULL,
                  version BIGINT NOT NULL,
                  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """);
    }

    private static final class NoopBalanceEventPublisher implements BalanceEventPublisher {
        @Override
        public void publish(com.reliabilitylab.eventcore.EventEnvelope envelope, String accountId) {
        }
    }

    private static final class NoopCommandFailpointGuard implements FailpointGuard {
        @Override
        public void check(String envName) {
        }
    }

    private static final class NoopConsumerFailpointGuard implements ConsumerFailpointGuard {
        @Override
        public void check(String envName) {
        }
    }

    private static final class NoopDlqPublisher implements DlqPublisher {
        @Override
        public void publish(ProcessingInput input, Exception exception) {
        }
    }

    private static final class NoopRetryPublisher implements RetryPublisher {
        @Override
        public void publish(ProcessingInput input, Exception exception) {
        }
    }

    private static final class NoopProjectionCacheInvalidator implements ProjectionCacheInvalidator {
        @Override
        public void invalidate(String accountId) {
        }
    }

    private static final class CapturingRelayPublisher implements RelayPublisher {
        private final List<OutboxEventRow> rows = new ArrayList<>();

        @Override
        public void publish(OutboxEventRow row) {
            rows.add(row);
        }
    }

    private static final class ToggleFailpointGuard implements RelayFailpointGuard {
        private boolean throwAfterSendOnce;

        @Override
        public void check(String envName) {
            if (throwAfterSendOnce && "FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT".equals(envName)) {
                throwAfterSendOnce = false;
                throw new RuntimeException("forced failpoint");
            }
        }
    }
}
