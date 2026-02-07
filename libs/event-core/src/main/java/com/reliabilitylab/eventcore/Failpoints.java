package com.reliabilitylab.eventcore;

public final class Failpoints {
    private Failpoints() {
    }

    public static void check(String envName) {
        if (Boolean.parseBoolean(System.getenv(envName))) {
            throw new FailpointTriggeredException("Failpoint triggered: " + envName);
        }
    }
}
