package com.reliabilitylab.consumerservice.infra;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.consumerservice.app.ProcessingInput;
import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ConsumerMessageMapperTest {

    @Test
    void shouldFailInStrictModeWhenTagsIsArray() {
        ConsumerServiceProperties properties = new ConsumerServiceProperties();
        properties.setSchemaReadMode(ConsumerServiceProperties.SchemaReadMode.V1_STRICT);
        ConsumerMessageMapper mapper = new ConsumerMessageMapper(new ObjectMapper(), properties);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> mapper.fromRecord(record("""
                        {
                          "eventId":"evt-1",
                          "dedupKey":"tx-1",
                          "eventType":"AccountBalanceChanged",
                          "payload":{"accountId":"A-1","amount":100,"tags":["vip","priority"]}
                        }
                        """)));

        assertEquals("unsupported tags field for schema_read_mode=V1_STRICT", ex.getMessage());
    }

    @Test
    void shouldAllowStringTagsInStrictMode() {
        ConsumerServiceProperties properties = new ConsumerServiceProperties();
        properties.setSchemaReadMode(ConsumerServiceProperties.SchemaReadMode.V1_STRICT);
        ConsumerMessageMapper mapper = new ConsumerMessageMapper(new ObjectMapper(), properties);

        ProcessingInput input = mapper.fromRecord(record("""
                {
                  "eventId":"evt-2",
                  "dedupKey":"tx-2",
                  "eventType":"AccountBalanceChanged",
                  "payload":{"accountId":"A-2","amount":200,"tags":"vip"}
                }
                """));

        assertEquals("evt-2", input.eventId());
        assertEquals("tx-2", input.dedupKey());
        assertEquals("A-2", input.accountId());
        assertEquals(200L, input.amount());
    }

    @Test
    void shouldAllowArrayTagsInDualReadMode() {
        ConsumerServiceProperties properties = new ConsumerServiceProperties();
        properties.setSchemaReadMode(ConsumerServiceProperties.SchemaReadMode.DUAL_READ);
        ConsumerMessageMapper mapper = new ConsumerMessageMapper(new ObjectMapper(), properties);

        ProcessingInput input = mapper.fromRecord(record("""
                {
                  "eventId":"evt-3",
                  "dedupKey":"tx-3",
                  "eventType":"AccountBalanceChanged",
                  "payload":{"accountId":"A-3","amount":300,"tags":["vip","priority"]}
                }
                """));

        assertEquals("evt-3", input.eventId());
        assertEquals("tx-3", input.dedupKey());
        assertEquals("A-3", input.accountId());
        assertEquals(300L, input.amount());
    }

    private static ConsumerRecord<String, String> record(String payload) {
        return new ConsumerRecord<>("account.balance.v1", 0, 0L, "A-1", payload);
    }
}
