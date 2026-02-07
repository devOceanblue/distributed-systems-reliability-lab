package com.reliabilitylab.queryservice.app;

import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicLong;

@Component
public class QueryMetricsCollector {
    private final AtomicLong cacheHit = new AtomicLong();
    private final AtomicLong cacheMiss = new AtomicLong();
    private final AtomicLong dbRead = new AtomicLong();

    public void onCacheHit() {
        cacheHit.incrementAndGet();
    }

    public void onCacheMiss() {
        cacheMiss.incrementAndGet();
    }

    public void onDbRead() {
        dbRead.incrementAndGet();
    }

    public QueryMetricsSnapshot snapshot() {
        return new QueryMetricsSnapshot(cacheHit.get(), cacheMiss.get(), dbRead.get());
    }
}
