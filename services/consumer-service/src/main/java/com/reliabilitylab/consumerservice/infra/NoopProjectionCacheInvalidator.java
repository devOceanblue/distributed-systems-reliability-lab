package com.reliabilitylab.consumerservice.infra;

import com.reliabilitylab.consumerservice.app.ProjectionCacheInvalidator;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnMissingBean(ProjectionCacheInvalidator.class)
public class NoopProjectionCacheInvalidator implements ProjectionCacheInvalidator {
    @Override
    public void invalidate(String accountId) {
    }
}
