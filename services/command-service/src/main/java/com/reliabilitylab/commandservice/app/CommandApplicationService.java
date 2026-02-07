package com.reliabilitylab.commandservice.app;

import com.reliabilitylab.commandservice.config.CommandServiceProperties;
import com.reliabilitylab.commandservice.infra.BalanceEventPublisher;
import org.springframework.stereotype.Service;

@Service
public class CommandApplicationService {
    private final CommandTxHandler commandTxHandler;
    private final BalanceEventPublisher balanceEventPublisher;
    private final CommandServiceProperties commandServiceProperties;
    private final FailpointGuard failpointGuard;

    public CommandApplicationService(CommandTxHandler commandTxHandler,
                                     BalanceEventPublisher balanceEventPublisher,
                                     CommandServiceProperties commandServiceProperties,
                                     FailpointGuard failpointGuard) {
        this.commandTxHandler = commandTxHandler;
        this.balanceEventPublisher = balanceEventPublisher;
        this.commandServiceProperties = commandServiceProperties;
        this.failpointGuard = failpointGuard;
    }

    public CommandResult deposit(String accountId, String txId, long amount, String traceId) {
        return apply(accountId, txId, amount, traceId);
    }

    public CommandResult withdraw(String accountId, String txId, long amount, String traceId) {
        return apply(accountId, txId, -amount, traceId);
    }

    private CommandResult apply(String accountId, String txId, long amount, String traceId) {
        CommandServiceProperties.ProduceMode mode = commandServiceProperties.getProduceMode();

        if (mode == CommandServiceProperties.ProduceMode.OUTBOX) {
            CommandTxResult result = commandTxHandler.apply(accountId, txId, amount, traceId, true);
            return new CommandResult(result.balance(), mode.name());
        }

        CommandTxResult result = commandTxHandler.apply(accountId, txId, amount, traceId, false);
        failpointGuard.check("FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND");
        balanceEventPublisher.publish(result.envelope(), accountId);
        return new CommandResult(result.balance(), mode.name());
    }
}
