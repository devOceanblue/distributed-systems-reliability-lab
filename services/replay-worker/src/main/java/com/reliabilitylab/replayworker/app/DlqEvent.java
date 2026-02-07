package com.reliabilitylab.replayworker.app;

import java.time.Instant;

public record DlqEvent(
        long id,
        String eventId,
        String dedupKey,
        String eventType,
        String accountId,
        long amount,
        int attempt,
        Instant occurredAt,
        String rawPayload
) {
}
