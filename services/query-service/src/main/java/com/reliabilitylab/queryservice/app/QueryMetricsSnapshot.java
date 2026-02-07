package com.reliabilitylab.queryservice.app;

public record QueryMetricsSnapshot(
        long cacheHit,
        long cacheMiss,
        long dbRead
) {
}
