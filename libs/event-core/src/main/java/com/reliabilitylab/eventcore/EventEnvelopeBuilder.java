package com.reliabilitylab.eventcore;

import java.time.Clock;
import java.util.Objects;
import java.util.UUID;

public final class EventEnvelopeBuilder {
    private final Clock clock;

    public EventEnvelopeBuilder(Clock clock) {
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    public EventEnvelope newEnvelope(String dedupKey, String eventType, int schemaVersion, String traceId, String payloadJson) {
        return EventValidator.validate(new EventEnvelope(
                UUID.randomUUID().toString(),
                dedupKey,
                eventType,
                schemaVersion,
                clock.millis(),
                traceId,
                payloadJson
        ));
    }
}
