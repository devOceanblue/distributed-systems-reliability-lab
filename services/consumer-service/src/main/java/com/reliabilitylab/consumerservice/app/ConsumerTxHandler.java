package com.reliabilitylab.consumerservice.app;

import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import com.reliabilitylab.consumerservice.infra.ConsumerJdbcRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class ConsumerTxHandler {
    private static final Logger log = LoggerFactory.getLogger(ConsumerTxHandler.class);

    private final ConsumerJdbcRepository consumerJdbcRepository;
    private final ProjectionCacheInvalidator projectionCacheInvalidator;

    public ConsumerTxHandler(ConsumerJdbcRepository consumerJdbcRepository,
                             ProjectionCacheInvalidator projectionCacheInvalidator) {
        this.consumerJdbcRepository = consumerJdbcRepository;
        this.projectionCacheInvalidator = projectionCacheInvalidator;
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
        try {
            projectionCacheInvalidator.invalidate(input.accountId());
        } catch (RuntimeException ex) {
            log.warn("cache invalidation failed accountId={} reason={}", input.accountId(), ex.getMessage());
        }
        return ProcessOutcome.PROCESSED;
    }
}
