package com.reliabilitylab.e2e;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DistributedLockSimulationTest {

    @Test
    void failureS1_ttlExpiry_allowsDuplicateApply() {
        Sim sim = new Sim();
        sim.acquire("A", 2000);
        sim.advance(2100);
        sim.acquire("B", 2000);
        sim.applyWithoutGuard();
        sim.advance(2900);
        sim.applyWithoutGuard();

        assertTrue(sim.appliedCount > 1);
    }

    @Test
    void failureS2_badUnlock_allowsDuplicateApply() {
        Sim sim = new Sim();
        sim.acquire("A", 2000);
        sim.advance(800);
        sim.unsafeUnlock();
        sim.acquire("B", 2000);
        sim.applyWithoutGuard();
        sim.applyWithoutGuard();

        assertTrue(sim.appliedCount > 1);
    }

    @Test
    void failureS3_timeoutRetry_ambiguousPathCanDuplicate() {
        Sim sim = new Sim();
        sim.acquire("A-first", 2000);
        sim.duplicateRiskEvents++;
        sim.advance(2100);
        sim.acquire("A-retry", 2000);
        sim.applyWithoutGuard();
        sim.applyWithoutGuard();

        assertTrue(sim.appliedCount > 1);
        assertTrue(sim.duplicateRiskEvents >= 1);
    }

    @Test
    void failureS4_crashRestart_canDuplicate() {
        Sim sim = new Sim();
        sim.acquire("A", 2000);
        sim.advance(1200);
        sim.applyWithoutGuard();
        sim.advance(1000);
        sim.acquire("B", 2000);
        sim.applyWithoutGuard();
        sim.advance(2100);
        sim.acquire("A-restart", 2000);
        sim.applyWithoutGuard();

        assertTrue(sim.appliedCount > 1);
    }

    @Test
    void fencingS1_ttlExpiry_convergesToSingleApply() {
        Sim sim = new Sim();
        sim.acquire("A", 2000);
        long tokenA = sim.allocateFenceToken();
        sim.advance(2100);
        sim.acquire("B", 2000);
        long tokenB = sim.allocateFenceToken();

        sim.applyWithFencingOncePerJob(tokenB);
        sim.advance(2900);
        sim.applyWithFencingOncePerJob(tokenA);

        assertEquals(1, sim.appliedCount);
    }

    @Test
    void fencingS2_badUnlockAttempt_isRejectedAndSingleApply() {
        Sim sim = new Sim();
        sim.acquire("A", 2000);
        long tokenA = sim.allocateFenceToken();
        sim.advance(800);
        sim.safeUnlock("B-evil");
        sim.applyWithFencingOncePerJob(tokenA);

        assertEquals(1, sim.appliedCount);
    }

    @Test
    void fencingS3_timeoutRetry_convergesToSingleApply() {
        Sim sim = new Sim();
        sim.acquire("A-first", 2000);
        long tokenFirst = sim.allocateFenceToken();
        sim.duplicateRiskEvents++;
        sim.advance(2100);
        sim.acquire("A-retry", 2000);
        long tokenRetry = sim.allocateFenceToken();

        sim.applyWithFencingOncePerJob(tokenRetry);
        sim.applyWithFencingOncePerJob(tokenFirst);

        assertEquals(1, sim.appliedCount);
    }

    @Test
    void fencingS4_crashRestart_convergesToSingleApply() {
        Sim sim = new Sim();
        sim.acquire("A", 2000);
        long tokenA = sim.allocateFenceToken();
        sim.advance(1200);
        sim.advance(1000);
        sim.acquire("B", 2000);
        long tokenB = sim.allocateFenceToken();
        sim.applyWithFencingOncePerJob(tokenB);

        sim.advance(2100);
        sim.acquire("A-restart", 2000);
        long tokenA2 = sim.allocateFenceToken();
        sim.applyWithFencingOncePerJob(tokenA2);
        sim.applyWithFencingOncePerJob(tokenA);

        assertEquals(1, sim.appliedCount);
    }

    private static final class Sim {
        long nowMs = 0;
        String lockOwner = "";
        long lockExpiresAtMs = 0;
        long lastFenceToken = 0;
        long nextFenceToken = 100;
        int appliedCount = 0;
        int duplicateRiskEvents = 0;
        boolean jobApplied = false;

        void advance(long millis) {
            nowMs += millis;
        }

        boolean acquire(String owner, long ttlMs) {
            if (!lockOwner.isEmpty() && nowMs < lockExpiresAtMs) {
                return false;
            }
            lockOwner = owner;
            lockExpiresAtMs = nowMs + ttlMs;
            return true;
        }

        void unsafeUnlock() {
            lockOwner = "";
            lockExpiresAtMs = 0;
        }

        boolean safeUnlock(String owner) {
            if (!lockOwner.isEmpty() && nowMs < lockExpiresAtMs && lockOwner.equals(owner)) {
                unsafeUnlock();
                return true;
            }
            return false;
        }

        void applyWithoutGuard() {
            appliedCount++;
        }

        long allocateFenceToken() {
            nextFenceToken++;
            return nextFenceToken;
        }

        boolean applyWithFencing(long token) {
            if (token > lastFenceToken) {
                lastFenceToken = token;
                appliedCount++;
                return true;
            }
            return false;
        }

        boolean applyWithFencingOncePerJob(long token) {
            if (jobApplied) {
                return false;
            }
            if (applyWithFencing(token)) {
                jobApplied = true;
                return true;
            }
            return false;
        }
    }
}
