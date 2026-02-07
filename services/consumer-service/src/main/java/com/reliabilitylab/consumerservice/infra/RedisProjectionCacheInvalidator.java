package com.reliabilitylab.consumerservice.infra;

import com.reliabilitylab.consumerservice.app.ProjectionCacheInvalidator;
import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import com.reliabilitylab.eventcore.cache.ProjectionCacheKeys;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.redis.enabled", havingValue = "true")
public class RedisProjectionCacheInvalidator implements ProjectionCacheInvalidator {
    private final ConsumerServiceProperties properties;
    private final StringRedisTemplate redisTemplate;

    public RedisProjectionCacheInvalidator(ConsumerServiceProperties properties,
                                           StringRedisTemplate redisTemplate) {
        this.properties = properties;
        this.redisTemplate = redisTemplate;
    }

    @Override
    public void invalidate(String accountId) {
        if (properties.getCacheInvalidationMode() == ConsumerServiceProperties.CacheInvalidationMode.NONE) {
            return;
        }

        if (properties.getCacheInvalidationMode() == ConsumerServiceProperties.CacheInvalidationMode.DEL) {
            redisTemplate.delete(ProjectionCacheKeys.balance(accountId));
            return;
        }

        if (properties.getCacheInvalidationMode() == ConsumerServiceProperties.CacheInvalidationMode.VERSIONED) {
            redisTemplate.opsForValue().increment(ProjectionCacheKeys.balanceVersion(accountId));
        }
    }
}
