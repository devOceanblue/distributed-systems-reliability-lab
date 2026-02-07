package com.reliabilitylab.queryservice.infra;

import com.reliabilitylab.queryservice.app.BalanceCacheStore;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Optional;

@Component
@ConditionalOnMissingBean(BalanceCacheStore.class)
public class NoopBalanceCacheStore implements BalanceCacheStore {
    @Override
    public Optional<Long> getBalance(String cacheKey) {
        return Optional.empty();
    }

    @Override
    public void putBalance(String cacheKey, long balance, Duration ttl) {
    }

    @Override
    public boolean tryAcquireLock(String lockKey, Duration ttl) {
        return true;
    }

    @Override
    public void releaseLock(String lockKey) {
    }

    @Override
    public long currentVersion(String accountId) {
        return 0L;
    }
}
