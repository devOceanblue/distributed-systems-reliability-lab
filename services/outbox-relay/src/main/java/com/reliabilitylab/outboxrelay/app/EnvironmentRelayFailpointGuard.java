package com.reliabilitylab.outboxrelay.app;

import com.reliabilitylab.eventcore.Failpoints;
import org.springframework.stereotype.Component;

@Component
public class EnvironmentRelayFailpointGuard implements RelayFailpointGuard {
    @Override
    public void check(String envName) {
        Failpoints.check(envName);
    }
}
