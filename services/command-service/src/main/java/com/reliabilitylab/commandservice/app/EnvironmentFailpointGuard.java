package com.reliabilitylab.commandservice.app;

import com.reliabilitylab.eventcore.Failpoints;
import org.springframework.stereotype.Component;

@Component
public class EnvironmentFailpointGuard implements FailpointGuard {
    @Override
    public void check(String envName) {
        Failpoints.check(envName);
    }
}
