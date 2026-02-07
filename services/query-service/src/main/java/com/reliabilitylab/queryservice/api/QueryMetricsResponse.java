package com.reliabilitylab.queryservice.api;

public record QueryMetricsResponse(
        long cacheHit,
        long cacheMiss,
        long dbRead
) {
}
