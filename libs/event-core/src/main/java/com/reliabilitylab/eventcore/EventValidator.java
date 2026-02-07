package com.reliabilitylab.eventcore;

import java.util.Objects;

public final class EventValidator {
    private EventValidator() {
    }

    public static EventEnvelope validate(EventEnvelope envelope) {
        Objects.requireNonNull(envelope, "envelope");
        require(envelope.eventId(), "event_id");
        require(envelope.dedupKey(), "dedup_key");
        require(envelope.eventType(), "event_type");
        require(envelope.payloadJson(), "payload");

        if (envelope.schemaVersion() <= 0) {
            throw new IllegalArgumentException("schema_version must be > 0");
        }
        if (envelope.occurredAt() <= 0) {
            throw new IllegalArgumentException("occurred_at must be > 0");
        }
        return envelope;
    }

    private static void require(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(field + " is required");
        }
    }
}
