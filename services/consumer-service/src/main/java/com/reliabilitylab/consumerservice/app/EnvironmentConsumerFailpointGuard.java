package com.reliabilitylab.consumerservice.app;

import com.reliabilitylab.eventcore.Failpoints;
import org.springframework.stereotype.Component;

@Component
public class EnvironmentConsumerFailpointGuard implements ConsumerFailpointGuard {
    @Override
    public void check(String envName) {
        Failpoints.check(envName);
    }
}
