package com.reliabilitylab.consumerservice.app;

import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import org.springframework.stereotype.Service;

@Service
public class ConsumerProcessingService {
    private final ConsumerServiceProperties properties;
    private final ConsumerTxHandler consumerTxHandler;
    private final ConsumerFailpointGuard consumerFailpointGuard;
    private final DlqPublisher dlqPublisher;
    private final RetryPublisher retryPublisher;

    public ConsumerProcessingService(ConsumerServiceProperties properties,
                                     ConsumerTxHandler consumerTxHandler,
                                     ConsumerFailpointGuard consumerFailpointGuard,
                                     DlqPublisher dlqPublisher,
                                     RetryPublisher retryPublisher) {
        this.properties = properties;
        this.consumerTxHandler = consumerTxHandler;
        this.consumerFailpointGuard = consumerFailpointGuard;
        this.dlqPublisher = dlqPublisher;
        this.retryPublisher = retryPublisher;
    }

    public ProcessOutcome consume(ProcessingInput input, Runnable offsetCommitter) {
        if (properties.getOffsetCommitMode() == ConsumerServiceProperties.OffsetCommitMode.BEFORE_DB) {
            offsetCommitter.run();
            consumerFailpointGuard.check("FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT");
        }

        try {
            ProcessOutcome outcome = consumerTxHandler.apply(
                    input,
                    properties.getConsumerGroup(),
                    properties.getIdempotencyMode(),
                    properties.getForcePermanentErrorOnAccountId()
            );
            if (properties.getOffsetCommitMode() == ConsumerServiceProperties.OffsetCommitMode.AFTER_DB) {
                offsetCommitter.run();
            }
            return outcome;
        } catch (PermanentProcessingException ex) {
            dlqPublisher.publish(input, ex);
            if (properties.getOffsetCommitMode() == ConsumerServiceProperties.OffsetCommitMode.AFTER_DB) {
                offsetCommitter.run();
            }
            return ProcessOutcome.DLQ;
        } catch (RuntimeException ex) {
            retryPublisher.publish(input, ex);
            if (properties.getOffsetCommitMode() == ConsumerServiceProperties.OffsetCommitMode.AFTER_DB) {
                offsetCommitter.run();
            }
            return ProcessOutcome.RETRY;
        }
    }
}
