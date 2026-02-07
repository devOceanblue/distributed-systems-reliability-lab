package com.reliabilitylab.queryservice.app;

public record QueryResult(
        String accountId,
        long balance,
        String cacheKey,
        CacheSource cacheSource
) {
    public enum CacheSource {
        CACHE_HIT,
        CACHE_MISS
    }
}
