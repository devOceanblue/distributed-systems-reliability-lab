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
import com.reliabilitylab.outboxrelay.app.RelayRunResult;
import com.reliabilitylab.outboxrelay.config.RelayProperties;
import com.reliabilitylab.outboxrelay.infra.OutboxEventRepository;
import com.reliabilitylab.replayworker.app.CapturedDlqEvent;
import com.reliabilitylab.replayworker.app.DlqEvent;
import com.reliabilitylab.replayworker.app.DlqReplayPublisher;
import com.reliabilitylab.replayworker.app.ReplayRunCommand;
import com.reliabilitylab.replayworker.app.ReplayRunResult;
import com.reliabilitylab.replayworker.app.ReplayWorkerService;
import com.reliabilitylab.replayworker.infra.JdbcDlqEventStore;
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
import static org.junit.jupiter.api.Assertions.assertTrue;

class RetryDlqReplayE2ETest {
    private static final String ACCOUNT_ID = "A-3";
    private static final String TOPIC_MAIN = "account.balance.v1";

    private final ObjectMapper objectMapper = new ObjectMapper();

    private JdbcTemplate jdbcTemplate;
    private CommandApplicationService commandApplicationService;
    private OutboxRelayService outboxRelayService;
    private ConsumerProcessingService failingConsumer;
    private ConsumerProcessingService healthyConsumer;
    private CapturingRelayPublisher relayPublisher;
    private CapturingDlqPublisher dlqPublisher;
    private CapturingReplayPublisher replayPublisher;
    private ReplayWorkerService replayWorkerService;

    @BeforeEach
    void setUp() {
        DataSource dataSource = new DriverManagerDataSource(
                "jdbc:h2:mem:e005-" + UUID.randomUUID() + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=ACCOUNT;DB_CLOSE_DELAY=-1",
                "sa",
                ""
        );
        jdbcTemplate = new JdbcTemplate(dataSource);
        createSchema(jdbcTemplate);

        commandApplicationService = createCommandService(jdbcTemplate);
        relayPublisher = new CapturingRelayPublisher();
        outboxRelayService = createRelayService(jdbcTemplate, relayPublisher);

        dlqPublisher = new CapturingDlqPublisher();
        failingConsumer = createConsumer(jdbcTemplate, ACCOUNT_ID, dlqPublisher);
        healthyConsumer = createConsumer(jdbcTemplate, "", new NoopDlqPublisher());

        replayPublisher = new CapturingReplayPublisher();
        replayWorkerService = new ReplayWorkerService(new JdbcDlqEventStore(jdbcTemplate), replayPublisher);
    }

    @Test
    void shouldRecoverFromDlqReplayAndStayIdempotentOnReplayDuplicates() throws Exception {
        for (int i = 1; i <= 5; i++) {
            commandApplicationService.deposit(ACCOUNT_ID, "e005-" + i, 100, "trace-e005-" + i);
        }
        assertEquals(5, count("SELECT COUNT(*) FROM outbox_event WHERE status = 'NEW'"));

        for (int i = 0; i < 5; i++) {
            RelayRunResult result = outboxRelayService.runOnce();
            assertTrue(result.processed());
            assertEquals("SENT", result.state());
        }
        assertEquals(5, relayPublisher.rows.size());
        assertEquals(5, count("SELECT COUNT(*) FROM outbox_event WHERE status = 'SENT'"));

        for (OutboxEventRow row : relayPublisher.rows) {
            ProcessOutcome outcome = failingConsumer.consume(toProcessingInput(row), () -> {
            });
            assertEquals(ProcessOutcome.DLQ, outcome);
        }
        assertEquals(5, dlqPublisher.events.size());
        assertEquals(0L, projectionBalance(ACCOUNT_ID));

        for (ProcessingInput input : dlqPublisher.events) {
            replayWorkerService.ingest(new CapturedDlqEvent(
                    input.eventId(),
                    input.dedupKey(),
                    input.eventType(),
                    input.accountId(),
                    input.amount(),
                    input.attempt(),
                    Instant.parse("2026-01-01T00:00:00Z"),
                    input.rawPayload()
            ));
        }
        assertEquals(5, count("SELECT COUNT(*) FROM dlq_event WHERE status = 'NEW'"));

        ReplayRunResult replayResult = replayWorkerService.run(new ReplayRunCommand(
                ACCOUNT_ID,
                ACCOUNT_ID,
                "AccountBalanceChanged",
                null,
                null,
                100,
                10,
                false,
                TOPIC_MAIN,
                "lab",
                "E-005 runtime replay"
        ));
        assertEquals(5, replayResult.scanned());
        assertEquals(5, replayResult.replayed());
        assertEquals(0, replayResult.skippedMissingDedup());
        assertEquals(5, replayPublisher.events.size());
        assertEquals(5, count("SELECT COUNT(*) FROM replay_audit WHERE source = 'dlq'"));
        assertEquals(5, count("SELECT COUNT(*) FROM dlq_event WHERE status = 'REPLAYED'"));

        for (DlqEvent event : replayPublisher.events) {
            ProcessOutcome outcome = healthyConsumer.consume(toProcessingInput(event), () -> {
            });
            assertEquals(ProcessOutcome.PROCESSED, outcome);
        }

        for (DlqEvent event : replayPublisher.events) {
            ProcessOutcome outcome = healthyConsumer.consume(toProcessingInput(event), () -> {
            });
            assertEquals(ProcessOutcome.DUPLICATE_SKIPPED, outcome);
        }

        assertEquals(500L, projectionBalance(ACCOUNT_ID));
        assertEquals(5, count("SELECT COUNT(*) FROM processed_event WHERE consumer_group = 'consumer-service'"));
    }

