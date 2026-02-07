package com.reliabilitylab.queryservice.app;

import com.reliabilitylab.eventcore.cache.ProjectionCacheKeys;
import com.reliabilitylab.queryservice.config.QueryServiceProperties;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class QueryBalanceService {
    private final QueryServiceProperties properties;
    private final ProjectionBalanceReader projectionBalanceReader;
    private final BalanceCacheStore balanceCacheStore;
    private final QueryMetricsCollector metricsCollector;

    public QueryBalanceService(QueryServiceProperties properties,
                               ProjectionBalanceReader projectionBalanceReader,
                               BalanceCacheStore balanceCacheStore,
                               QueryMetricsCollector metricsCollector) {
        this.properties = properties;
        this.projectionBalanceReader = projectionBalanceReader;
        this.balanceCacheStore = balanceCacheStore;
        this.metricsCollector = metricsCollector;
    }

    public QueryResult queryBalance(String accountId) {
        String cacheKey = resolveCacheKey(accountId);
        Optional<Long> cached = balanceCacheStore.getBalance(cacheKey);
        if (cached.isPresent()) {
            metricsCollector.onCacheHit();
            return new QueryResult(accountId, cached.get(), cacheKey, QueryResult.CacheSource.CACHE_HIT);
        }

        metricsCollector.onCacheMiss();
        if (properties.getStampedeProtection() == QueryServiceProperties.StampedeProtectionMode.OFF) {
            long balance = loadFromDbAndCache(cacheKey, accountId);
            return new QueryResult(accountId, balance, cacheKey, QueryResult.CacheSource.CACHE_MISS);
        }

        String lockKey = ProjectionCacheKeys.lock(cacheKey);
        if (balanceCacheStore.tryAcquireLock(lockKey, Duration.ofMillis(properties.getLockTtlMillis()))) {
            try {
                long balance = loadFromDbAndCache(cacheKey, accountId);
                return new QueryResult(accountId, balance, cacheKey, QueryResult.CacheSource.CACHE_MISS);
            } finally {
                balanceCacheStore.releaseLock(lockKey);
            }
        }

        for (int i = 0; i < properties.getLockRetryCount(); i++) {
            sleepQuietly(properties.getLockWaitMillis());
            Optional<Long> waited = balanceCacheStore.getBalance(cacheKey);
            if (waited.isPresent()) {
                metricsCollector.onCacheHit();
                return new QueryResult(accountId, waited.get(), cacheKey, QueryResult.CacheSource.CACHE_HIT);
            }
        }

        long balance = loadFromDbAndCache(cacheKey, accountId);
        return new QueryResult(accountId, balance, cacheKey, QueryResult.CacheSource.CACHE_MISS);
    }

    public QueryMetricsSnapshot metrics() {
        return metricsCollector.snapshot();
    }

    private long loadFromDbAndCache(String cacheKey, String accountId) {
        metricsCollector.onDbRead();
        long balance = projectionBalanceReader.readBalance(accountId);
        balanceCacheStore.putBalance(cacheKey, balance, ttlWithJitter());
        return balance;
    }

    private Duration ttlWithJitter() {
        int base = Math.max(1, properties.getTtlSeconds());
        int jitter = Math.max(0, properties.getTtlJitterSeconds());
        int jitterDelta = jitter == 0 ? 0 : ThreadLocalRandom.current().nextInt(jitter + 1);
        return Duration.ofSeconds(base + jitterDelta);
    }

    private String resolveCacheKey(String accountId) {
        if (properties.getCacheInvalidationMode() == QueryServiceProperties.CacheInvalidationMode.VERSIONED) {
            long version = balanceCacheStore.currentVersion(accountId);
            return ProjectionCacheKeys.balanceVersioned(accountId, version);
        }
        return ProjectionCacheKeys.balance(accountId);
    }

    private void sleepQuietly(long millis) {
        if (millis <= 0) {
            return;
        }
        try {
            Thread.sleep(millis);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
        }
    }
}
