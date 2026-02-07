package com.reliabilitylab.consumerservice.infra;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.consumerservice.app.ProcessingInput;
import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.stereotype.Component;

@Component
public class ConsumerMessageMapper {
    private final ObjectMapper objectMapper;
    private final ConsumerServiceProperties properties;

    public ConsumerMessageMapper(ObjectMapper objectMapper,
                                 ConsumerServiceProperties properties) {
        this.objectMapper = objectMapper;
        this.properties = properties;
    }

    public ProcessingInput fromRecord(ConsumerRecord<String, String> record) {
        try {
            JsonNode root = objectMapper.readTree(record.value());
            JsonNode payloadNode = root.get("payload");

            String eventId = text(root, "event_id", text(root, "eventId", ""));
            String dedupKey = text(root, "dedup_key", text(root, "dedupKey", ""));
            String eventType = text(root, "event_type", text(root, "eventType", ""));
            validateTagsField(payloadNode);
            String accountId = text(payloadNode, "accountId", text(payloadNode, "account_id", ""));
            long amount = longValue(payloadNode, "amount");

            return new ProcessingInput(
                    eventId,
                    dedupKey,
                    eventType,
                    accountId,
                    amount,
                    payloadNode == null ? "{}" : payloadNode.toString(),
                    record.topic(),
                    record.partition(),
                    record.offset(),
                    0
            );
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("failed to parse consumer record", e);
        }
    }

    private void validateTagsField(JsonNode payloadNode) {
        if (payloadNode == null) {
            return;
        }

        JsonNode tags = payloadNode.get("tags");
        if (tags == null || tags.isNull()) {
            return;
        }

        if (tags.isTextual()) {
            return;
        }

        if (tags.isArray() && properties.getSchemaReadMode() == ConsumerServiceProperties.SchemaReadMode.DUAL_READ) {
            return;
        }

        throw new IllegalArgumentException("unsupported tags field for schema_read_mode=" + properties.getSchemaReadMode());
    }

    private String text(JsonNode root, String field, String fallback) {
        if (root == null) {
            return fallback;
        }
        JsonNode value = root.get(field);
        if (value == null || value.isNull()) {
            return fallback;
        }
        return value.asText();
    }

    private long longValue(JsonNode root, String field) {
        if (root == null) {
            return 0L;
        }
        JsonNode value = root.get(field);
        if (value == null || value.isNull()) {
            return 0L;
        }
        return value.asLong();
    }
}
