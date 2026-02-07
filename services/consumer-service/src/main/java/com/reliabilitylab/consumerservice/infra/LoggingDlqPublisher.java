package com.reliabilitylab.consumerservice.infra;

import com.reliabilitylab.consumerservice.app.DlqPublisher;
import com.reliabilitylab.consumerservice.app.ProcessingInput;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "false", matchIfMissing = true)
public class LoggingDlqPublisher implements DlqPublisher {
    private static final Logger log = LoggerFactory.getLogger(LoggingDlqPublisher.class);

    @Override
    public void publish(ProcessingInput input, Exception exception) {
        log.warn("[dlq] publish skipped because app.kafka.enabled=false dedupKey={} reason={}",
                input.dedupKey(),
                exception.getMessage());
    }
}
