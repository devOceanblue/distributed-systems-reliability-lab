package com.reliabilitylab.queryservice.api;

public record BalanceQueryResponse(
        String accountId,
        long balance,
        String cacheSource,
        String cacheKey
) {
}
