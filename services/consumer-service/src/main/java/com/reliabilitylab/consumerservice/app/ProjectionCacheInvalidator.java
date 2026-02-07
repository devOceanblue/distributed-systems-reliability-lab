package com.reliabilitylab.consumerservice.app;

public interface ProjectionCacheInvalidator {
    void invalidate(String accountId);
}
