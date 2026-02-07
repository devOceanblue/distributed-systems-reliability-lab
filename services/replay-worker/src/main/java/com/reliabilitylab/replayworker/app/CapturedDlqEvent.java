package com.reliabilitylab.replayworker.app;

import java.time.Instant;

public record CapturedDlqEvent(
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
