package com.reliabilitylab.eventcore.cache;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ProjectionCacheKeysTest {

    @Test
    void shouldBuildExpectedKeys() {
        assertEquals("balance:A-1", ProjectionCacheKeys.balance("A-1"));
        assertEquals("balance:ver:A-1", ProjectionCacheKeys.balanceVersion("A-1"));
        assertEquals("balance:A-1:v:3", ProjectionCacheKeys.balanceVersioned("A-1", 3));
        assertEquals("lock:balance:A-1", ProjectionCacheKeys.lock("balance:A-1"));
    }

    @Test
    void shouldRejectBlankAccountId() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> ProjectionCacheKeys.balance(" "));
        assertEquals("accountId is required", ex.getMessage());
    }
}
