package com.reliabilitylab.queryservice.app;

import com.reliabilitylab.queryservice.config.QueryServiceProperties;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class QueryBalanceServiceTest {

    @Test
    void shouldReproduceStaleReadWhenInvalidationNone() {
        QueryServiceProperties properties = new QueryServiceProperties();
        properties.setCacheInvalidationMode(QueryServiceProperties.CacheInvalidationMode.NONE);
        properties.setStampedeProtection(QueryServiceProperties.StampedeProtectionMode.OFF);
        properties.setTtlSeconds(300);
        properties.setTtlJitterSeconds(0);

        InMemoryProjectionReader projectionReader = new InMemoryProjectionReader(0);
        projectionReader.setBalance("A-1", 100L);
        InMemoryCacheStore cacheStore = new InMemoryCacheStore();

        QueryBalanceService service = new QueryBalanceService(
                properties,
                projectionReader,
                cacheStore,
                new QueryMetricsCollector()
        );

        QueryResult first = service.queryBalance("A-1");
        projectionReader.setBalance("A-1", 200L);
        QueryResult second = service.queryBalance("A-1");

        assertEquals(QueryResult.CacheSource.CACHE_MISS, first.cacheSource());
        assertEquals(QueryResult.CacheSource.CACHE_HIT, second.cacheSource());
        assertEquals(100L, second.balance());
        assertEquals(1, projectionReader.readCount());
    }

    @Test
    void shouldUseVersionedCacheKeyWhenConfigured() {
        QueryServiceProperties properties = new QueryServiceProperties();
        properties.setCacheInvalidationMode(QueryServiceProperties.CacheInvalidationMode.VERSIONED);
        properties.setStampedeProtection(QueryServiceProperties.StampedeProtectionMode.OFF);
        properties.setTtlSeconds(60);
        properties.setTtlJitterSeconds(0);

        InMemoryProjectionReader projectionReader = new InMemoryProjectionReader(0);
        projectionReader.setBalance("A-2", 55L);

        InMemoryCacheStore cacheStore = new InMemoryCacheStore();
        cacheStore.setVersion("A-2", 7L);

        QueryBalanceService service = new QueryBalanceService(
                properties,
                projectionReader,
                cacheStore,
                new QueryMetricsCollector()
        );

        QueryResult result = service.queryBalance("A-2");
        assertEquals("balance:A-2:v:7", result.cacheKey());
    }

    @Test
    void shouldReduceDbReadsWhenStampedeProtectionOn() throws Exception {
        int parallelism = 20;

        QueryServiceProperties offProps = new QueryServiceProperties();
        offProps.setStampedeProtection(QueryServiceProperties.StampedeProtectionMode.OFF);
        offProps.setCacheInvalidationMode(QueryServiceProperties.CacheInvalidationMode.DEL);
        offProps.setTtlSeconds(60);
        offProps.setTtlJitterSeconds(0);

        InMemoryProjectionReader offReader = new InMemoryProjectionReader(40);
        offReader.setBalance("A-3", 999L);
        QueryBalanceService offService = new QueryBalanceService(
                offProps,
                offReader,
                new InMemoryCacheStore(),
                new QueryMetricsCollector()
        );
        runConcurrentQueries(offService, "A-3", parallelism);
        int readsWithoutProtection = offReader.readCount();

        QueryServiceProperties onProps = new QueryServiceProperties();
        onProps.setStampedeProtection(QueryServiceProperties.StampedeProtectionMode.ON);
        onProps.setCacheInvalidationMode(QueryServiceProperties.CacheInvalidationMode.DEL);
        onProps.setTtlSeconds(60);
        onProps.setTtlJitterSeconds(0);
        onProps.setLockWaitMillis(5);
        onProps.setLockRetryCount(30);
        onProps.setLockTtlMillis(500);

        InMemoryProjectionReader onReader = new InMemoryProjectionReader(40);
        onReader.setBalance("A-3", 999L);
        QueryBalanceService onService = new QueryBalanceService(
                onProps,
                onReader,
                new InMemoryCacheStore(),
                new QueryMetricsCollector()
        );
        runConcurrentQueries(onService, "A-3", parallelism);
        int readsWithProtection = onReader.readCount();

        assertTrue(readsWithProtection < readsWithoutProtection);
        assertTrue(readsWithProtection <= 3);
    }

    private static void runConcurrentQueries(QueryBalanceService service, String accountId, int workers) throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(workers);
        CountDownLatch ready = new CountDownLatch(workers);
        CountDownLatch start = new CountDownLatch(1);
        CountDownLatch done = new CountDownLatch(workers);

        for (int i = 0; i < workers; i++) {
            executor.submit(() -> {
                ready.countDown();
                try {
                    start.await();
                    QueryResult result = service.queryBalance(accountId);
                    assertEquals(999L, result.balance());
                } catch (InterruptedException ex) {
                    Thread.currentThread().interrupt();
                } finally {
                    done.countDown();
                }
            });
        }

        assertTrue(ready.await(2, TimeUnit.SECONDS));
        start.countDown();
        assertTrue(done.await(5, TimeUnit.SECONDS));
        executor.shutdownNow();
    }

    private static final class InMemoryProjectionReader implements ProjectionBalanceReader {
        private final Map<String, Long> balances = new ConcurrentHashMap<>();
        private final AtomicInteger readCount = new AtomicInteger();
        private final long readDelayMillis;

        private InMemoryProjectionReader(long readDelayMillis) {
            this.readDelayMillis = readDelayMillis;
        }

        @Override
        public long readBalance(String accountId) {
            readCount.incrementAndGet();
            if (readDelayMillis > 0) {
                try {
                    Thread.sleep(readDelayMillis);
                } catch (InterruptedException ex) {
                    Thread.currentThread().interrupt();
                }
            }
            return balances.getOrDefault(accountId, 0L);
        }

        private void setBalance(String accountId, long balance) {
            balances.put(accountId, balance);
        }

        private int readCount() {
            return readCount.get();
        }
    }

    private static final class InMemoryCacheStore implements BalanceCacheStore {
        private final Map<String, CacheEntry> values = new ConcurrentHashMap<>();
        private final Map<String, AtomicLong> versions = new ConcurrentHashMap<>();
        private final Map<String, Boolean> locks = new ConcurrentHashMap<>();

        @Override
        public Optional<Long> getBalance(String cacheKey) {
            CacheEntry entry = values.get(cacheKey);
            if (entry == null) {
                return Optional.empty();
            }
            if (entry.expiresAtMillis > 0 && System.currentTimeMillis() > entry.expiresAtMillis) {
                values.remove(cacheKey);
                return Optional.empty();
            }
            return Optional.of(entry.value);
        }

        @Override
        public void putBalance(String cacheKey, long balance, Duration ttl) {
            long expiresAt = ttl.isZero() ? 0 : (System.currentTimeMillis() + ttl.toMillis());
            values.put(cacheKey, new CacheEntry(balance, expiresAt));
        }

        @Override
        public boolean tryAcquireLock(String lockKey, Duration ttl) {
            return locks.putIfAbsent(lockKey, Boolean.TRUE) == null;
        }

        @Override
        public void releaseLock(String lockKey) {
            locks.remove(lockKey);
        }

        @Override
        public long currentVersion(String accountId) {
            return versions.getOrDefault(accountId, new AtomicLong(0)).get();
        }

        private void setVersion(String accountId, long version) {
            versions.computeIfAbsent(accountId, ignored -> new AtomicLong()).set(version);
        }

        private record CacheEntry(long value, long expiresAtMillis) {
        }
    }
}
