package com.reliabilitylab.eventcore;

import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class EventValidatorTest {

    @Test
    void shouldBuildAndValidateEnvelope() {
        EventEnvelopeBuilder builder = new EventEnvelopeBuilder(
                Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC)
        );

        EventEnvelope envelope = builder.newEnvelope("tx-1", "AccountBalanceChanged", 1, "trace-1", "{}");

        assertEquals("tx-1", envelope.dedupKey());
        assertEquals(1767225600000L, envelope.occurredAt());
    }

    @Test
    void shouldFailWhenDedupKeyMissing() {
        IllegalArgumentException error = assertThrows(IllegalArgumentException.class,
                () -> EventValidator.validate(new EventEnvelope(
                        "e1", "", "AccountBalanceChanged", 1, 1L, null, "{}"
                )));

        assertEquals("dedup_key is required", error.getMessage());
    }
}
