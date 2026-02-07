package com.reliabilitylab.e2e;

import com.fasterxml.jackson.databind.ObjectMapper;
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
import com.reliabilitylab.consumerservice.infra.ConsumerMessageMapper;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class SchemaDeployOrderE2ETest {
    private static final String ACCOUNT_ID = "A-1";

    private JdbcTemplate jdbcTemplate;
    private ConsumerProcessingService consumerProcessingService;

    @BeforeEach
    void setUp() {
        jdbcTemplate = new JdbcTemplate(new DriverManagerDataSource(
                "jdbc:h2:mem:e006-" + UUID.randomUUID() + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=ACCOUNT;DB_CLOSE_DELAY=-1",
                "sa",
                ""
        ));
        createSchema();
        consumerProcessingService = createConsumerService();
    }

    @Test
    void shouldFailInProducerFirstAndConvergeInConsumerFirstDualRead() {
        ConsumerServiceProperties strictProps = new ConsumerServiceProperties();
        strictProps.setSchemaReadMode(ConsumerServiceProperties.SchemaReadMode.V1_STRICT);
        ConsumerMessageMapper strictMapper = new ConsumerMessageMapper(new ObjectMapper(), strictProps);

        int parseFailures = 0;
        for (int i = 1; i <= 3; i++) {
            ConsumerRecord<String, String> v2Record = v2Record(i);
            assertThrows(IllegalArgumentException.class, () -> strictMapper.fromRecord(v2Record));
            parseFailures++;
        }
        assertEquals(3, parseFailures);
        assertEquals(0L, projectionBalance(ACCOUNT_ID));

        ConsumerServiceProperties dualProps = new ConsumerServiceProperties();
        dualProps.setSchemaReadMode(ConsumerServiceProperties.SchemaReadMode.DUAL_READ);
        ConsumerMessageMapper dualMapper = new ConsumerMessageMapper(new ObjectMapper(), dualProps);

        for (int i = 1; i <= 3; i++) {
            ProcessingInput input = dualMapper.fromRecord(v2Record(i));
            ProcessOutcome outcome = consumerProcessingService.consume(input, () -> {
            });
            assertEquals(ProcessOutcome.PROCESSED, outcome);
        }

        assertEquals(300L, projectionBalance(ACCOUNT_ID));
        assertEquals(3, count("SELECT COUNT(*) FROM processed_event WHERE consumer_group = 'consumer-service'"));
        assertEquals(0, count("SELECT COUNT(*) FROM account_projection WHERE account_id <> 'A-1'"));
    }

    private ConsumerRecord<String, String> v2Record(int seq) {
        String body = """
                {
                  "eventId":"evt-v2-%d",
                  "dedupKey":"e006-success-%d",
                  "eventType":"AccountBalanceChanged",
                  "payload":{"accountId":"A-1","amount":100,"tags":["vip","priority"]}
                }
                """.formatted(seq, seq);
        return new ConsumerRecord<>("account.balance.v1", 0, seq, ACCOUNT_ID, body);
    }

    private ConsumerProcessingService createConsumerService() {
        ConsumerServiceProperties properties = new ConsumerServiceProperties();
        properties.setConsumerGroup("consumer-service");
        properties.setIdempotencyMode(ConsumerServiceProperties.IdempotencyMode.PROCESSED_TABLE);
        properties.setOffsetCommitMode(ConsumerServiceProperties.OffsetCommitMode.AFTER_DB);

        return new ConsumerProcessingService(
                properties,
                new ConsumerTxHandler(new ConsumerJdbcRepository(jdbcTemplate), new NoopProjectionCacheInvalidator()),
                new NoopConsumerFailpointGuard(),
                new NoopDlqPublisher(),
                new NoopRetryPublisher()
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

    private void createSchema() {
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

    private static final class NoopProjectionCacheInvalidator implements ProjectionCacheInvalidator {
        @Override
        public void invalidate(String accountId) {
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
}
