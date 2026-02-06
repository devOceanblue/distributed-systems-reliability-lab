package com.reliabilitylab.eventcore;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public record EventEnvelope(
    String eventId,
    String dedupKey,
    String eventType,
    String schemaVersion,
    Instant occurredAt,
    String traceId,
    byte[] payload
) {
  public EventEnvelope {
    Objects.requireNonNull(eventId, "eventId");
    Objects.requireNonNull(dedupKey, "dedupKey");
    Objects.requireNonNull(eventType, "eventType");
    Objects.requireNonNull(schemaVersion, "schemaVersion");
    Objects.requireNonNull(occurredAt, "occurredAt");
    Objects.requireNonNull(payload, "payload");
  }

  public static EventEnvelope of(String dedupKey, String eventType, String schemaVersion, byte[] payload) {
    return new EventEnvelope(
        UUID.randomUUID().toString(),
        dedupKey,
        eventType,
        schemaVersion,
        Instant.now(),
        null,
        payload
    );
  }
}
