package com.reliabilitylab.outboxrelay.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@ConfigurationProperties(prefix = "app.relay")
public class RelayProperties {
    private int maxAttempts = 5;
    private List<Long> backoffSeconds = new ArrayList<>(List.of(5L, 30L, 120L));
    private LockingMode lockingMode = LockingMode.SKIP_LOCKED;
    private boolean schedulerEnabled;
    private long schedulerDelayMs = 1000;

    public int getMaxAttempts() {
        return maxAttempts;
    }

    public void setMaxAttempts(int maxAttempts) {
        this.maxAttempts = maxAttempts;
    }

    public List<Long> getBackoffSeconds() {
        return backoffSeconds;
    }

    public void setBackoffSeconds(List<Long> backoffSeconds) {
        this.backoffSeconds = backoffSeconds;
    }

    public LockingMode getLockingMode() {
        return lockingMode;
    }

    public void setLockingMode(LockingMode lockingMode) {
        this.lockingMode = lockingMode;
    }

    public boolean isSchedulerEnabled() {
        return schedulerEnabled;
    }

    public void setSchedulerEnabled(boolean schedulerEnabled) {
        this.schedulerEnabled = schedulerEnabled;
    }

    public long getSchedulerDelayMs() {
        return schedulerDelayMs;
    }

    public void setSchedulerDelayMs(long schedulerDelayMs) {
        this.schedulerDelayMs = schedulerDelayMs;
    }

    public Duration backoffForAttempt(int attemptNumber) {
        if (backoffSeconds == null || backoffSeconds.isEmpty()) {
            return Duration.ofSeconds(5);
        }
        int index = Math.min(Math.max(attemptNumber - 1, 0), backoffSeconds.size() - 1);
        return Duration.ofSeconds(backoffSeconds.get(index));
    }

    public enum LockingMode {
        SKIP_LOCKED,
        SIMPLE
    }
}
