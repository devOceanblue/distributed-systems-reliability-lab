package com.reliabilitylab.queryservice.infra;

import com.reliabilitylab.eventcore.cache.ProjectionCacheKeys;
import com.reliabilitylab.queryservice.app.BalanceCacheStore;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Optional;

@Component
@ConditionalOnProperty(name = "app.redis.enabled", havingValue = "true")
public class RedisBalanceCacheStore implements BalanceCacheStore {
    private final StringRedisTemplate redisTemplate;

    public RedisBalanceCacheStore(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public Optional<Long> getBalance(String cacheKey) {
        String value = redisTemplate.opsForValue().get(cacheKey);
        if (value == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(Long.parseLong(value));
        } catch (NumberFormatException ex) {
            return Optional.empty();
        }
    }

    @Override
    public void putBalance(String cacheKey, long balance, Duration ttl) {
        redisTemplate.opsForValue().set(cacheKey, Long.toString(balance), ttl);
    }

    @Override
    public boolean tryAcquireLock(String lockKey, Duration ttl) {
        return Boolean.TRUE.equals(redisTemplate.opsForValue().setIfAbsent(lockKey, "1", ttl));
    }

    @Override
    public void releaseLock(String lockKey) {
        redisTemplate.delete(lockKey);
    }

    @Override
    public long currentVersion(String accountId) {
        String value = redisTemplate.opsForValue().get(ProjectionCacheKeys.balanceVersion(accountId));
        if (value == null) {
            return 0L;
        }
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException ex) {
            return 0L;
        }
    }
}