    private CommandApplicationService createCommandService(JdbcTemplate jdbcTemplate) {
        CommandJdbcRepository commandJdbcRepository = new CommandJdbcRepository(jdbcTemplate);
        CommandTxHandler commandTxHandler = new CommandTxHandler(
                commandJdbcRepository,
                new EventEnvelopeBuilder(Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC)),
                objectMapper
        );

        CommandServiceProperties commandProperties = new CommandServiceProperties();
        commandProperties.setProduceMode(CommandServiceProperties.ProduceMode.OUTBOX);

        return new CommandApplicationService(
                commandTxHandler,
                new NoopBalanceEventPublisher(),
                commandProperties,
                new NoopCommandFailpointGuard()
        );
    }

    private OutboxRelayService createRelayService(JdbcTemplate jdbcTemplate, RelayPublisher relayPublisher) {
        RelayProperties relayProperties = new RelayProperties();
        relayProperties.setLockingMode(RelayProperties.LockingMode.SIMPLE);
        relayProperties.setBackoffSeconds(List.of(0L));
        relayProperties.setMaxAttempts(5);

        return new OutboxRelayService(
                new OutboxEventRepository(jdbcTemplate),
                relayPublisher,
                new NoopRelayFailpointGuard(),
                relayProperties,
                Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC)
        );
    }

    private ConsumerProcessingService createConsumer(JdbcTemplate jdbcTemplate,
                                                     String forcePermanentAccountId,
                                                     DlqPublisher dlqPublisher) {
        ConsumerServiceProperties consumerProperties = new ConsumerServiceProperties();
        consumerProperties.setConsumerGroup("consumer-service");
        consumerProperties.setIdempotencyMode(ConsumerServiceProperties.IdempotencyMode.PROCESSED_TABLE);
        consumerProperties.setOffsetCommitMode(ConsumerServiceProperties.OffsetCommitMode.AFTER_DB);
        consumerProperties.setForcePermanentErrorOnAccountId(forcePermanentAccountId);

        return new ConsumerProcessingService(
                consumerProperties,
                new ConsumerTxHandler(
                        new ConsumerJdbcRepository(jdbcTemplate),
                        new NoopProjectionCacheInvalidator()
                ),
                new NoopConsumerFailpointGuard(),
                dlqPublisher,
                new NoopRetryPublisher()
        );
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
                TOPIC_MAIN,
                0,
                0,
                0
        );
    }

    private ProcessingInput toProcessingInput(DlqEvent event) {
        return new ProcessingInput(
                event.eventId(),
                event.dedupKey(),
                event.eventType(),
                event.accountId(),
                event.amount(),
                event.rawPayload(),
                TOPIC_MAIN,
                0,
                0,
                event.attempt()
        );
    }

    private long projectionBalance(String accountId) {
        List<Long> values = jdbcTemplate.query(
                "SELECT balance FROM account_projection WHERE account_id = ?",
                (rs, rowNum) -> rs.getLong("balance"),
                accountId
        );
        return values.isEmpty() ? 0L : values.getFirst();
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

    private static final class NoopRelayFailpointGuard implements RelayFailpointGuard {
        @Override
        public void check(String envName) {
        }
    }

    private static final class NoopConsumerFailpointGuard implements ConsumerFailpointGuard {
        @Override
        public void check(String envName) {
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

    private static final class NoopDlqPublisher implements DlqPublisher {
        @Override
        public void publish(ProcessingInput input, Exception exception) {
        }
    }

    private static final class CapturingRelayPublisher implements RelayPublisher {
        private final List<OutboxEventRow> rows = new ArrayList<>();

        @Override
        public void publish(OutboxEventRow row) {
            rows.add(row);
        }
    }

    private static final class CapturingDlqPublisher implements DlqPublisher {
        private final List<ProcessingInput> events = new ArrayList<>();

        @Override
        public void publish(ProcessingInput input, Exception exception) {
            events.add(input);
        }
    }

    private static final class CapturingReplayPublisher implements DlqReplayPublisher {
        private final List<DlqEvent> events = new ArrayList<>();

        @Override
        public void publish(DlqEvent event, String outputTopic) {
            events.add(event);
        }
    }
}
