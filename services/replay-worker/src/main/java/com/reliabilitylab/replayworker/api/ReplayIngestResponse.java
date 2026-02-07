package com.reliabilitylab.replayworker.api;

public record ReplayIngestResponse(
        String status,
        String eventId
) {
}
