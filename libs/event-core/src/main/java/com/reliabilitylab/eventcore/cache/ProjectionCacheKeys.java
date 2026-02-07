package com.reliabilitylab.eventcore.cache;

import java.util.Objects;

public final class ProjectionCacheKeys {
    private ProjectionCacheKeys() {
    }

    public static String balance(String accountId) {
        return "balance:" + requiredAccountId(accountId);
    }

    public static String balanceVersion(String accountId) {
        return "balance:ver:" + requiredAccountId(accountId);
    }

    public static String balanceVersioned(String accountId, long version) {
        return balance(accountId) + ":v:" + version;
    }

    public static String lock(String cacheKey) {
        return "lock:" + Objects.requireNonNull(cacheKey, "cacheKey");
    }

    private static String requiredAccountId(String accountId) {
        if (accountId == null || accountId.isBlank()) {
            throw new IllegalArgumentException("accountId is required");
        }
        return accountId;
    }
}
