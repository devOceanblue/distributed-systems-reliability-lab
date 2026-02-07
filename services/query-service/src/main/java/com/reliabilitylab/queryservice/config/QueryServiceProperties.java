package com.reliabilitylab.queryservice.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.query")
public class QueryServiceProperties {
    private int ttlSeconds = 30;
    private int ttlJitterSeconds = 5;
    private StampedeProtectionMode stampedeProtection = StampedeProtectionMode.ON;
    private CacheInvalidationMode cacheInvalidationMode = CacheInvalidationMode.DEL;
    private int lockTtlMillis = 3000;
    private int lockWaitMillis = 25;
    private int lockRetryCount = 20;

    public int getTtlSeconds() {
        return ttlSeconds;
    }

    public void setTtlSeconds(int ttlSeconds) {
        this.ttlSeconds = ttlSeconds;
    }

    public int getTtlJitterSeconds() {
        return ttlJitterSeconds;
    }

    public void setTtlJitterSeconds(int ttlJitterSeconds) {
        this.ttlJitterSeconds = ttlJitterSeconds;
    }

    public StampedeProtectionMode getStampedeProtection() {
        return stampedeProtection;
    }

    public void setStampedeProtection(StampedeProtectionMode stampedeProtection) {
        this.stampedeProtection = stampedeProtection;
    }

    public CacheInvalidationMode getCacheInvalidationMode() {
        return cacheInvalidationMode;
    }

    public void setCacheInvalidationMode(CacheInvalidationMode cacheInvalidationMode) {
        this.cacheInvalidationMode = cacheInvalidationMode;
    }

    public int getLockTtlMillis() {
        return lockTtlMillis;
    }

    public void setLockTtlMillis(int lockTtlMillis) {
        this.lockTtlMillis = lockTtlMillis;
    }

    public int getLockWaitMillis() {
        return lockWaitMillis;
    }

    public void setLockWaitMillis(int lockWaitMillis) {
        this.lockWaitMillis = lockWaitMillis;
    }

    public int getLockRetryCount() {
        return lockRetryCount;
    }

    public void setLockRetryCount(int lockRetryCount) {
        this.lockRetryCount = lockRetryCount;
    }

    public enum StampedeProtectionMode {
        ON,
        OFF
    }

    public enum CacheInvalidationMode {
        DEL,
        VERSIONED,
        NONE
    }
}
