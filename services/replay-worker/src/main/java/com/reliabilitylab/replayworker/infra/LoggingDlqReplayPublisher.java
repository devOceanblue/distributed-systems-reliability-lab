package com.reliabilitylab.replayworker.infra;

import com.reliabilitylab.replayworker.app.DlqEvent;
import com.reliabilitylab.replayworker.app.DlqReplayPublisher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnMissingBean(DlqReplayPublisher.class)
public class LoggingDlqReplayPublisher implements DlqReplayPublisher {
    private static final Logger log = LoggerFactory.getLogger(LoggingDlqReplayPublisher.class);

    @Override
    public void publish(DlqEvent event, String outputTopic) {
        log.info("[replay] publish skipped because app.kafka.enabled=false dedupKey={} outputTopic={}",
                event.dedupKey(),
                outputTopic);
    }
}
