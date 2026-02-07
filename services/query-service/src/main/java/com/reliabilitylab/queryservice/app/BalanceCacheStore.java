package com.reliabilitylab.queryservice.app;

import java.time.Duration;
import java.util.Optional;

public interface BalanceCacheStore {
    Optional<Long> getBalance(String cacheKey);

    void putBalance(String cacheKey, long balance, Duration ttl);

    boolean tryAcquireLock(String lockKey, Duration ttl);

    void releaseLock(String lockKey);

    long currentVersion(String accountId);
}
