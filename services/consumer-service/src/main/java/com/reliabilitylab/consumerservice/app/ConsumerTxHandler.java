package com.reliabilitylab.consumerservice.app;

import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import com.reliabilitylab.consumerservice.infra.ConsumerJdbcRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class ConsumerTxHandler {
    private final ConsumerJdbcRepository consumerJdbcRepository;

    public ConsumerTxHandler(ConsumerJdbcRepository consumerJdbcRepository) {
        this.consumerJdbcRepository = consumerJdbcRepository;
    }

    @Transactional
    public ProcessOutcome apply(ProcessingInput input,
                                String consumerGroup,
                                ConsumerServiceProperties.IdempotencyMode idempotencyMode,
                                String forcePermanentErrorOnAccountId) {
        if (forcePermanentErrorOnAccountId != null
                && !forcePermanentErrorOnAccountId.isBlank()
                && forcePermanentErrorOnAccountId.equals(input.accountId())) {
            throw new PermanentProcessingException("forced permanent error for account=" + input.accountId());
        }

        if (idempotencyMode == ConsumerServiceProperties.IdempotencyMode.PROCESSED_TABLE) {
            boolean inserted = consumerJdbcRepository.tryInsertProcessed(
                    consumerGroup,
                    input.dedupKey(),
                    input.topic(),
                    input.partition(),
                    input.offset()
            );
            if (!inserted) {
                return ProcessOutcome.DUPLICATE_SKIPPED;
            }
        }

        consumerJdbcRepository.applyProjectionDelta(input.accountId(), input.amount());
        return ProcessOutcome.PROCESSED;
    }
}
